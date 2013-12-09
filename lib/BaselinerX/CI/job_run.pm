package BaselinerX::CI::job_run;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _now);
use Try::Tiny;

extends 'BaselinerX::CI::job';

has exec               => qw(is rw isa Num default 1);
has pid                => qw(is rw isa Num lazy 1), default=>sub{ return $$ };
has host               => qw(is rw isa Str lazy 1), default=>sub{ return Util->my_hostname() };
has owner              => qw(is rw isa Str lazy 1), default=>sub{ return $ENV{USER} || $ENV{USERNAME} };
has same_exec          => qw(is rw isa Bool default 0); 
has last_error         => qw(is rw isa Maybe[Str] default '');
has prev_status        => ( is=>'rw', isa=>'Any' );  # saves previous status
has final_status       => ( is=>'rw', isa=>'Any' );  # so that services can request a final status like PAUSE
has parent_job         => (is=>'rw', isa=>'Num', required=>1 );
has pause_timeout      => qw(is rw isa Num default), 3600 * 24;  # 1 day max
has pause_frequency    => qw(is rw isa Num default 5);  # 5 seconds
#  has failing         => ( is=>'rw', isa=>'Bool', default=>0 );  # XXX desirable?

#has_cis 'parent_job'; 
#sub rel_type {
#    { 
#        parent_job => [ to_mid => 'job_run' ] ,
#    };
#}


with 'Baseliner::Role::JobRunner';

# save status for the step
around status => sub {
    my $orig = shift;
    my $self = shift;
    my $status = shift;
    my $old_status = $self->{status} // '';
    $self->prev_status( $old_status );
    my $step = $self->step;
    if( defined $status && $self->{status} ne $status ) {
        $self->step_status->{$step} = $status if $step;
        my @who = caller(3) ;
        _debug "Status has changed to $status by " . join(', ', $who[0], $who[2] );
    }
    $self->status_trans( Util->_loc($status) );
    return defined $status 
        ? $self->$orig( $status )
        : $self->$orig();
};

around exec => sub {
    my $orig = shift;
    my $self = shift;
    my $exec = shift;
    if( defined $exec && $exec > 1 && ref $self->{logger} ) {
        $self->logger->exec( $exec );
    }
    return defined $exec 
        ? $self->$orig( $exec )
        : $self->$orig();
};

around update_ci => sub {
    my $orig = shift;
    my $self = shift;
    
    $self->$orig( @_ ); 
};


service 'job.run' => {
    name    => 'Job CI Runner',
    handler => sub{
        my ($self,$c,$config)=@_;
        $self->run();
    },
};

sub run {
    my ($self, %p) = @_;

    $self->status('RUNNING');
    $self->write_pid;
    if( !$self->same_exec && ( ($self->endtime && $self->step) || $self->rollback ) ) {
        $self->exec( $self->exec + 1);  # endtime=job has run before, a way to detect first time
        _log "Setting exec to " . $self->exec;
    }
    $self->save;
    
    $self->service_levels->{ $self->step } = {};  # restart level aggregator
    #$self->service_levels->{ _loc('Core') } = {};  # restart level aggregator
    
    # trap all die signals
    local $SIG{__DIE__} = \&_throw;

    local $Baseliner::logger = sub {
        my ($lev, $cl,$fi,$li, @msgs ) = @_;
        #my $cal = $Baseliner::Utils::caller_level // 2;
        
        #die "calling logger: $lev";
        $lev = 'debug' if $lev eq 'info';
        my $text = $msgs[0];
        if( ref $text ) {    # _log { ... }
            $self->logger->common_log( [$lev,3], _loc('Data dump'), @msgs ); 
        } else {
            $self->logger->common_log( [$lev,3], @msgs ); 
        }
        return 0;
    };

    _log "=========| Starting JOB " . $self->jobid . ", rollback=" . $self->rollback;

    _debug( _loc('Rule Runner, STEP=%1, PID=%2, RULE_ID', $self->step, $self->pid ) );

    # prepare stash for rules
    my $prev_stash = $self->job_stash;
    my $stash = { 
            %{ $prev_stash }, 
            job            => $self,
            bl             => $self->bl, 
            job_step       => $self->step,
            job_dir        => $self->job_dir,
            job_name       => $self->name,
            job_type       => $self->job_type,
            job_mode       => $self->rollback ? 'rollback' : 'forward',
            rollback       => $self->rollback,
            username       => $self->username,
            changesets     => $self->changesets,
            needs_rollback => {},
    };
    #die _dump $stash unless $self->step eq 'INIT';
    
    ROLLBACK:
    my $job_error = 0;
    try {
        my $ret = Baseliner->model('Rules')->run_single_rule( 
            id_rule => $self->id_rule, 
            logging => 1,
            stash   => $stash,
            simple_error => 2,  # hide "Error Running Rule...Error DSL" even as _error
        );
        #$self->logger->debug( 'Stash after rules', $stash );
        $self->job_stash( $stash ); # saves stash to table
        $self->finish( $self->final_status || 'FINISHED' );
    } catch {
        my $err = shift;   
        #$self->logger->debug( 'Stash after rules', $stash );
        $stash->{failing} = 1;
        $self->finish( 'ERROR' );
        $self->logger->error( _loc( 'Job failure: %1', $err ) );
        $self->last_error( $err );
        $self->job_stash( $stash );
        $job_error = 1;
    };

    my $rollback_now = 0;
    my $nr = $stash->{needs_rollback} // {};
    my @needing_rollback = map { $_ } grep { $nr->{$_} } keys %$nr;
    if( $job_error ) {
        if( @needing_rollback && !$self->rollback ) {
            # repeat
            $stash->{rollback} = 1;
            $stash->{job} = $self;
            $self->rollback( 1 );
            $self->status( 'RUNNING' );
            $self->exec( $self->exec + 1);
            $rollback_now = 1;
            $self->logger->info( "Starting *Rollback*", \@needing_rollback );
        } elsif( !@needing_rollback && !$self->rollback ) {
            $self->logger->info( _loc( 'No need to rollback anything.' ) );
        } else {
            $self->logger->error( _loc( 'Error during rollback. Baselines are incosistent, manual intervention required.' ) );
        }
    }

    $self->save;
    $self->save_to_parent_job( natures=>$self->natures, logfile=>$self->logfile, service_levels=>$self->service_levels );
    goto ROLLBACK if $rollback_now;

    #$self->logger->debug( "Job natures....", $self->natures );
    $self->logger->debug( "Job children", $self->children );
    
    # last line on log
    if( $self->status eq 'ERROR' ) {
        $self->logger->error( _loc( 'Job step %1 finished with error', $self->step, $self->status ) );
    } elsif( $self->status eq 'FINISHED' ) { 
        $self->logger->info( _loc( 'Job step %1 finished ok', $self->step ) );
    } else {
        $self->logger->info( _loc( 'Job step %1 finished with status %2', $self->step, $self->status ) );
    }
    if( $self->status eq 'ERROR' && $self->step eq 'POST' ) {
        $self->step('END'); 
        $self->save;
    } else {
        $self->goto_next_step( $self->final_status ) 
    }
    unlink $self->pid_file;
    $self->save_to_parent_job( status=>$self->status, step=>$self->step );
    return $self->status;
}

sub pid_file {
    my ($self)=@_;
    return Util->_file( $ENV{BASELINER_PIDHOME} || $ENV{BASELINER_TMPHOME}, 'cla-job-' . $self->name . '.pid' );
}

sub write_pid {
    my ($self) = @_;
    my $file = $self->pid_file;
    open my $ff, '>', $file or _error( _loc('Could not write pid file for job: %1', $!) );
    print $ff $$;
    close $ff;
}

sub save_to_parent_job {
    my ($self, %p)=@_;
    _debug( sprintf "Save to parent job '%s'", $self->parent_job );
    if( my $parent_job = ci->new( $self->parent_job ) ) {
        $parent_job->update( %p );
    }
}

# called from dsl_run in Rules
sub start_task {
    my ($self,$stmt_name) = @_;
    $self->current_service( $stmt_name );
    $self->logger->debug( "$stmt_name", milestone=>2 );
}

sub back_to_core {
    my ($self)=@_;
    $self->current_service( _loc('Core') ); #"\x{2205}" );
}

our %next_step   = ( CHECK=>'INIT', INIT=>'PRE', PRE => 'RUN', RUN => 'POST', POST => 'END' );
our %next_status  = ( CHECK=>'IN-EDIT', INIT=>'READY', PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

=head2 goto_next_step

Updates the step in the row following the next_status rules

=cut
sub goto_next_step {
    my ($self, $no_status_change ) = @_;
    
    my $current_step = $self->step;

    # STATUS
    my $next_status = $next_status{ $current_step };
    $self->status( $next_status ) if defined $next_status && !$no_status_change;
    
    # STEP
    my $next_step = $next_step{ $current_step };
    $self->logger->debug(
         _loc('Going from step %1 to next step %2', $current_step, $next_step )
    );
    $self->step( $next_step );
    
    # COMMIT
    $self->save;
    return ( $next_step, $next_status );
}

sub finish {
    my ($self, $status ) = @_;
    my $next = $status || 'FINISHED';
    #if( $self->rollback ) {
    #    if( $next eq 'FINISHED' ) {
    #        $next = 'ROLLEDBACK';
    #    } elsif( $next eq 'ERROR' ) {
    #        $next = 'ROLLEDBACKFAIL';
    #    }
    #}
    _debug "JOB FINISHED=$next, rollback=". $self->rollback;
    $self->status( $next );
    $self->endtime( _now ); 
}

=head2 pause

Pause job.

When pausing, the status changes to PAUSE. Pause means that the job process 
is still alive, albeit on stand by waiting for a change in status.

Pause happens on the spot. The job blocks at this same call:

    $job->pause;  # may stay here for 10 hours ...
    
        reason: "log message"
        details: "log data"
        timeout: seconds
        frequency: seconds
        verbose: 0|1  - print message to log continously

=cut
sub pause {
    my ($self, %p ) = @_;
    $self->logger->warn( _loc('Job pausing...') );
    my $saved_status = $self->status;
    $self->status('PAUSED');
    $self->save;
    
    $p{reason} ||= _loc('unspecified');
    $self->logger->info( _loc('Paused. Reason: %1', $p{reason} ), milestone=>1, data=>$p{details} );
    
    my $timeout = $p{timeout} || $self->pause_timeout;
    my $freq    = $p{frequency} || $self->pause_frequency;
    my $t = 0;
    $self->logger->debug( _loc('Setting pause timeout at %1 seconds', $timeout ) );
    # select continuously
    while( $self->job_row->get_from_storage->status eq 'PAUSED' ) {
        $self->logger->info( _loc('Paused. Reason: %1', $p{reason} )) if $p{verbose};
        sleep $freq;
        $t += $freq;
        if( defined $timeout && $t > $timeout ) {
            my $msg = _loc('Pause timed-out at %1 seconds', $timeout ) ;
            $self->logger->error( $msg );
            _fail $msg unless $p{no_fail}; 
            last;
        }
    }
    my $last_status = $self->job_row->get_from_storage->status;
    $self->logger->debug( _loc('Pause finished due to status %1', $last_status) );
    if( $last_status =~ /CANCEL/ ) {
        _fail _loc('Job cancelled while in pause');
    }
    elsif( $last_status =~ /ERROR/ ) {
        _fail _loc('Job error while in pause');
    }
    $self->status( $saved_status );  # resume back to my last real status
    $self->save;
}

sub suspend {
    my ($self, %p ) = @_;
    
    $self->logger->warn( _loc('Suspending Job' ) );
    $self->status( 'SUSPENDED' );
    $self->save;
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
        require BaselinerX::Service::Init;
        BaselinerX::Service::Init->new->root_path( job=>$self );
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
