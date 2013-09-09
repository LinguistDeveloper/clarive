package BaselinerX::CI::job_run;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _now);
use Try::Tiny;

extends 'BaselinerX::CI::job';

has exec         => qw(is rw isa Num default 1);
has logfile      => qw(is rw isa Any);
has pid          => qw(is rw isa Num lazy 1), default=>sub{ return $$ };
has host         => qw(is rw isa Str lazy 1), default=>sub{ return lc Sys::Hostname::hostname() };
has owner        => qw(is rw isa Str lazy 1), default=>sub{ return $ENV{USER} || $ENV{USERNAME} };
has same_exec    => qw(is rw isa Bool default 0); 
has step_status  => ( is=>'rw', isa=>'HashRef[Str]', default=>sub{{}} );  # saves statuses at step change
has prev_status  => ( is=>'rw', isa=>'Any' );  # saves previous status
has final_status => ( is=>'rw', isa=>'Any' );  # so that services can request a final status like PAUSE
has current_service => qw(is rw isa Any default job_run);
#  has failing         => ( is=>'rw', isa=>'Bool', default=>0 );  # XXX desirable?

has_cis 'parent_job'; 
sub rel_type {
    { 
        parent_job => [ to_mid => 'job_run' ] ,
    };
}


with 'Baseliner::Role::JobRunner';

around update_ci => sub {
    my $orig = shift;
    my $self = shift;
    my ($master_row, $data ) = @_;
    my $mid = $self->mid;
    
    if( my $row = DB->BaliJob->search({ mid=>$mid })->first ) {
        $row->update({
            exec        => $self->exec,
            step        => $self->step,
            status      => $self->status,
            endtime     => $self->endtime,
        });
        # serialize stash, only if instanciated
        if( ref $self ) {
            my $job_obj = delete $self->job_stash->{job};
            $row->stash( Util->_dump($self->job_stash) );
            $self->job_stash({ %{ $self->job_stash }, job=>$job_obj });
        }
    }
    $self->$orig( @_ ); 
};

# change logger service
around current_service => sub {
    my $orig = shift;
    my $self = shift;
    my $service = shift // '';
    if( $service && $self->{current_service} ne $service ) {
        $self->logger( current_service=>$service );
        $self->logger->max_service_level( 2 );  # XXX ???
    }
};

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

service 'job.run' => {
    name    => 'Job CI Runner',
    handler => \&run,
};

sub run {
    my ($self, %p) = @_;

    $self->status('RUNNING');
    $self->exec( $self->exec + 1) if !$self->same_exec && $self->endtime;  # endtime=job has run before, a way to detect first time
    _log "Setting exec to " . $self->exec;
    $self->save;
    
    # trap all die signals
    local $SIG{__DIE__} = \&_throw;

    local $Baseliner::logger = sub {
        my ($lev, $cl,$fi,$li, @msgs ) = @_;
        
        #die "calling logger: $lev";
        $lev = 'debug' if $lev eq 'info';
        my $text = $msgs[0];
        if( ref $text ) {    # _log { ... }
            $self->logger->common_log( [$lev,2], _loc('Data dump'), @msgs ); 
        } else {
            $self->logger->common_log( [$lev,2], @msgs ); 
        }
        return 0;
    };

    _log "=========| Starting JOB " . $self->id_job;

    _debug( _loc('Rule Runner, STEP=%1, PID=%2, RULE_ID', $self->step, $self->pid ) );

    # prepare stash for rules
    #my $prev_stash = delete $job->{job_stash};
    my $stash = { 
            %{ $self->job_stash }, 
            job         => $self,
            bl          => $self->bl, 
            job_step    => $self->step,
            job_dir     => $self->job_dir,
            changesets  => $self->changesets,
    };
    $self->job_stash( $stash );  # make sure they are the same, there are services that get the stash from here
    
    try {
        my $ret = Baseliner->model('Rules')->run_single_rule( 
            id_rule => $self->id_rule, 
            logging => 1,
            stash   => $stash,
        );
        #$self->logger->debug( 'Stash after rules', $stash );
        $self->job_stash( $stash );
        $self->finish( $self->final_status || 'FINISHED' );
    } catch {
        my $err = shift;   
        #$self->logger->debug( 'Stash after rules', $stash );
        $self->finish( 'ERROR' );
        $self->logger->error( _loc( 'Job failure: %1', $err ) );
        $self->job_stash( $stash );
    };
    $self->save;
    
    # last line on log
    if( $self->status eq 'ERROR' ) {
        $self->logger->error( _loc( 'Job step %1 finished with error', $self->step, $self->status ) );
    } elsif( $self->status eq 'FINISHED' ) { 
        $self->logger->info( _loc( 'Job step %1 finished ok', $self->step ) );
    } else {
        $self->logger->info( _loc( 'Job step %1 finished with status %2', $self->step, $self->status ) );
    }
    $self->status;
}

our %next_step   = ( CHECK=>'INIT', INIT=>'PRE', PRE => 'RUN', RUN => 'POST', POST => 'END' );
our %next_status  = ( CHECK=>'IN-EDIT', INIT=>'READY', PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

=head2 goto_step

Updates the step in the row following the next_status rules

=cut
sub goto_step {
    my ($self, $current_step ) = @_;
    
    # STATUS
    my $next_status = $next_status{ $current_step };
    $self->status( $next_status ) if defined $next_status;
    
    # STEP
    my $next_step = $next_step{ $current_step };
    $self->logger->debug(
         _loc('Going from step %1 to next step %2', $current_step, $next_step )
    );
    $self->save;
}

sub goto_next_step {
    my $self = shift;
    $self->goto_step( $self->step );
}

sub finish {
    my ($self, $status ) = @_;
    $self->status( $status || 'FINISHED' );
    $self->endtime( _now ); 
}

sub logger { 
    my ($self)=@_;
    return BaselinerX::CI::job_log->new(
        step            => $self->step,
        exec            => $self->exec,
        jobid           => $self->id_job,
        current_service => $self->current_service
    );
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
    $self->status('PAUSE');
    $self->save;
    
    $p{reason} ||= _loc('unspecified');
    my $timeout = $p{timeout} || $self->config->{pause_timeout} || 3600 * 24;  # 1 day default
    my $freq    = $p{frequency} || $self->config->{pause_frequency} || 5;
    $self->logger->debug( _loc('Pause timeout (%1 seconds)', $timeout ) );
    my $t = 0;
    # select continuously
    while( $self->job_row->get_from_storage->status eq 'PAUSED' ) {
        $self->logger->warn( _loc('Paused. Reason: %1', $p{reason} ) );
        sleep $freq;
        $t += $freq;
        if( defined $timeout && $t > $timeout ) {
            $self->logger->warn( _loc('Pause timed-out at %1 seconds', $timeout ) );
            last;
        }
    }
    $self->status( $self->job_row->get_from_storage->status );  # resume back to my last real status
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
