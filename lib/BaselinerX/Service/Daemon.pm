package BaselinerX::Service::Daemon;
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
        {  id=>'mode', label=>'Job Spawn Mode (spawn,fork,detach)', type=>'str', default=>'detach' },
        {  id=>'unified_log', label=>'Set true to have jobs report to dispatcher log', type=>'bool', default=>0 },
    ]
};


# daemon - listens for new jobs
sub job_daemon {
    my ($self,$c,$config)=@_;
    my $freq = $config->{frequency};

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

    # set job query order
    for( 1..1000 ) {
        my $now = mdb->now;

        my @query_roll = (
                # Immediate chain (PRE, POST or now=1 )
                { 
                    '$or' => [ 
                        { step => 'PRE', status=>'READY' }, 
                        { step => 'POST', status=>mdb->in('READY','ERROR','KILLED','EXPIRED','REJECTED') }, 
                        { now=>1 }, 
                    ]
                }, 
                # Scheduled chain (RUN and now<>0 )
                { 
                    schedtime        => { '$lte', "$now" },
                    maxstarttime     => { '$gt',  "$now" },
                    status           => 'READY',
                    step             => 'RUN',
                    now              => { '$ne' => 1 },
                } 
        );
        for my $roll ( @query_roll ) {
            my @docs = ci->job->find( $roll )->all;
            foreach my $job ( map { ci->new( $_->{mid} ) } @docs ) {
                _log _loc( "Starting job %1 for step %2", $job->name, $job->step );
                $job->status('RUNNING');
                $job->save;
                # get proc mode from job bl
                my $mode = $^O eq 'Win32'
                    ? 'spawn'
                    : Baseliner->model('ConfigStore')->get('config.job.daemon', bl=>$job->bl || '*' )->{mode} || 'spawn';
                my $step = $job->step;
                my $loghome = $ENV{BASELINER_LOGHOME};
                $loghome ||= $ENV{BASELINER_HOME} . './logs';
                _mkpath $loghome;
                my $logfile = File::Spec->catfile( $ENV{BASELINER_LOGHOME} || $ENV{BASELINER_HOME} || '.', $job->name . '.log' );
                # set job pid to 0 to avoid checking until it sets it's own pid
                $job->pid( $$ );
                $job->save; 
                # launch the job proc
                if( $mode eq 'spawn' ) {
                    _log "Spawning job (mode=$mode)";
                    my $pid = $self->runner_spawn( mid=>$job->mid, runner=>$job->runner, step=>$step, jobid=>$job->mid, logfile=>$logfile );
                } elsif( $mode =~ /fork|detach/i ) {
                    _log "Forking job " . $job->mid . " (mode=$mode), logfile=$logfile";
                    $self->runner_fork( mid=>$job->mid, runner=>'Core', step=>$step, jobid=>$job->mid, logfile=>$logfile, mode=>$mode, unified_log=>$config->{unified_log} );
                } else {
                    _throw _loc("Unrecognized mode '%1'", $mode );
                }
                ;
                _log("Reaping children..."), $self->reap_children if $mode =~ /fork|detach/;
            }
        }
        $self->check_job_expired();
        last if $EXIT_NOW;
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
        $0 = "clarive job $p{jobid} (#$mid)";
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
            $job->save;
        };
        exit 0;
    } else {
        _log _loc("***** ERROR: Could not fork job '%1'", $p{jobid} );
    }
}

# expired or pid alive
sub check_job_expired {
    my ($self)=@_;
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
    $rs = ci->job->find({ status => mdb->in('RUNNING','PAUSED','TRAPPED') });
    my $hostname = Util->my_hostname();
    while( my $doc = $rs->next ) {
        my $ci = ci->new( $doc->{mid} );
        _debug sprintf "Checking job row alive: job=%s, pid=%s, host=%s (my host=%s)", $ci->name, $ci->mid, $ci->pid, $ci->host, $hostname;
        if( $ci->host eq $hostname ) {
            if( $ci->pid>0 && !pexists($ci->pid) ) {
                _warn "Not alive: " . $ci->name;
                # recheck
                if( $ci->pid>0 ) {
                    my $rec = $ci->load;
                    next unless ref $rec;
                    next unless $rec->{status} eq 'RUNNING';
                }
                my $msg = _loc("Detected killed job %1 (mid %2 status %3, pid %4)", $ci->name, $ci->mid, $ci->status, $ci->pid ); 
                _warn( $msg ); 
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

1;

