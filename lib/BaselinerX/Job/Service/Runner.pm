package BaselinerX::Job::Service::Runner;
=head1 NAME

BaselinerX::Job::Service::Runner - job main initializer.

=head1 DESCRIPTION

Executes jobs sent by the daemon in an independent process.

Usually, the runner runs one time for each step for a given job.

=cut
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use BaselinerX::Job::Elements;
use Capture::Tiny;
use Carp;
use Try::Tiny;
use Sys::Hostname;
use utf8;

has 'jobid' => ( is=>'rw', isa=>'Int' );
has 'name' => ( is=>'rw', isa=>'Str' );
has 'logger' => ( is=>'rw', isa=>'Object' );
has 'ns' => ( is=>'rw', isa=>'Str' );
has 'bl' => ( is=>'rw', isa=>'Str' );
has 'config' => ( is=>'rw', isa=>'Any', default=>sub{{}} );
has 'step' => ( is=>'rw', isa=>'Str' );
has 'step_status' => ( is=>'rw', isa=>'HashRef[Str]', default=>sub{{}} );
has 'status' => ( is=>'rw', isa=>'Str', 
    trigger=>sub {
        my ($self, $status)=@_;
        my $step = $self->step or return;
        $self->step_status->{$step} = $status;
        my @who = caller(3) ;
        _log "Status being changed to $status by " . join(', ', $who[0], $who[2] );
        # write status to DB
        #$self->row->status( $status ); 
        #$self->row->update;
    }
);
has 'rollback' => ( is=>'rw', isa=>'Bool', default=>0 );
has 'job_type' => ( is=>'rw', isa=>'Str' );
has 'job_stash' => ( is=>'rw', isa=>'HashRef', default=>sub {{}}  );
has 'job_data' => ( is=>'rw', isa=>'HashRef', default=>sub {{}} );
has 'job_row' => ( is=>'rw', isa=>'Any' );
has 'exec' => ( is => 'rw', isa => 'Maybe[Int]', default => 1 );

with 'Baseliner::Role::Service';

register 'config.job.runner' => {
    metadata => [
        { id => 'root', default => do { $ENV{BASELINER_TEMP} || $ENV{TEMP} || File::Spec->tmpdir() } },
        { id => 'step', name    => 'Which phase of the job, pre, post or run', default => 'RUN' },
        # jobid is also supposed to be here
    ]
};

register 'service.job.run' => {
    name    => 'Job Runner',
    config  => 'config.job',
    handler => \&job_run,
};

register 'service.job.stash.print' => {
    name    => 'Job Stash Printer',
    config  => 'config.job',
    handler => \&stash_print,
};

register 'action.notify.job.start' => { name=>'Notify when job has started' };
register 'action.notify.job.end' => { name=>'Notify when job has finished' };
register 'action.job.approve' => { name=>'Approve jobs' };

our %next_step = ( PRE => 'RUN',   RUN => 'POST',  POST => 'END' );
our %next_state  = ( PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

sub row {
    my ($self)=@_;
    my $row = Baseliner->model('Baseliner::BaliJob')->find({ id=>$self->jobid });
    ref $row or _throw _loc 'Could not find job id %1', $self->jobid;
    return $row;
}

=head2 new_from_id

Allows services to execute independently afterwards

=cut
#   TODO move this to the Jobs model?
sub new_from_id {
    my ($class,%p)=@_;
    $p{jobid} or _throw 'Missing jobid parameter';
    $p{step} ||= $p{same_exec} ? 'POST' : 'RUN';
    $p{exec} eq 'last' and $p{exec}=0;
    my $msg=$p{message} || "Job revived";
    
    my $job = $class->new( %p );
    _log "Created job object for jobid=$p{jobid}";
    # increment the execution
    my $row = $job->row ;
    if( $p{'exec'} != 0 ) {
        $row->exec( $row->exec + 1);
        }
    $row->update;
    # setup the logger
    my $log = $job->logger( BaselinerX::Job::Log->new({ jobid=>$p{jobid} }) );
    #thaw job stash from table
    my $stash = $job->thaw;
    $log->info(_loc($msg), data=>_dump($stash) ) if ! $p{silent};
    $job->job_stash( $stash );
    $job->name( $row->name );
    return $job;
}

=head2 clone_from_id

Create a new job from an old one

=cut
#   TODO move this to the Jobs model?
sub clone_from_id {
    my ($class,%p)=@_;
    _throw 'Not implemented';
    $p{jobid} or _throw 'Missing jobid parameter';
    $p{step} ||= $p{same_exec} ? 'POST' : 'RUN';
    my $job = $class->new( %p );
    _log "Created job object for jobid=$p{jobid}";
    # increment the execution
    my $row = $job->row;
    #Baseliner->model('Baseliner::BaliJob')->create(
    $row->exec( $row->exec + 1);
    $row->update;
    # setup the logger
    my $log = $job->logger( BaselinerX::Job::Log->new({ jobid=>$p{jobid} }) );
    $log->info(_loc("Job revived"));
    #thaw job stash from table
    my $stash = $job->thaw;
    $job->job_stash( $stash );
    return $job;
}

sub report_pid {
    my $self = shift;
    my $r = $self->row;
    $r->pid( $$ );
    $r->host( lc Sys::Hostname::hostname() );
    $r->owner( $ENV{USER} || $ENV{USERNAME} ); # os user id
    $r->update;
}

=head2 job_run

All the work is done here. This is the handler for C<service.job.run>.

=cut
sub job_run {
    my ($self,$c,$config)=@_;

    # redirect log $BASELINER_LOGHOME/

    my $jobid = $config->{jobid};
    $self->status('RUNNING');
    $c->stash->{job} = $self;
    $self->jobid( $jobid );
    $self->logger( new BaselinerX::Job::Log({ jobid=>$jobid }) );
    $self->report_pid;
    $self->config( $config );

    # trap all die signals
    $SIG{__DIE__} = \&_throw;

    _log "================================| Starting JOB=" . $jobid;;

    my $step = $config->{args}{step} || $config->{step} or _throw 'Missing step value';

    _throw( "No job chain or service defined for job " . $config->{jobid} )
        unless( $config->{runner} );

    $c->log->debug("Running Service " . $config->{runner} . " for step=$step" ); 

    my $runner_output='';
    my $goto_next = 0;

    try {
        # load job object
        my $r = $self->row;

        # increment the execution
        if( defined $config->{'next-exec'} ) {
            $r->exec( $r->exec + 1 ) ;
            $r->update;
            $self->logger->exec( $r->exec );
        } else {
            $self->exec( $r->exec );
        }        # increment the execution

        $self->name( $r->name );
        $self->job_type( $r->type );
        $self->job_data( { $r->get_columns } );
        $self->bl( $r->bl );
        $self->step( $step || $r->step );
        $self->job_row( $r );
        $self->rollback( $r->rollback );

        my $runner = try { defined $config->{arg_list}->{runner} ? $config->{runner} : $r->runner } 
            catch { $r->runner };  # XXX would be easier to delete the runner default

        _throw( "No job chain or service defined for job " . $config->{jobid} )
            unless( $runner );

        $c->log->debug("Running Service " . $runner . " for step=$step" ); 

        _log _loc("Job initialized: step=%1, status=%2, bl=%3" , $self->step, $self->status, $self->bl );

        #thaw job stash from table
        my $stash = $self->thaw;
        $self->job_stash( $stash );
        $self->job_stash->{step} = $step;

        # send notifications  
        Baseliner->model('Jobs')->notify( jobid=>$jobid, type=>'started' )
            if( $step eq 'RUN' );

        #******************  start main runner  ******************
        # typically, a Chain runner, like SimpleChain, or a single service
        $runner_output = Capture::Tiny::tee_merged {
            $c->launch( $runner ); 
        };

        # exit fast if suspended or waiting
        _log "Hay que salir? " . $self->status;
        return 0 if $self->status =~ m{SUSPENDED|WAITING};

        # finish it if ok
        $self->logger->debug( _loc('Step %1 finished', _loc( $step ) ) );

        unless( $self->rollback ) {
            #*** normal step finish
            $goto_next = 1;
        } else {  # rollback
            if( $self->job_stash->{rollback_broken_step} eq 'PRE' ) {
                $self->finish();
            } else {
                $goto_next = 1;
            }
        }
        $self->freeze; # store the stash
        return 1;
    } catch {
        my $error = shift;

        # log the error
        _log "*** Error running Job $jobid ****";
        _log $error;
        $self->logger->error( $error || _loc('Internal Error') );

        # now, rollback if needed
        unless( $self->rollback ) { # if we are already rolling back, skip

            # Changes by Eric Lorenzana @ 2011-11-04
            # Distributions from development to testing (at dev state) are not allowed in BdE.

            my $from_state = [values %{$self->job_stash->{rollback}->{transition}->{state}}]->[0]; 
            my $to_state   = [values %{$self->job_stash->{rollback}->{transition}->{to_state}}]->[0];

            _log "from_state: $from_state";
            _log "to_state:   $to_state";

            if(   (scalar keys %{ $self->job_stash->{rollback} })  # Is there something to rollback?
               && ($from_state ne 'Desarrollo')                    # Am I not promoting from state Desarrollo?
               && ($to_state ne 'Pruebas')                         # Am I not promoting to state Pruebas?
              )  # End of changes
            { 
                # prepare rollback:
                $self->logger->info( _loc('Starting job rollback for step %1', $step) );
                my $r = $self->row;
                $r->now( 1 ); # schedule it for immediate execution
                $r->rollback( 1 );
                $r->step( 'PRE' );
                $r->status( $self->status('READY') );
                $r->update;

                $self->job_stash->{rollback_broken_step} = $step;
                $self->freeze;
                return; # no messages yet
            } else {
                # no rollback needed
                scalar keys %{$self->job_stash->{rollback}}
                  ? $self->logger->debug(_loc('There are no rollbacks in TEST environments'))
                  : $self->logger->debug(_loc('No rollback data found in the stash'));
                $self->status('ERROR');
                $self->finish($self->status);
                $self->freeze;
            }
        } else {
            # already rolling back, but failed
            $self->logger->error( _loc('Rollback failed') );
            $self->status('ERROR');
            $self->finish($self->status);
            $self->freeze;
        }
    };

    # get out now is SUSPENDED or WAITING
    _log "Hay que salir? " . $self->status;
    return if $self->status =~ m{SUSPENDED|WAITING};

    # log debug all output
    $self->logger->debug(_loc("Job execution output"), data=>$runner_output );

    # last message on log
    my $logprerunlevel = $self->status =~ /ERROR/ ? 'error' : 'debug';
    my $loglevel = $self->status =~ /ERROR/ ? 'error' : 'info';
    my $log_status = $self->status =~ /ERROR/i ? 'ERROR' : 'OK'; 

    # finish up step
    if( $step eq 'PRE' ) {
        $self->logger->$logprerunlevel( _loc("Job prerun finished with status %1", _loc( $log_status ) ), milestone=>1 );
    } elsif( $step eq 'RUN' ) {
        $self->logger->$loglevel( _loc("Job run finished with status %1", _loc( $log_status ) ), milestone=>1);
        $self->finish($self->status);
    } else {
        $self->logger->$loglevel( _loc("Job finished with status %1", _loc( $log_status ) ), milestone=>1 );
        $self->finish($self->status);
    }

    # commit status - visible to daemon now
    # $self->row->status( $self->status ); 
    # $self->row->endtime( _now ); 
    # $self->row->update;

    # change step and status
    $self->goto_next_step if $goto_next;

    # notify
    Baseliner->model('Jobs')->notify( jobid=>$jobid, type=>'finished', status=>$self->status ) 
        if( $self->step eq 'POST' || $self->status eq 'ERROR' );

    _log _loc( "Job finished step %1 with status %2",  $self->step, $self->status );
}

sub finish {
    my ($self, $status ) = @_;
    my $r = $self->row;
    $r->status( $status || $self->status( 'FINISHED' ) );
    $r->endtime( _now ); 
    $r->update;
}

sub goto_next_step {
    my $self = shift;
    $self->goto_step( $self->step );
}

=head2 goto_step

Updates the step in the row following the next_state rules

=cut
sub goto_step {
    my ($self, $current_step ) = @_;
    my $r = $self->row;
    # ask the daemon to go to the next step
    if( $self->status eq 'APPROVAL' ) {
        $r->status( $self->status );
    } else {
        my $next_step = $next_state{ $current_step };
        $r->status( $self->status( $next_step ) ) if defined $next_step;
    }
    $self->logger->debug(
         _loc('Going from step %1 to next step %2', $current_step, $next_step{$current_step} )
    );
    $r->step( $next_step{ $current_step } );
    $r->update;
}

=head2 thaw

Retrieve the stash or reinitialize a job.

=cut
sub thaw {
    my $self = shift;
    my $stash = {};
    my $r = $self->row;
    if( $r->stash ) {
        try {
            $stash = _load( $r->stash ); 
        } catch {
            $self->logger->warn( 'No he podido recuperar el stash de pase', shift );
        };
    } else {
        _log "No stash for job";
    }
    return $stash;
}

=head2 freeze

Freeze job stash to table

=cut
sub freeze {
    my $self = shift;
    try {
        my $r = $self->row;
        $r->stash( _dump( $self->job_stash ) ); 
        $r->update;
        $self->logger->debug( _loc('Job stash stored ok') );
    } catch {
        $self->logger->warn( _loc('Could not store job stash: %1', shift) );
    };
}

=head2 pause

Pause job.

When pausing, the status changes to PAUSE. Pause means that the job process 
is still alive, albeit frozen waiting for a change in status.

Pause happens on the spot. The job blocks at this same call:

    $job->pause;  # may stay here for 10 hours ...

=cut
sub pause {
    my ($self, %p ) = @_;
    $self->logger->warn( _loc('Job pausing...') );
    #$self->status('PAUSE');
    $self->job_row->status( 'PAUSED' );
    $self->job_row->update;
    $p{reason} ||= _loc('unspecified');
    my $timeout = $p{timeout} || $self->config->{pause_timeout} || 3600 * 24;  # 1 day default
    my $freq    = $p{frequency} || $self->config->{pause_frequency} || 5;
    $self->logger->debug( _loc('Pause timeout (%1 seconds)', $timeout ) );
    my $t = 0;
    while( $self->job_row->get_from_storage->status eq 'PAUSED' ) {
        $self->logger->warn( _loc('Paused. Reason: %1', $p{reason} ) );
        sleep $freq;
        $t += $freq;
        if( defined $timeout && $t > $timeout ) {
            $self->logger->warn( _loc('Pause timed-out at %1 seconds', $timeout ) );
            last;
        }
    }
    $self->job_row->status( $self->status );  # resume back to my last real status
    $self->job_row->update;
}

sub suspend {
    my ($self, %p ) = @_;
    $self->freeze;
    my $msg = $p{message} || 'Suspending Job';
    my $status = $p{status} || 'SUSPENDED';
    $self->logger->warn( _loc( $msg ) ) if ! $p{silent};
    $self->job_row->status( $self->status( $status ) );
    $self->job_row->update;
}

sub stash_print {
    my ($self,$c,$config)=@_;

    my $jobid = $config->{jobid};
    $self->jobid( $jobid );
    my $r = $self->row;
    print "Job stash for job id $jobid:\n";
    length $r->stash ? print $r->stash : print "(empty)\n";
}

sub stash {  # not just an alias
    my ($self, %hash)=@_;
    for my $key ( keys %hash ) {
         $self->job_stash->{$key} = $hash{$key};
    }
    return $self->job_stash;
}

sub root {
    my ($self)=@_;
    return $self->job_stash->{root} || $self->job_stash->{path};
}

1;
