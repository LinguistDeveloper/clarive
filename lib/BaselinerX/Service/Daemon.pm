package BaselinerX::Service::Daemon;
use Baseliner::Plug;
use Baseliner::Utils;

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
        my $now = _now;

        my @query_roll = (
                # Immediate chain (PRE, POST or now=1 )
                { 
                    '-or' => [ 
                        { step => 'PRE', status=>'READY' }, 
                        { step => 'POST', status=>['READY','ERROR','KILLED','EXPIRED'] }, 
                        { now=>1 } 
                    ]
                    #step=>{ '-or' => ['PRE', 'POST'] },
                }, 
                # Scheduled chain (RUN and now<>0 )
                { 
                    schedtime => { '<' , $now }, 
                    maxstarttime => { '>' , $now }, 
                    status => 'READY', step=>'RUN',
                    now => { '<>', 1 },
                } 
        );
        for my $roll ( @query_roll ) {
            my @rs = DB->BaliJob->search($roll);
            foreach my $r ( @rs ) {
                _log _loc( "Starting job %1 for step %2", $r->name, $r->step );
                $r->status('RUNNING');
                $r->update;
                # get proc mode from job bl
                my $mode = $^O eq 'Win32'
                    ? 'spawn'
                    : Baseliner->model('ConfigStore')->get('config.job.daemon', bl=>$r->bl || '*' )->{mode} || 'spawn';
                my $step = $r->step;
                my $loghome = $ENV{BASELINER_LOGHOME};
                $loghome ||= $ENV{BASELINER_HOME} . './logs';
                _mkpath $loghome;
                my $logfile = File::Spec->catfile( $ENV{BASELINER_LOGHOME} || $ENV{BASELINER_HOME} || '.', $r->name . '.log' );
                # set job pid to 0 to avoid checking until it sets it's own pid
                $r->pid( 0 );
                $r->update; 
                # launch the job proc
                if( $mode eq 'spawn' ) {
                    _log "Spawning job (mode=$mode)";
                    my $pid = $self->runner_spawn( mid=>$r->mid, runner=>$r->runner, step=>$step, jobid=>$r->id, logfile=>$logfile );
                } elsif( $mode =~ /fork|detach/i ) {
                    _log "Forking job " . $r->id . " (mode=$mode), logfile=$logfile";
                    $self->runner_fork( mid=>$r->mid, runner=>$r->runner, step=>$step, jobid=>$r->id, logfile=>$logfile, mode=>$mode, unified_log=>$config->{unified_log} );
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
    my $pid = fork;
    if( $pid ) { # parent
        waitpid( $pid, 0 );
        return $pid;
    } elsif( $pid == 0 ) { # child
        $SIG{CHLD} = 'DEFAULT';
        if ($pid = Fork) { exit 0; }
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
        my $job = Baseliner::CI->new( $mid );
        my $job_run = $job->create_runner( same_exec=>1, logfile=>$p{logfile} );
        $job_run->run();
        #Baseliner->model('Services')->launch( 'job.run', data=>{ runner=>$p{runner}, step=>$p{step}, jobid=>$p{jobid}, logfile=>$p{logfile} } );
        exit 0;
    } else {
        _log _loc("***** ERROR: Could not fork job '%1'", $p{jobid} );
    }
}

sub check_job_expired {
    my ($self)=@_;
    #_log( "Checking for expired jobs..." );
    my $rs = DB->BaliJob->search({ 
            maxstarttime => { '<' , _now }, 
            status => 'READY',
    });
    while( my $row = $rs->next ) {
        _log( _loc("Job %1 expired (maxstartime=%2)" , $row->name, $row->maxstarttime ) );
        $row->status('EXPIRED');
        $row->endtime( _now );
        $row->update;
    }
    # some jobs are running with pid, and some without, 
    #   but if they have any of these statuses, they should have a pid>0 and exist, otherwise their dead
    $rs = DB->BaliJob->search({ status => ['RUNNING','PAUSED','TRAPPED'] });
    my $hostname = Util->my_hostname();
    while( my $row = $rs->next ) {
        _debug sprintf "Checking job row alive: job=%s, pid=%s, host=%s (my host=%s)", $row->name, $row->pid, $row->host, $hostname;
        if( $row->host eq $hostname ) {
            if( $row->pid>0 && !pexists($row->pid) ) {
                _warn "Not alive: " . $row->name;
                # recheck
                if( $row->pid>0 ) {
                    my $job = DB->BaliJob->search({ id=>$row->id, step=>$row->step, pid=>{'>',0} })->first;
                    next unless ref $job;
                    next unless $job->status eq 'RUNNING';
                }
                _warn( _loc("Detected killed job %1 (status %2, pid %3)", $row->name, $row->status, $row->pid ) ); 
                $row->status('KILLED');
                $row->endtime( _now );
                $row->update;
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

