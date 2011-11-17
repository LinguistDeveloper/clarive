package BaselinerX::Job::Model::Jobs;
use Moose;
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
            my $last_run = Baseliner->model('Baseliner::BaliJob')->search({ runner=> $service->key }, { order_by=>'starttime desc' })->first;
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
    my $rs = Baseliner->model('Baseliner::BaliJobItems')->search({ %p }, { order_by => "id_job.id desc", prefetch=>['id_job'] });
    return undef unless ref $rs;
    my $row = $rs->next;
    return undef unless ref $row;
    return $row->id_job; # return the job row
}

sub is_in_active_job {
    my ($self, $ns )=@_;
    
    my $rs = Baseliner->model('Baseliner::BaliJobItems')->search({ item=> $ns }, { order_by => "id_job.id desc", prefetch=>['id_job'] });
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
        _throw _loc('Job %1 is currently running and cannot be deleted')
            unless( $job->is_not_running );
        $job->delete if $job->status =~ /^CANCELLED/; $job->status( 'CANCELLED' );
        $job->update;
    } else {
        _throw _loc('Could not find job id %1', $p{id} );
    }
}

sub resume {
    my ($self, %p )=@_;
    my $id = $p{id} or _throw 'Missing job id';
    my $job = bali_rs('Job')->find( $id );
    my $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$id, same_exec=>1 );
    $runner->logger->warn( _loc('Job resumed by user %1', $p{username} ) ) if $p{username};
    $job->status('READY');
    $job->update;
}

sub rerun {
    my ($self, %p )=@_;
    my $jobid = $p{jobid} or _throw 'Missing job id';
    my $username = $p{username} or _throw 'Missing username';
    my $realuser = $p{realuser} || $username;

    my $job = Baseliner->model('Baseliner::BaliJob')->search({ id=> $jobid })->first;
    _throw _loc('Job %1 not found.', $jobid ) unless ref $job;
    _throw _loc('Job %1 is currently running (%2) and cannot be rerun', $job->name, $job->status)
        unless( $job->is_not_running );

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
}

sub create {
    my ($self, %p )=@_;

    my $job;
    Baseliner->model('Baseliner')->txn_do( sub {
        $job = $self->_create( %p );
    });
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

    my ($starttime, $maxstarttime ) = ( $now, $end );
    ($starttime, $maxstarttime ) = $p{starttime} < $now
        ? ( $now , $end )
        : ($p{starttime} , $p{maxstarttime} );
    $maxstarttime = $starttime->clone->add( hours => $config->{expiry_time}->{$jobType} || 24 );

    #if( is_oracle ) {
        $starttime =  $starttime->strftime('%Y-%m-%d %T');
        $maxstarttime =  $maxstarttime->strftime('%Y-%m-%d %T');
    #}
    my $job = Baseliner->model('Baseliner::BaliJob')->create({
            name         => 'temp' . $$,
            starttime    => $starttime,
            schedtime    => $starttime,
            maxstarttime => $maxstarttime,
            status       => $status,
            step         => $p{step} || 'PRE',
            type         => $p{type} || $p{job_type} || $config->{type},
            runner       => $p{runner} || $config->{runner},
            username     => $p{username} || $config->{username} || 'internal',
            comments     => $p{comments},
            ns           => $ns,
            bl           => $bl,
    });

    # setup name
    my $name = $config->{name} 
        || $self->job_name({ mask=>$config->{mask}, type=>'promote', bl=>$bl, id=>$job->id });

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
            _throw _loc("Job element '%1' is in an active job: %2", $item->{ns}, $active_job->name)
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
    if ( exists $p{options} ) {
        $job->stash_key( job_options => _array $p{options} );
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
        Baseliner->model('Messaging')->notify(
            subject => $subject,
            message => $message,
            sender => _loc('Job Manager'),
            to => { users => [ $username ] },
            carrier =>'email',
            template => 'email/job.html',
            template_engine => 'mason',
            vars   => {
                subject   => $subject,  # Job xxxx: (error|finished|started|cancelled...)
                message   => $message,  # last log msg 
                action    => _loc($type), #started or finished
                username  => $username,
                realname  => $realname, 
                job       => $job->name,
                status    => _loc($status), 
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
1;
