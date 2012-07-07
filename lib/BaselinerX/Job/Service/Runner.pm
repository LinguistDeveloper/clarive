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
use IO::CaptureOutput;
use Carp;
use Try::Tiny;
use Sys::Hostname;
use utf8;
use namespace::autoclean;

has 'jobid' => ( is=>'rw', isa=>'Int' );
has 'name' => ( is=>'rw', isa=>'Str' );
has 'logger' => ( is=>'rw', isa=>'Object' );
has 'ns' => ( is=>'rw', isa=>'Str' );
has 'bl' => ( is=>'rw', isa=>'Str' );
has 'config' => ( is=>'rw', isa=>'Any', default=>sub{{}} );
has 'step' => ( is=>'rw', isa=>'Str', trigger=>sub { 
    my ($self) = @_;
    my $logger = $self->logger;
    $logger->max_step_level( 2 );
});
has 'step_status' => ( is=>'rw', isa=>'HashRef[Str]', default=>sub{{}} );
has 'current_service' => ( is=>'rw', isa=>'Maybe[Str]', trigger=>sub { 
    my ($self, $val) = @_;
    my $logger = $self->logger;
    $logger->current_service( $val );
    $logger->max_service_level( 2 );
});
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
has 'failing' => ( is=>'rw', isa=>'Bool', default=>0 );
has 'job_type' => ( is=>'rw', isa=>'Str' );
has 'job_stash' => ( is=>'rw', isa=>'HashRef', default=>sub {{}}  );
has 'job_data' => ( is=>'rw', isa=>'HashRef', default=>sub {{}} );
has 'job_row' => ( is=>'rw', isa=>'Any' );
has 'exec' => ( is => 'rw', isa => 'Maybe[Int]', default => 1 );

with 'Baseliner::Role::Service';
with 'Baseliner::Role::JobRunner';

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

register 'action.notify.job.start' => { name=>_loc('Notify when job has started') };
register 'action.notify.job.end' => { name=>_loc('Notify when job has finished') };
register 'action.job.approve' => { name=>_loc('Approve jobs') };

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

    bali service.xxxx --job-continue 999 --job-exec [same|next]

This special constructor is called from the Services Model.

=cut
#   TODO move this to the Jobs model?
sub new_from_id {
    my ($class,%p)=@_;
    $p{jobid} or _throw 'Missing jobid parameter';
    $p{step} ||= $p{same_exec} ? 'POST' : 'RUN';
    my $service_name = $p{service_name} || '';
    my $exec = delete $p{exec};
    # defer for when we have a logger
    my $current_service = delete $p{current_service}; 
    my $step = delete $p{step}; 
    # instantiate myself
    my $job = $class->new( %p );
    my $row = $job->row;
    _log "Created job object for jobid=$p{jobid} exec=$exec";
    # increment the execution in the Job row
    if( $exec =~ m/next/i ) {
        $row->exec( $row->exec + 1);
    } elsif( is_number $exec ) {
        $row->exec( $exec );
    }
    $row->update;
    $job->exec( $row->exec );
    $job->job_type( $row->type );
    $job->job_data( { $row->get_columns } );
    # setup the logger
    my $log = $job->logger( BaselinerX::Job::Log->new({ jobid=>$p{jobid}, job=>$job }) );
    $job->current_service( $service_name );
    $job->step( $step );
    #thaw job stash from table
    my $stash = $job->thaw;
    $log->info(_loc("Job revived"), data=>_dump($stash) );
    $job->bl( $row->bl );
    $job->job_stash( $stash );
    # initialize my job name
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
    my $log = $job->logger( BaselinerX::Job::Log->new({ jobid=>$p{jobid}, job=>$job }) );
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
    $self->logger( new BaselinerX::Job::Log({ jobid=>$jobid, job=>$self }) );
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
        }

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
        $step eq 'RUN' and Baseliner->model('Jobs')->notify( jobid=>$jobid, type=>'started' );

        #******************  start main runner  ******************
        # typically, a Chain runner, like SimpleChain, or a single service
        _log "Runner launching service $runner";
        IO::CaptureOutput::capture( sub {
            $c->launch( $runner ); 
        }, \$runner_output, \$runner_output );
        _log "Finished service $runner";

        # exit fast if suspended
        return 0 if $self->status eq 'SUSPENDED';

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
            if( scalar keys %{ $self->job_stash->{rollback} } ) { # is there something to rollback?
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
                $self->logger->debug( _loc('No rollback data found in the stash') );
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

    # get out now
    return if $self->status eq 'SUSPENDED';

    # log debug all output
    $self->logger->debug(_loc("Job execution output"), data=>$runner_output );

    # last message on log
    my $loglevel = $self->status =~ /ERROR/ ? 'error' : 'info';
    my $log_status = $self->status =~ /ERROR/i ? 'ERROR' : 'OK'; 

    # finish up step
    if( $step eq 'PRE' ) {
        $self->logger->$loglevel( _loc("Job prerun finished with status %1", _loc( $log_status ) ), milestone=>$self->logger->max_step_level );
    } elsif( $step eq 'RUN' ) {
        $self->logger->$loglevel( _loc("Job run finished with status %1", _loc( $log_status ) ), milestone=>$self->logger->max_step_level);
        $self->finish($self->status);
    } else {
        $self->logger->$loglevel( _loc("Job finished with status %1", _loc( $log_status ) ), milestone=>$self->logger->max_step_level );
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
        my $stash = _dump( $self->job_stash );
        $r->stash( $stash ); 
        $r->update;
        $self->logger->debug( _loc('Job stash stored ok'), data=>$stash );
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
    $self->logger->warn( _loc('Suspending Job' ) );
    $self->job_row->status( $self->status( 'SUSPENDED' ) );
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
    return $self->job_stash->{root} || $self->job_stash->{path} || do { 
        require BaselinerX::Job::Service::Init;
        BaselinerX::Job::Service::Init->new->root_path( job=>$self );
    };
}

=head2 parse_job_vars ( $str, \%user_data )

Parse a string for variables C<${variable}>, replacing it with:

    1) job info 
    2) stash data
    3) user supplied data

=cut
sub parse_job_vars {
    my ($self, $data, $user_vars ) = @_;
    $user_vars ||= {};
    my $stash = $self->job_stash->{vars} || {};
    my $vars = {
        job      => $self->name,
        job_root => $self->root,
        job_id   => $self->jobid,
        jobid    => $self->jobid,
        job_exec => $self->exec,
        job_step => $self->step,
        bl       => $self->bl,
        # merging:
        %$stash,
        %$user_vars,
    };

    # substitute vars
    Baseliner::Utils::parse_vars( $data, $vars, throw=>0 );
}


1;
