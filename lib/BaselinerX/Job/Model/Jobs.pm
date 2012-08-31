package BaselinerX::Job::Model::Jobs;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use namespace::clean;
use Baseliner::Utils;
use Baseliner::Sugar;
use Compress::Zlib;
use Archive::Tar;
use Path::Class;
use Try::Tiny;
use Data::Dumper;
use utf8;
use Class::Date;

with 'Baseliner::Role::Search';
with 'Baseliner::Role::Service';

register 'service.doo' => {
    handler=>sub{
        _debug( "NONONO" );
        #_log "888888888888";
    }
};

sub search_provider_name { 'Jobs' };
sub search_provider_type { 'Job' };
sub search_query {
    my ($self, %p ) = @_;
    my $where = query_sql_build( query=>$p{query}, fields=>{
        name     =>'me.name',
        id       =>'to_char(me.id)',
        user     =>'me.username',
        comments =>'me.comments',
        status   =>'me.status',
        start    =>"me.starttime",
        sched    =>"me.schedtime",
        end      =>"me.endtime",
        items    =>"bali_job_items.item",
    });
    my $rs_search = Baseliner->model('Baseliner::BaliJob')->search(
        $where,
        {
            select => [ { distinct=>'me.id'}, 'starttime' ],
            as => [ 'id', 'starttime' ],
            join => [ 'bali_job_items' ],	
            page=>0, rows=>$p{query_limit} || 20,
            order_by => { -desc => 'me.starttime' },
        }
    );
    rs_hashref( $rs_search );
    my @ids = map { $_->{id} } $rs_search->all; 
    my $rs = Baseliner->model('Baseliner::BaliJob')->search(
        { 'me.id'=>{ -in =>\@ids } },
        {
            page=>$p{page} // 1, rows=>$p{limit} // 20,
            order_by => { -desc => 'me.starttime' },
        }
    );
    my $pager = $rs->pager;
    my $cnt = $pager->total_entries;
    return map { 
        my %res = $_->get_columns;
        my $text = join ', ', 
        map {
            "$_: $res{$_}" 
        } keys %res;
        +{ title=>$_->name, text=>$text, url=>[ $_->id, $_->name ], type=>'log' }
    } $rs->all;
}

sub get {
    my ($self, $id ) = @_;
    return Baseliner->model('Baseliner::BaliJob')->find($id) if $id =~ /^[0-9]+$/;
    return Baseliner->model('Baseliner::BaliJob')->search({ name=>$id })->first;
}

sub list_by_type {
    my $self = shift ;
    my @types = @_;
    return Baseliner->model('Baseliner::BaliJob')->search({ type=>{ -in => [ @types ] } });
}

sub check_scheduled {
    my $self = shift;
    my @services = Baseliner->model('Services')->search_for( scheduled=>1 );
    foreach my $service ( @services ) {
        my $frequency = $service->frequency;
        unless( $frequency ) {
            $frequency = Baseliner->model('Config')->get( $service->frequency_key );
        }
        if( $frequency ) {
            my $last_run = Baseliner->model('Baseliner::BaliJob')->search({ runner=> $service->key }, { order_by=>{ '-desc' => 'starttime' } })->first;
        }
    }
}

sub job_name {
    my $self = shift;
    my $p = shift;
    my $prefix = $p->{type} eq 'promote' ? 'N' : 'B';
    return sprintf( $p->{mask}, $prefix, $p->{bl} eq '*' ? 'ALL' : $p->{bl} , $p->{id} );
}

sub top_job {
    my ($self, %p )=@_;
    my $rs = Baseliner->model('Baseliner::BaliJobItems')->search({ %p }, { order_by => { '-desc' => 'id_job.id' }, prefetch=>['id_job'] });
    return undef unless ref $rs;
    my $row = $rs->next;
    return undef unless ref $row;
    return $row->id_job; # return the job row
}

sub is_in_active_job {
    my ($self, $ns )=@_;
    
    my $rs = Baseliner->model('Baseliner::BaliJobItems')->search({ item=> $ns }, { order_by => { '-desc' => 'id_job.id' }, prefetch=>['id_job'] });
    while( my $r = $rs->next ) {
        if(  $r->id_job->is_active ) {
            return $r->id_job;
        }
    }
    return undef;
}

sub cancel {
    my ($self, %p )=@_;
    my $job = Baseliner->model('Baseliner::BaliJob')->search({ id=> $p{id} })->first;
    if( ref $job ) {
        #TODO allow cancel on run, and let the daemon kill the job,
        #    or let the chained runner or simplechain to decide how to cancel the job nicely
        _throw _loc('Job %1 is currently running and cannot be deleted') unless( $job->is_not_running );
        if ( $job->status =~ /^CANCELLED/ ) {
           $job->delete;
        } else {
           event_new 'event.job.cancel' => { job=>$job, self=>$self } => sub {
               $job->status( 'CANCELLED' );
               $job->update;
           };
        }
    } else {
        _throw _loc('Could not find job id %1', $p{id} );
    }
}

sub resume {
    my ($self, %p )=@_;
    my $id = $p{id} or _throw 'Missing job id';
    my $job = bali_rs('Job')->find( $id );
    my $silent = $p{silent}||0;
    my $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$id, same_exec=>1, exec=>'last', silent=>$silent );
    $runner->logger->warn( _loc('Job resumed by user %1', $p{username} ) ) if ! $silent;
    $job->status('READY');
    $job->update;
}

register 'event.job.rerun';

sub rerun {
    my ($self, %p )=@_;
    my $jobid = $p{jobid} or _throw 'Missing job id';
    my $username = $p{username} or _throw 'Missing username';
    my $realuser = $p{realuser} || $username;

    my $job = Baseliner->model('Baseliner::BaliJob')->search({ id=> $jobid })->first;
    _throw _loc('Job %1 not found.', $jobid ) unless ref $job;
    _throw _loc('Job %1 is currently running (%2) and cannot be rerun', $job->name, $job->status)
        unless( $job->is_not_running );

    event_new 'event.job.rerun' => { job=>$job } => sub {
        if( $p{run_now} ) {
            my $now = DateTime->now;
            $now->set_time_zone(_tz);
            my $end = $now->clone->add( hours => 1 );
            my $ora_now =  $now->strftime('%Y-%m-%d %T');
            my $ora_end =  $end->strftime('%Y-%m-%d %T');
            $job->schedtime( $ora_now );
            $job->starttime( $ora_now );
            $job->maxstarttime( $ora_end );
        }
        $job->rollback( 0 );
        $job->status( 'READY' );
        $job->step( $p{step} || 'PRE' );
        $job->username( $username );
        my $exec = $job->exec + 1;
        $job->exec( $exec );
        $job->update;
        my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
        $log->info(_loc("Job restarted by user %1, execution %2", $realuser, $exec));
    };
}

sub create {
    my ($self, %p )=@_;

    my $job;
    master_new 'job' => $p{name} => sub { # this is transaction "aware"
        my $mid = shift;
        $p{mid} = $mid;
        $job = $self->_create( %p );
    };
    return $job;
}

sub _create {
    my ($self, %p )=@_;
    my $ns = $p{ns} || '/';
    my $bl = $p{bl} || '*';

    my $contents = $p{items} || $p{contents};
    my $config = Baseliner->model('ConfigStore')->get( 'config.job' );
    #FIXME this text based stuff needs to go away
    my $jobType = (defined $p{approval}->{reason} && $p{approval}->{reason}=~ m/fuera de ventana/i)
        ? $config->{emer_window}
        : $config->{normal_window};

    my $status = $p{status} || 'IN-EDIT';
    #$now->set_time_zone('CET');
    my $now = DateTime->now(time_zone=>_tz);
    my $end = $now->clone->add( hours => $config->{expiry_time}->{$jobType} || 24 );

    $p{starttime}||=$now;
    $p{maxstarttime}||=$end;

    ## allow the creation of jobs executed outside Baseliner, with older dates
    my ($starttime, $maxstarttime ) = ( $p{starttime}, $p{maxstarttime} );
    $starttime =  $starttime->strftime('%Y-%m-%d %T');
    $maxstarttime =  $maxstarttime->strftime('%Y-%m-%d %T');

    my $type = $p{type} || $p{job_type} || $config->{type};

    my $job = Baseliner->model('Baseliner::BaliJob')->create({
            name         => 'temp' . $$,
            mid          => $p{mid},
            starttime    => $starttime,
            schedtime    => $starttime,
            maxstarttime => $maxstarttime,
            status       => $status,
            step         => $p{step} || 'PRE',
            type         => $type,
            runner       => $p{runner} || $config->{runner},
            username     => $p{username} || $config->{username} || 'internal',
            comments     => $p{comments},
            ns           => $ns,
            bl           => $bl,
    });

    # setup name
    my $name = $config->{name}
        || $self->job_name({ mask=>$config->{mask}, type=>$type, bl=>$bl, id=>$job->id });

    _log "****** Creating JOB id=" . $job->id . ", name=$name, mask=" . $config->{mask};
    $config->{runner} && $job->runner( $config->{runner} );
    $config->{chain} && $job->chain( $config->{chain} );

    $job->name( $name );
    $job->update;

    # create a hash stash

    my $log = new BaselinerX::Job::Log({ jobid=>$job->id });

    # publish release names to the log, just in case
    my @original_contents = _unique _array  $contents;
    my $original ='';
    foreach my $it ( _array $contents ) {
        my $ns = Baseliner->model('Namespaces')->get( $it->{ns} );
        try {
            $original .= '<li>' . $ns->ns_type . ": " . $ns->ns_name
                if( $ns->does('Baseliner::Role::Container') );
        } catch { };
    }
    $log->info( _loc('Job elements requested for this job: %1', '<br>'.$original ) )
        if $original;

    # create job items
    if( ref $contents eq 'ARRAY' ) {
        my $contents = $self->container_expand( $contents );
        my @item_list;
        for my $item ( _array $contents ) {
            $item->{ns} ||= $item->{item};
            _throw _loc 'Missing item ns name' unless $item->{ns};
            my $ns = Baseliner->model('Namespaces')->get( $item->{ns} );
            my $app = try { $ns->application } catch { '' };
            # check rfc
            Baseliner->model('RFC')->check_rfc( $app, $ns->rfc )
                if $config->{check_rfc};
            # check contents job status
            _log "Checking if in active job: " . $item->{ns};
            my $active_job = $self->is_in_active_job( $item->{ns} );
            _fail _loc("Job element '%1' is in an active job: %2", $item->{ns}, $active_job->name)
                if ref $active_job;
                    # item => $item->{ns},
            my $provider=$1 if $item->{provider} =~ m/^namespace\.(.*)$/g;
            my $items = $job->bali_job_items->create(
                {
                    data        => _dump( $item->{data} || $item->{ns_data} ),
                    item        => $ns->does('Baseliner::Role::Container')?"$provider/".$ns->{ns_name}:$item->{ns},
                    service     => $item->{service},
                    provider    => $item->{provider},
                    id_job      => $job->id,
                    application => $app,
                }
            );
            #$items->update;
            # push @item_list, '<li>'.$item->{ns}.' ('.$item->{ns_type}.')';
            # push @item_list, '<li>'. ($ns->does('Baseliner::Role::Container')?$ns->{ns_name}:$item->{ns}) . ' ('.$item->{ns_type}.')';
            push @item_list, '<li><b>'.$item->{ns_type}.':</b> '.$ns->{ns_name};
        }
        _throw 'No hay contenido de pase' unless @item_list > 0;

        # log job items
        if( @item_list > 10 ) {
            my $msg = _loc('Job contents: %1 total items', scalar(@item_list) );
            $log->info( $msg, data=>join("\n",@item_list) );
        } else {
            # my $item = "";
            # for ( @item_list ) {
                # item .= "$_\n";
                # }
            $log->info(_loc('Job contents: %1', join("\n",@item_list)) );
        }
    }

    # now let it run
    # if(  $p{approval}  ) {
    if ( exists $p{approval}{reason} ) {
        # approval request executed by runner service
        $job->stash_key( approval_needed => $p{approval} );
    }
    if ( ref $p{job_stash} eq 'HASH' ) {
        while( my ($k,$v) = each %{ $p{job_stash} } ) {
            $job->stash_key( $k => $v );
        }
    }
    $job->status( 'READY' );
    $job->update;
    return $job;
}

sub container_expand {
    my ($self, $contents ) = @_;
    my @ret;
    for my $job_item ( _array $contents ) {
        _throw _loc 'Missing item ns name' unless $job_item->{ns};
        _log "Checking if this is a container: " . $job_item->{ns};
        my $ns = Baseliner->model('Namespaces')->get( $job_item->{ns} );
        try {
            if( $ns->does('Baseliner::Role::Container') ) {
                push @ret, $job_item;
                _log "Checking contents of " . $job_item->{ns};
                my $contents = [ $ns->contents ];
                push @ret, @{ $self->container_expand( $contents ) || [] };
            } else {
                push @ret, $job_item;
            }
        } catch {
            my $err = shift;
            _log "Error retrieving release contents: $err";
        };
    }
    return \@ret;
}

sub status {
    my ($self,%p) = @_;
    my $jobid = $p{jobid} or _throw 'Missing jobid';
    my $status = $p{status} or _throw 'Missing status';
    my $r = Baseliner->model('Baseliner::BaliJob')->search({ id=>$jobid })->first;
    $r->status( $status );
    $r->update;
}

sub notify { #TODO : send to all action+ns users, send to project-team
    my ($self,%p) = @_;
    my $type = $p{type};
    my $jobid = $p{jobid} or _throw 'Missing jobid';
    my $job = Baseliner->model('Baseliner::BaliJob')->find( $jobid )
        or _throw "Job id $jobid not found";
    my $log = new BaselinerX::Job::Log({ jobid=>$jobid });
    my $status = $p{status} || $job->status || $type;
    my $mailcfg   = Baseliner->model('ConfigStore')->get( 'config.comm.email' );

    if( $job->step ne 'RUN' && $job->status !~ /ERROR|KILLED/ ) {
        $log->debug(_loc( "Notification skipped for job %1 step %2 status %3",
            $job->name,
            $job->step,
            $job->status ));
    }
    try {
        my $subject = _loc('Job %1: %2', $job->name, _loc($status) );
        my $last_log = $job->last_log_message;
        my $message = ref $last_log ? $last_log->{text} : _loc($type);
        my $username = $job->username;
        my $u = Baseliner->model('Users')->get( $username );
        my $realname = $u->{realname};
        $log->debug( _loc("Notifying user %1: %2", $username, $subject) );
        my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $job->jobid );
        Baseliner->model('Messaging')->notify(
            subject => $subject,
            message => $message,
            sender  => $mailcfg->{from},
            to => { users => [ $username ] },
            carrier =>'email',
            template => 'email/job.html',
            template_engine => 'mason',
            vars   => {
                action    => _loc($type), #started or finished
                job       => $job->name,
                message   => $message,  # last log msg
                realname  => $realname,
                status    => _loc($status),
                subject   => $subject,  # Job xxxx: (error|finished|started|cancelled...)
                to        => $username,
                username  => $username,
                url_log   => $url_log,
            }
            #cc => { actions=> ['action.notify.job.end'] },
        );
    } catch {
        my $err = shift;
        my $msg =  _loc( 'Error sending job notification: %1', $err );
        _log $msg;
        $log->warn( _loc("Failed to notify users"), data=> $msg );
    };
}

sub export {
    my ($self,%p) = @_;
    exists $p{id} or _throw 'Missing job id';
    return eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 60;
        $p{format} ||= 'raw';
        my $rs = Baseliner->model('Baseliner::BaliJob')->search(
            { 'me.id'=>$p{id} },
            {
                prefetch =>['bali_log','job_stash']
            }
        );
        rs_hashref($rs);
        my $job = $rs->first or _throw "Job id $p{id} not found";

        my $data = _dump({ job=>$job });
        alarm 0;
        return $data if $p{format} eq 'raw';
        return compress($data) if $p{format} eq 'zip';

        my $tar = Archive::Tar->new or _throw $!;
        # dump
        $tar->add_data( 'data.txt', $data );
        # job files
        my $name = $job->{name};
        my $inf = Baseliner->model('ConfigStore')->get( 'config.job.runner' );
        my $job_dir = File::Spec->catdir( $inf->{root}, $name );
        if( -e $job_dir ) {
            #$tar->setcwd( $inf->{root} );
            my @files;
            Path::Class::dir( $job_dir )->recurse(callback=>sub{
                my $f = shift;
                return if $f->is_dir;
                push @files, "" . $f->relative($inf->{root});
            });
            chdir $inf->{root};
            $tar->add_files( @files );
        }
        my $tmpfile = File::Spec->catdir( $inf->{root}, "job-export-$name.tgz" );
        return $tar->write unless $p{file};
        $tar->write($tmpfile,COMPRESS_GZIP);;
        return $tmpfile;
    };
    if( $@ eq "alarm\n" ) {
        _log "*** Job export timeout: $p{id}";
    }
    return undef;
}


sub user_has_access {
    my ($self,%p) = @_;
    my $username = $p{username};
    my $perm = Baseliner->model('Permissions');
    my $where={ id=>$p{id} };
    if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
        my @user_apps = $perm->user_namespaces( $username ); # user apps
        $where->{'bali_job_items.application'} = { -in => \@user_apps };
        # username can view jobs where the user has access to view the jobcontents corresponding app
        # username can view jobs if it has action.job.view for the job set of job_contents projects/app/subapl
    }
    return Baseliner->model('Baseliner::BaliJob')->search($where)->first;
}

sub log {
    my ($self,%p) = @_;
    $p{jobid} or _throw 'Missing jobid';
    my $args = { jobid=>$p{jobid} };
    $args->{exec} = $p{job_exec} if $p{job_exec} > 0;
    return new BaselinerX::Job::Log( $args );
}

sub get_summary {
    my ($self, %p) = @_;
    my $row = Baseliner->model( 'Baseliner::BaliJob' )->search( {id => $p{jobid}, exec => $p{job_exec}} )->first;
    my $result = {};

    if ( $row ) {
        my $execution_time;
        my $endtime;
        my $starttime;
        $starttime = Class::Date->new( $row->starttime);
        if ($row->endtime){
            $endtime = Class::Date->new( $row->endtime);
            $execution_time = $endtime - $starttime;
        } else {
            my $now = Class::Date->new( _now);
            $execution_time = $now - $row->starttime;
        }
        $result = {
            bl => $row->bl,
            status => $row->status,
            starttime => $starttime,
            execution_time => $execution_time,
            endtime => $endtime,
            type => $row->type,
            owner => $row->owner,
            last_step => $row->step,
            rollback => $row->rollback
        }
    }
    return $result;
}

sub get_services_status {
    my ( $self, %p ) = @_;
    defined $p{jobid} or _throw "Missing jobid";
    my $rs = 
        Baseliner->model( 'Baseliner::BaliLog' )
        ->search( {id_job => $p{jobid}, exec => $p{job_exec}, milestone => {'>', 1}}, {order_by => 'id'} );

    my $row_stash = Baseliner->model( 'Baseliner::BaliJobStash' )->search( {id_job => $p{jobid}} )->first;

    my $job_stash     = $row_stash? _load $row_stash->stash : {};

    my $chain_id = 1;
    if ( $job_stash->{runner_data}->{chain_id} ) {
        $chain_id = $job_stash->{runner_data}->{chain_id};
    }
    my $chain_rs =
        Baseliner->model( 'Baseliner::BaliChainedService' )
        ->search( { chain_id => $chain_id } );

    my $services = {};

    while ( my $chained_service = $chain_rs->next() ) {
        $services->{$chained_service->step.'-'.$chained_service->key } = $chained_service->description;
    }

    my $service_statuses = {2 => 'Success', 3 => 'Warning', 4 => 'Error'};
    my $result;
    my %added_services;
    while ( my $row = $rs->next ) {
        my $info = Baseliner->model( 'Baseliner::BaliLog' )->search( {id_job => $p{jobid}, exec => $p{job_exec}, lev => {'<>','debug'}, service_key => $row->service_key, step => $row->step}, {order_by => 'id'} )->first;
        if ( $info ) {
            if ( !$added_services{$row->step.$row->service_key} ) {
                push @{$result->{$row->step}}, 
                    { description => $services->{$row->step.'-'.$row->service_key}, service=>$row->service_key, status => $service_statuses->{$row->milestone}, id => $row->id};
                $added_services{$row->step.$row->service_key} = 1;
            }
        }
    } ## end while ( my $row = $rs->next)

    return $result;
} ## end sub get_services_status

sub get_contents {
    my ( $self, %p ) = @_;
    defined $p{jobid} or _throw "Missing jobid"; 
    my $result;

    my $rs = Baseliner->model( 'Baseliner::BaliJobItems' )->search( {id_job => $p{jobid}} );
    my $row_stash =
        Baseliner->model( 'Baseliner::BaliJobStash' )->search( {id_job => $p{jobid}} )->first;

    my $job_stash     = $row_stash? _load $row_stash->stash : {};
    my $elements      = $job_stash->{elements};
    my @elements_list;
    $result = {};
    if($elements){
        @elements_list = $elements->list( '' );
        my %topics;
        my %technologies;
    
        while ( my $row = $rs->next ) {
            my $ns = ns_get( $row->item );
            push @{$result->{packages}->{$ns->{ns_data}->{project}}}, { name => $ns->{ns_name}, type => $ns->{ns_type} };
            push @{$result->{elements}},
                map { 
                    try {
                        $_->path =~ /^\/.*?\/.*?\/(.*?)\/.*?/;
                        #_log $_->path;
                        my $tech = $1;
                        $technologies{$tech} = '';
                        {name => $_->name, status => $_->status, path => $_->path} 
                    } catch {
                        +{}
                    };
                } @elements_list;
    
            my $rs_topics =
                Baseliner->model( 'Baseliner::BaliRelationship' )->search( {from_ns => $ns->{ns_type}.'/'.$ns->{ns_name}} );
    
            while ( my $topic = $rs_topics->next ) {
                my $row_topics =
                    Baseliner->model( 'Baseliner::BaliTopic' )->search( {mid => $topic->to_id} )->first;
                ##$topics{$topic->to_id} = $row_topics->title;
                $topics{$topic->to_id} = $row_topics->title if $row_topics && $row_topics->title;
            }
        } ## end while ( my $row = $rs->next)
    
        push @{$result->{topics}}, map { {id => $_, title => $topics{$_}} } keys %topics;
        push @{$result->{technologies}}, keys %technologies;        
    }
    return $result;

} ## end sub get_contents

sub get_outputs {
    my ( $self, %p ) = @_;
    my $rs =
        Baseliner->model( 'Baseliner::BaliLog' )->search(
        {
            -and => [
                id_job => $p{jobid},
                exec => $p{job_exec},
                lev    => {'<>', 'debug'},
                -or    => [
                    more      => {'<>', undef},
                    milestone => 1
                ]
            ]
        },
        {order_by => 'id'}
        );
    my $result;
    my $qre = qr/\.\w+$/;

    while ( my $r = $rs->next ) {
        my $more = $r->more;
        my $data = _html_escape( uncompress( $r->data ) || $r->data );

        my $data_len  = $r->data_length || 0;
        my $data_name = $r->data_name   || '';
        my $file =
            $data_name =~ $qre ? $data_name
            : ( $data_len > ( 4 * 1024 ) )
            ? ( $data_name || $self->_select_words( $r->text, 2 ) ) . ".txt"
            : '';
        my $link;
        if ( $more eq 'link') {
            $link = $data;
        }
        push @{$result->{outputs}}, {
            id      => $r->id,
            datalen => $data_len,
            more => {
                more      => $more,
                data_name => $r->data_name,
                data      => $data_len ? 1 : 0,
                file      => $file,
                link      => $link
            },
            }

    } ## end while ( my $r = $rs->next)
    return $result;
} ## end sub get_outputs

sub _select_words {
    my ( $self, $text, $cnt ) = @_;
    my @ret = ();
    for ( $text =~ /(\w+)/g ) {
        next if length( $_ ) <= 3;
        push @ret, $_;
        last if @ret >= $cnt;
    }
    return join '_', @ret;
} ## end sub _select_words

1;
