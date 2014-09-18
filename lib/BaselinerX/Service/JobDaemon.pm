package BaselinerX::Service::JobDaemon;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Service';

use Proc::Background;
use Proc::Exists qw(pexists);

our $EXIT_NOW = 0;

has 'proc_list' => ( is=>'rw', isa=>'ArrayRef', default=>sub { [] } );

register 'service.job.daemon' => {
    name    => 'Watch for new jobs',
    config  => 'config.job.daemon',
    daemon  => 1,
    handler => \&job_daemon,
};

register 'service.job.dummy' => {
    name => 'A Dummy Job',
    handler => sub {
        my ($self,$c)=@_;
        _log "DUMMY";
        my $job = $c->stash->{job};
        $job->logger->info("A dummy job is running");
    }
};

register 'config.job.daemon' => {
    metadata=> [
        {  id=>'frequency', label=>'Job Server Frequency', type=>'int', default=>10 },
        {  id=>'wait_for_killed', label=>'Seconds to wait before declaring job killed', type=>'int', default=>10 },
        {  id=>'mode', label=>'Job Spawn Mode (spawn,fork,detach)', type=>'str', default=>'detach' },
        {  id=>'unified_log', label=>'Set true to have jobs report to dispatcher log', type=>'bool', default=>0 },
        {  id=>'job_host_affinity', label=>'All steps of jobs must been executed in the same host', type=>'bool', default=>1}
    ]
};


# daemon - listens for new jobs
sub job_daemon {
    my ($self,$c,$config)=@_;
    my $freq = $config->{frequency};
    my %discrepancies;  # keep a count on these

    my $startup = { cwd=>Cwd::cwd, proc=>$^X, script=>$0, argv=>[ @ARGV ] };
    # enable signal handler before sleep
    $SIG{USR1} = sub { _log "Exitting job daemon via restart signal"; $EXIT_NOW=1 };
    $SIG{USR2} = sub { _log "Restarting job daemon via restart signal..."; 
        chdir $startup->{cwd};
        _log "Changed dir to $startup->{cwd}";
        my $cmd;
        # $0 maybe set by parent on fork
        $startup->{script} =~ /service.job.daemon/
            ? $cmd = $startup->{script}
            : $cmd = "'". join("' '", $startup->{proc}, $startup->{script}, 'service.job.daemon', @{ $startup->{argv} || [] } ). "'";
        _log "Restart command: $cmd";
        exec $cmd;
    };
    _log "Job daemon started with frequency ${freq}s";
    require Baseliner::Sem;
    my $hostname = Util->my_hostname();
    # set job query order
    for( 1..1000 ) {
        my $sem = Baseliner::Sem->new( key=>'job_daemon', who=>"job_daemon", internal=>1 );
        $sem->take;
        #sleep 20;
        my $now = mdb->now;

        # Immediate chain (PRE, POST or now=1 )
        my @query_roll = ( 
            {   
                '$or' => [ 
                    { step => 'PRE', status=>'READY' }, 
                    { step => 'POST', status=>mdb->in('READY','ERROR','KILLED','EXPIRED','REJECTED') }, 
                    { now=>1 }, 
                ], 
                
            },
        # Scheduled chain (RUN and now<>0 )
            { 
                schedtime        => { '$lte', "$now" },
                maxstarttime     => { '$gt',  "$now" },
                status           => 'READY',
                step             => 'RUN',
                now              => { '$ne' => 1 }, 
                host         => mdb->in([$hostname,'',undef])
            }
        );
        for my $roll ( @query_roll ) {
            $roll->{host} = mdb->in([$hostname,'',undef]) if $config->{job_host_affinity};
            my @docs = ci->job->find( $roll )->all;
            JOB: foreach my $job_doc ( @docs ) {
                local $Baseliner::_no_cache = 1;  # make sure we get a fresh CI
                my $job = ci->new( $job_doc->{mid} );  # reload job here, so that old jobs in the roll get refreshed
                if( $job->status ne $job_doc->{status} ) {
                    _log _loc( "Skipping job %1 due to status discrepancy: %2 != %3", $job->name, $job->status, $job_doc->{status} );
                    if( $discrepancies{ $job->mid } > 10 ) {  
                        #$job->save; # fixes the discrepancy
                        delete $discrepancies{ $job->mid };
                    } else {
                        $discrepancies{ $job->mid }++;
                    }
                    next JOB;
                }
                _log _loc( "Starting job %1 for step %2", $job->name, $job->step );
                # set job pid to 0 to avoid checking until it sets it's own pid
                $job->update( status=>'RUNNING', pid=>0, host => $hostname );
                
                # get proc mode from job bl
                my $mode = $^O eq 'Win32'
                    ? 'spawn'
                    : Baseliner->model('ConfigStore')->get('config.job.daemon', bl=>$job->bl || '*' )->{mode} || 'spawn';
                my $step = $job->step;
                my $loghome = $ENV{BASELINER_LOGHOME};
                $loghome ||= $ENV{BASELINER_HOME} . './logs';
                _mkpath $loghome;
                my $logfile = File::Spec->catfile( $ENV{BASELINER_LOGHOME} || $ENV{BASELINER_HOME} || '.', $job->name . '.log' );
                
                # launch the job proc
                if( $mode eq 'spawn' ) {
                    _log "Spawning job (mode=$mode)";
                    my $pid = $self->runner_spawn( mid=>$job->mid, runner=>$job->runner, step=>$step, jobid=>$job->mid, logfile=>$logfile );
                } elsif( $mode =~ /fork|detach/i ) {
                    _log "Forking job " . $job->mid . " (mode=$mode), logfile=$logfile";
                    $self->runner_fork( mid=>$job->mid, runner=>'Core', step=>$step, jobid=>$job->jobid, logfile=>$logfile, mode=>$mode, unified_log=>$config->{unified_log} );
                } else {
                    _throw _loc("Unrecognized mode '%1'", $mode );
                }
                ;
                _log("Reaping children..."), $self->reap_children if $mode =~ /fork|detach/;
            }
        }
        $self->check_job_expired($config);
        $self->check_cancelled();
        last if $EXIT_NOW;
        if ( $sem ) {
            $sem->release;
        }
        sleep $freq;    
        last if $EXIT_NOW;
    }
    _log "Job daemon stopped.";
}

sub runner_spawn {
    my ($self, %p ) =@_;
    my $cmd = "bin/bali job.run --runner \"". $p{runner} ."\" --step $p{step} --jobid ". $p{jobid} . " --logfile '$p{logfile}' >>'$p{logfile}' 2>&1";
    my $proc = Proc::Background->new( $cmd );
    push @{ $self->{proc_list} }, $proc;
    return $proc->pid;
}

sub Fork {
    my $pid;
    FORK: {
        if (defined($pid = fork)) {
            return $pid;
        } elsif ($! =~ /No more process/) {
            _warn "No processes available. Sleeping and retrying in a few seconds...";
            sleep 5;
            redo FORK;
        } else {
            _log "Job child: Can't fork: $!";
        }
    }
}

sub reap_children {
    require POSIX;
    POSIX::waitpid(-1, POSIX::WNOHANG());
}

sub runner_fork {
    my ($self, %p ) =@_;
    my $mid = $p{mid} or _throw 'Missing parameter job `mid`';
    require POSIX;
    mdb->disconnect;
    my $pid = fork;
    if( $pid ) { # parent
        waitpid( $pid, 0 );
        return $pid;
    } elsif( $pid == 0 ) { # child
        $SIG{CHLD} = 'DEFAULT';
        if ($pid = Fork) { exit 0; }  # refork and exit parent (XXX necessary?)
        if( $p{mode} eq 'detach' ) {
            _log "Detaching job...";
            my $sid = POSIX::setsid; 
            $sid > 0 or _throw "Could not detach job $p{jobid}: $!";
            _log "Detached with session id $sid";
        }
        # change child process name for the ps command
        $0 = "clarive job $p{jobid} (#$mid, $p{step})";
        unless( $p{unified_log} ) {
            open (STDOUT, ">>", $p{logfile} ) or die "Can't open STDOUT: $!";
            open (STDERR, ">>", $p{logfile} ) or die "Can't open STDERR: $!";
        }
        my $job;
        try {
            $job = ci->new( $mid );
            $job->logfile( $p{logfile} );
            $job->run( same_exec=>1 );
        } catch {
            my $err = shift;
            # this is job.pm error not caught, this is considered a KILLED (aborted) job
            # no POST will execute since stash situation may be unstable
            my $msg = Util->_loc('Abort by Dispatcher. Job unknown error caught: %1', $err);
            print STDERR "Unknown error in Job with mid=$mid";
            print STDERR $msg;
            $job->logger->error( $msg );
            $job->status('KILLED');
            unlink $job->pid_file;
            $job->save;
        };
        exit 0;
    } else {
        _log _loc("***** ERROR: Could not fork job '%1'", $p{jobid} );
    }
}

# expired or pid alive
sub check_job_expired {
    my ($self, $config)=@_;
    #_log( "Checking for expired jobs..." );
    my $rs = ci->job->find({ 
            maxstarttime => { '$lt' => _now }, 
            status => 'READY',
    });
    while( my $doc = $rs->next ) {
        _log( _loc("Job %1 expired (mid=%3, maxstartime=%2)" , $doc->{name}, $doc->{maxstarttime}, $doc->{mid} ) );
        my $ci = ci->new( $doc->{mid} ) or do { _error _loc 'Job ci not found for id_job=%1', $doc->{id}; next };
        $ci->status('EXPIRED');
        $ci->endtime( _now );
        $ci->save;
    }
    # some jobs are running with pid, and some without, 
    #   but if they have any of these statuses, they should have a pid>0 and exist, otherwise they are dead
    my @running = ('RUNNING','PAUSED','TRAPPED');
    $rs = ci->job->find({ status => mdb->in(@running) });
    my $hostname = Util->my_hostname();
    while( my $doc = $rs->next ) {
        my $ci = ci->new( $doc->{mid} );
        _debug sprintf "Checking job row alive: job=%s, mid=%s, pid=%s, host=%s (my host=%s)", $ci->name, $ci->mid, $ci->pid, $ci->host, $hostname;
        if( $ci->host eq $hostname && $ci->step =~ /PRE|RUN|POST/ ) {
            if( $ci->pid>0 && !pexists($ci->pid) ) {
                _warn "Not alive: " . $ci->name;
                # TODO recheck is slow (sleeps), try forking
                # recheck: sleep a little, reload the row, than check the pid again
                sleep( $config->{wait_for_killed} // 10 );  # sleep for row wait
                if( $ci->pid>0 ) {
                    my $rec = $ci->load;
                    next unless ref $rec;
                    next unless $rec->{status} ~~ @running;
                    next unless $ci->pid;
                }
                next if pexists($ci->pid);
                my $msg = _loc("Detected killed job %1 (mid %2 status %3, pid %4)", $ci->name, $ci->mid, $ci->status, $ci->pid ); 
                _warn( $msg ); 
                # TODO consider using $ci->update
                $ci->logger->error( $msg ); 
                $ci->status('KILLED');
                $ci->endtime( _now );
                $ci->save;
            } else {
                #if( $^O eq 'MSWin32' ) {
                #    use Win32::Process;
                #    my $win_proc; 
                #    if( Win32::Process::Open( $win_proc, $row->pid ) ) {
                #        $win_proc->Kill;
                #    }

                #} else {
                #    _log "PID " . $row->pid . " ok.";
                #}
            }
        }
    }

    foreach my $proc ( @{ $self->{proc_list} } ) {
        unless( $proc->alive ) {
            $proc->die;
        }
    }
    return;
}

# Cancelled by user in monitor
sub check_cancelled {
    my ($self)=@_;
    my $hostname = Util->my_hostname();
    my $rs = ci->job->find({ 
            status => 'CANCELLED', '$or'=>[ {pid=>{'$gt' => 0}},{ pid=>{ '$ne'=>'0'}} ] 
    });
    while( my $doc = $rs->next ) {
        my $job = ci->new( $doc->{mid} );
        _debug sprintf "Looking for job kill candidate: job=%s, mid=%s, pid=%s, host=%s (my host=%s)", $job->name, $job->mid, $job->pid, $job->host, $hostname;
        if( $job->host eq $hostname ) {
            if( $job->pid > 0  ) {
                if( pexists($job->pid) ) {
                    my $sig = 16;
                    _warn "Killing job (sig=$sig): " . $job->name;
                    my $msg;
                    if( kill $sig => $job->pid ) {
                        # recheck
                        $msg = _loc("Killed issued to job %1 process due to CANCEL status (mid %2 status %3, pid %4, host %5)", 
                            $job->name, $job->mid, $job->status, $job->pid, $hostname ); 
                        _warn( $msg ); 
                    } else {
                        $msg = _loc("Could not kill Job %1 process due to CANCEL: pid not found (mid %2 status %3, pid %4, host %5)", 
                                $job->name, $job->mid, $job->status, $job->pid, $hostname ); 
                        _warn( $msg ); 
                    }
                    $job->logger->error( $msg ); 
                    $job->status('KILLED');
                    $job->endtime( _now );
                    unlink $job->pid_file;
                    $job->save;
                } else {
                    # process not found, killed by hand? just reset PID
                    _warn sprintf "Cancelled job %s pid %s not found. Resetting pid to 0: ", $job->name, $job->pid;
                    $job->pid( 0 );
                    $job->save;
                }
            }
        }
    }

    foreach my $proc ( @{ $self->{proc_list} } ) {
        unless( $proc->alive ) {
            $proc->die;
        }
    }
    return;
}

1;

