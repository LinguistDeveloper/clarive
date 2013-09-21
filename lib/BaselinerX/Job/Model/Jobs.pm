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

sub search_provider_name { 'Jobs' };
sub search_provider_type { 'Job' };
sub search_query {
    my ($self, %p ) = @_;
    my $c = $p{c};
    $c->request->params->{limit} = $p{limit} // 1000;
    $c->forward( '/job/monitor_json');
    my $json = delete $c->stash->{json};
    return map {
        my $r = $_;
        #my $summary = join ',', map { "$_: $r->{$_}" } grep { defined $_ && defined $r->{$_} } keys %$r;
        my @text = 
            grep { length }
            map { "$_" }
            map { _array( $_ ) }
            grep { defined }
            map { $r->{$_} }
            keys %$r;
        chomp @text;
        +{
            title => $r->{name},
            info  => $r->{ts},
            text  => join(', ', @text ),
            url   => [ $r->{id}, $r->{name} ],
            type  => 'log'
        }
    } _array( $json->{data} );
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

sub top_job {
    my ($self, %p )=@_;
    my $rs = Baseliner->model('Baseliner::BaliJobItems')->search({ %p }, { order_by => { '-desc' => 'id_job.id' }, prefetch=>['id_job'] });
    return undef unless ref $rs;
    my $row = $rs->next;
    return undef unless ref $row;
    return $row->id_job; # return the job row
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
        my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $jobid );
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

sub log_this {
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
        my @log_all = DB->BaliLog->search( 
            { 
                id_job => $p{jobid}, 
                exec => $p{job_exec}
             },
             {
                select => [
                    'step',
                    'service_key',
                    { min => 'timestamp', -as => 'starttime' },
                    { max => 'timestamp', -as => 'endtime'}
                ],
                group_by => ['step','service_key']
              }
        )->hashref->all;

        @log_all = sort { Class::Date->new($a->{starttime})->epoch <=> Class::Date->new($b->{starttime})->epoch } @log_all;

        my $active_time = 0;
        my $services_time = {};

        my $endtime;
        my $starttime;
        
        for my $service ( @log_all ) {
            
            my $service_starttime = Class::Date->new($service->{starttime});
            my $service_endtime = Class::Date->new($service->{endtime});

            $starttime = Class::Date->new( $service_starttime ) if !$starttime;
            $endtime = Class::Date->new( $service_endtime );

            my $service_time = $service_endtime - $service_starttime;

            if ( $service_time && $service_time->sec > 0) {
                $services_time->{$service->{step}."#".$service->{service_key}} = $service_time->sec;
            }
            $active_time += $service_endtime - $service_starttime;
        }
        
        my $execution_time;
        if ($row->endtime){
            $endtime = Class::Date->new( $row->endtime );
            $execution_time = $endtime - $starttime;
        } else {
            my $now = Class::Date->now;
            $execution_time = $now - $starttime;
        }

        # Fill services time
        $result = {
            bl => $row->bl,
            status => $row->status,
            starttime => $starttime,
            execution_time => $execution_time,
            active_time => $active_time,
            endtime => $endtime,
            type => $row->type,
            owner => $row->username,
            last_step => $row->step,
            rollback => $row->rollback,
            services_time => $services_time
        }
    }
    return $result;
}

sub get_services_status {
    my ( $self, %p ) = @_;
    defined $p{jobid} or _throw "Missing jobid";
    my $job = _ci( ns=>'job/'. $p{jobid} );
    my $summary = $p{summary};
        
    my $result = {};
    my $ss = {};
    my $log_levels = { warn => 3, error => 4, debug => 2, info => 2 };
    
    my @log = DB->BaliLog->search(
        {
            id_job => $p{jobid},
            exec   => $p{job_exec}
        },
        {
            select => [
                'step',
                'service_key',
                'lev'
            ],
        }
    )->hashref->all;

    for my $sl ( @log ) {
        if ( $sl->{service_key} && $summary->{services_time}->{$sl->{step}."#".$sl->{service_key} }) {
            if ( !$ss->{ $sl->{step} }->{ $sl->{service_key} }) {
                $ss->{ $sl->{step} }->{ $sl->{service_key} } = 'info';
            }
            if ( $log_levels->{$ss->{ $sl->{step} }->{ $sl->{service_key} }} < $log_levels->{$sl->{lev}} ) {

                $ss->{ $sl->{step} }->{ $sl->{service_key} } = $sl->{lev};
            }            
        }
    }

    my %seen;  
    my $load_results = sub {
        my @keys = @_; 
        for my $r ( @keys ) {
            my ($step, $skey, $id ) = @{ $r }{ qw(step service_key id) };
            next if $seen{ $skey . '#' . $step };
            $seen{ $skey . '#' . $step } = 1;
            my $status = $ss->{$step}->{$skey};
            next if $status eq 'debug';
            if ( $status ne 'error') {
                next if ( !$summary->{services_time}->{$step."#".$skey } );
            }
            $status = uc( substr $status,0,1 ) . substr $status,1;
            $status = 'Warning' if $status eq 'Warn';
            $status = 'Success' if $status eq 'Info';
            push @{ $result->{$step} }, {
                service     => $skey,
                description => $skey,
                status      => $status,
                id          => $id,
            };
        }
    };
    
    # # load previous exec services, in case we had exec=1, step=PRE, then, exec=2, step=RUN
    # my @keys = DB->BaliLog->search({ id_job=>$p{jobid}, exec =>{ '!=' => $p{job_exec} }, service_key=>{ '<>'=>undef } },
    #     { order_by=>{ -asc=>'id' }, select=>[qw(step service_key id)] } ) # ->hash_unique_on('service_key');
    #     ->hashref->all;
    # $load_results->( @keys );

    # load current keys
    my @keys = DB->BaliLog->search({ id_job=>$p{jobid}, exec => $p{job_exec}, service_key=>{ '<>'=>undef } },
        { order_by=>{ -asc=>'id' }, select=>[qw(step service_key id)] } ) # ->hash_unique_on('service_key');
        ->hashref->all;
    # reset keys for current exec 
    for my $r ( @keys ) {
        $result->{$r->{step}}=[];
    }
    $load_results->( @keys );
    
    return $result;  # {   PRE=>[ {},{} ], RUN=>... }
} 

sub get_contents {
    my ( $self, %p ) = @_;
    defined $p{jobid} or _throw "Missing jobid"; 
    my $result;

    my $job = _ci( ns=>'job/' . $p{jobid} );
    my $job_stash = $job->job_stash;
    my @changesets = _array( $job->changesets );
    my $changesets_by_project = {};
    my @natures = map { $_->name } _array( $job->natures );
    my $items = $job_stash->{items};
    for my $cs ( @changesets ) {
        my @projs = _array $cs->projects;
        push @{ $changesets_by_project->{$  projs[0]->{name}} }, $cs;
    }
    $result = {
        packages => $changesets_by_project,
        items => $items, 
        technologies => \@natures,
    };
    
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
        if ( $more && $more eq 'link') {
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
