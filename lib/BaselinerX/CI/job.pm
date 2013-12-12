package BaselinerX::CI::job;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _now);
use Baseliner::Sugar qw(event_new);
use Try::Tiny;
use v5.10;
with 'Baseliner::Role::CI::Internal';

has id_stash           => qw(is rw isa Any);
has jobid              => qw(is rw isa Any);   # mdb->seq('job')
has bl                 => qw(is rw isa Any);
has rollback           => qw(is rw isa BoolCheckbox default 0);
has job_key            => qw(is rw isa Any), default => sub { Util->_md5() };
has job_type           => qw(is rw isa Any default promote);  # promote, demote, static
has current_service    => qw(is rw isa Any default Core);
has root_dir           => qw(is rw isa Any);
has schedtime          => qw(is rw isa TS coerce 1), default => sub { ''.mdb->now };
has starttime          => qw(is rw isa TS coerce 1), default => sub { ''.mdb->now };
has maxstarttime       => qw(is rw isa TS coerce 1), default => sub { ''.( Class::Date->new($_[0]->starttime) + '1D' ) };
has endtime            => qw(is rw isa Any);
has comments           => qw(is rw isa Any);
has logfile            => qw(is rw isa Any lazy 1), default => sub { my $self=shift; ''.Util->_file($ENV{BASELINER_LOGHOME}, $self->name . '.log') };
has step               => qw(is rw isa Str default CHECK);
has exec               => qw(is rw isa Num default 1);
has status             => qw(is rw isa Any default IN-EDIT);
has status_trans       => qw(is rw isa Any);  # translation of status so that it shows in searches
has step_status        => ( is=>'rw', isa=>'HashRef[Str]', default=>sub{{}} );  # saves statuses at step change
has contents           => qw(is rw isa Any);
has approval           => qw(is rw isa Any);
has username           => qw(is rw isa Any);
has milestones         => qw(is rw isa HashRef default), sub { +{} };
has service_levels     => qw(is rw isa HashRef default), sub { +{} };
has job_dir            => qw(is rw isa Any lazy 1), default => sub { 
    my ($self) = @_;
    my $job_home = $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir();
    File::Spec->catdir( $job_home, $self->name ); 
};  
has backup_dir         => qw(is rw isa Any lazy 1), default => sub { 
    my ($self) = @_;
    return ''.Util->_file( $self->job_dir, '_backups' );
};
has id_rule      => qw(is rw isa Any ), default=>sub {
    my $self = shift;
    my $type = $self->job_type || 'promote';
    my $row = DB->BaliRule->search({ rule_when=>$type }, { order_by=>{-desc=>'id'} })->first;
    if( $row ) {
        return $row->id;    
    } else {
        _fail _loc 'Could not find a default %1 job chain rule', $type;
    }
};

has_cis 'releases';
has_cis 'changesets';
has_cis 'projects';
has_cis 'natures';

sub rel_type {
    { 
        releases   => [ from_mid => 'job_release' ] ,
        changesets => [ from_mid => 'job_changeset' ] ,
        projects   => [ from_mid => 'job_project' ] ,
        natures    => [ from_mid => 'job_nature' ] ,
    };
}
sub icon { '/static/images/icons/job.png' }

before new_ci => sub {
    my ($self, $master_row, $data ) = @_;
    $self->_create( %$self ) if ref $self eq __PACKAGE__;  # don't do this in job_run
};

after delete => sub {
    my ($self, $mid)=@_;
    $mid //= $self->mid;
    mdb->job_log->remove({ mid=>''.$mid }, { multiple=>1 });
    mdb->grid->remove({ mid=>''.$mid });
};

# report status in debug
# translate the status so that we can search in the monitor
around status => sub {
    my $orig = shift;
    my $self = shift;
    my $status = shift;
    my $old_status = $self->{status} // '';
    $self->prev_status( $old_status );
    my $step = $self->step;
    if( defined $status && $self->{status} ne $status ) {
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


###### methods 
#

# get and set the job stash in mdb, this does not merge! (it's a full replace)
sub job_stash {
    my ($self, $new_stash)=@_;
    if( $new_stash ) {
        # set
        _fail "Invalid stash type ".ref($new_stash) unless ref $new_stash eq 'HASH';
        delete $new_stash->{job}; # never serialize job
        delete $new_stash->{$_} for grep /^_state_/, keys %$new_stash;  # no _state_ vars, usually have CODE in them
        my $serial_stash = Util->_stash_dump($new_stash);  # better serialization for stash
        mdb->grid->remove({ parent_mid=>''.$self->mid }, { multiple=>1 });
        my $id = mdb->asset_new( $serial_stash, parent_collection=>'job', parent_mid=>''.$self->mid  );
        $self->id_stash( "$id" );  
        return $new_stash;
    } else {
        # get
        my $stash_file = mdb->grid->get( mdb->oid( $self->id_stash ) ) if $self->id_stash;  # MongoDB::GridFS::File
        $stash_file = mdb->grid->find_one({ parent_mid=>''.$self->mid }) if !$stash_file;  # second attempt, in case id_stash not saved to job CI
        return {} if !$stash_file;
        my $job_stash_str = $stash_file->slurp;
        my $job_stash = try { 
            length $job_stash_str ? Util->_stash_load($job_stash_str) : +{};
        } catch { 
            my $err = shift;
            _log _loc "Error loading job stash: %1", $err;
            +{};
        };
        return $job_stash;
    }
}

# assigns keys to stash, but does not save
sub stash {  # not just an alias
    my ($self, %hash)=@_;
    for my $key ( keys %hash ) {
         $self->job_stash->{$key} = $hash{$key};
    }
    return $self->job_stash;
}


sub _create {
    my ($self, %p )=@_;
    my $bl = $p{bl} || '*';

    my $job_mid = $self->mid;
    my $changesets = $p{changesets};
    my $config = Baseliner->model('ConfigStore')->get( 'config.job' );
    
    my $status = $p{status} || 'IN-EDIT';

    #$now->set_time_zone('CET');
    my $now = mdb->now;
    my $end = $now + ( $config->{expiry_time}{normal} // '1D' );

    $p{starttime}    ||= "$now";
    $p{maxstarttime} ||= "$end";

    ## allow the creation of jobs executed outside Baseliner, with older dates
    my ($starttime, $maxstarttime ) = ( $now, $end );
    ($starttime, $maxstarttime ) = $p{starttime} < $now
        ? ( $now , $end )
        : ($p{starttime} , $p{maxstarttime} );

    my $type = $p{job_type} || $p{type} || $config->{type};
    
    my $row_data = {
            name         => 'temp' . $$,
            mid          => $job_mid,
            starttime    => "$starttime",
            schedtime    => "$starttime",
            maxstarttime => "$maxstarttime",
            status       => $status,
            step         => $p{step} || 'PRE',
            type         => $type,
            id_rule      => $p{id_rule},
            username     => $p{username} || $config->{username} || 'internal',
            comments     => $p{description},
            ns           => '/', # not used, deprecated
            bl           => $bl,
    };
    $row_data->{job_key} = $p{job_key} if length $p{job_key},
    
    # create db row
    my $job_seq = mdb->seq('job');
    $self->jobid( $job_seq );

    # setup name
    my $name = $config->{name}
        || $self->gen_job_name({ mask=>$config->{mask}, type=>$type, bl=>$bl, id=>$job_seq });

    _log "****** Creating JOB id=" . $job_seq . ", name=$name, mask=" . $config->{mask};

    # create a hash stash

    my $log = $self->logger;

    # expand releases into changesets
    my @releases; 
    my @cs_cis = grep { ref } map {
        my $cs = ref $_ ? $_ :  Baseliner::CI->new( $_ );
        if( $cs->is_release ) {
            push @releases, $cs if $cs->is_release;
            grep { $_->is_changeset } $cs->children( isa=>'topic', depth=>-1, no_rels=>1 );
        } elsif( $cs->is_changeset ) {
            $cs
        } else {
            undef; 
        }
    } Util->_array( $changesets );

    # create job contents
    my @cs_list;
    for my $cs ( @cs_cis ) {
        my @active_jobs = $cs->is_in_active_job;
        for my $active_job ( @active_jobs ) {
            _log _dump $active_job;
            if ( $active_job->job_type ne 'static') {
                my $ci_self_status = ci->new('moniker:'.$self->bl);
                my ($self_status_to) = grep {$_->{type} eq 'D'} Util->_array($ci_self_status->parents( isa => 'status'));
                my $ci_other_status = ci->new('moniker:'.$active_job->bl);
                my ($other_status_to) = grep {$_->{type} eq 'D'} Util->_array($ci_other_status->parents( isa => 'status'));
                if ( $self_status_to->{name} ne $other_status_to->{name} ) {
                    _fail _loc("Changeset '%1' is in an active job: %2 (%3) with promote/demote to a different state (%4)", $cs->{name}, $active_job->name, $active_job->mid, $other_status_to->{name} )
                }
            }
            if ( $active_job->bl eq $self->bl ) {
                _fail _loc("Changeset '%1' is in an active job to bl %3: %2", $cs->{name}, $active_job->name, $self->bl )
            }
        }
        push @cs_list, $cs->topic_name;
    }
    _fail _loc('Missing job contents') unless @cs_list > 0;

    # log job items
    if( @cs_list > 10 ) {
        my $msg = _loc('Job contents: %1 total items', scalar(@cs_list) );
        $log->info( $msg, data=>'==>'.join("\n==>", @cs_list) );
    } else {
        $log->info(_loc('Job contents: %1', join("\n", map { "<li><b>$_</b></li>" } @cs_list)) );
    }
    
    # add attributes to job ci
    $self->name( $name );
    $self->status( 'IN-EDIT' );
    $self->changesets( \@cs_cis );
    $self->releases( \@releases ) if @releases;

    # add unique projects from changesets
    my %pp;
    $self->projects([
        grep { defined }
        map { $pp{$_->mid} ? undef : do{ $pp{$_->mid}=1; $_ } }
        map { $_->projects }
        @cs_cis 
    ]);
    $self->ns( 'job/' . $job_seq );
    $self->save;

    # CHECK
    $self->step('CHECK');
    $self->run( same_exec => 1 );
    if( $self->status eq 'ERROR' ) { 
        # errors during CHECK fail back to the user
        _fail _loc "Error during Job Check: %1", $self->last_error;
    } else {
        # INIT
        $self->step('INIT');
        $self->run( same_exec => 1 );
    }
    $self->step('PRE');
    $self->status('READY');
    $self->save;
    return $job_seq;
}

sub gen_job_name {
    my $self = shift;
    my $p = shift;
    my $prefix = $p->{type} eq 'promote' || $p->{type} eq 'static' ? 'N' : 'B';
    return sprintf( $p->{mask}, $prefix, $p->{bl} eq '*' ? 'ALL' : $p->{bl} , $p->{id} );
}

sub is_active {
    my $self = shift;
    if( my $status = $self->load->{status} ) {
        return 1 if $status !~ /REJECTED|CANCELLED|TRAPPED|ERROR|FINISHED|KILLED|EXPIRED/;
    }
    return 0;
}

sub is_running {
    my $self = shift;
    if( my $status = $self->load->{status} ) {
        return 1 if $status =~ /RUNNING|PAUSE/;
    }
    return 0;
}

sub logger { 
    my ($self)=@_;
    return BaselinerX::CI::job_log->new(
        step            => $self->step,
        exec            => $self->exec,
        jobid           => $self->jobid,
        job             => $self,
        current_service => $self->current_service
    );
}

# monitor resties:

sub resume {
    my ($self, $p ) = @_;
    if( $self->status eq 'PAUSED' ) {
        $self->logger->info( Util->_loc('Job resumed by user %1', $p->{username}) );
        $self->status( 'RUNNING' );
        $self->save;
    } else {
        Util->_fail( Util->_loc('Job was not paused') );
    }
    return {};
}

sub run_inproc {
    my ($self, $p) = @_;
    require Capture::Tiny;
    Util->_log('************** Starting JOB IN-PROC %1 ***************', $self->name );
    my ($err,$out);
    try {
        ($out) = Capture::Tiny::tee_merged( sub {
            $self->run( same_exec=>1 );
        });
    } catch {
        $err = shift;
    };
    Util->_log('************** Finished JOB IN-PROC %1 ***************', $self->name );
    try { $self->write_to_logfile( $out ) } catch { _error shift() };
    return { output=>$out, error=>$err };
}

method write_to_logfile( $txt ) {
    open my $ff, '>>', $self->logfile 
        or _fail _log "Could not open logfile %1 for writing", $self->logfile;
    print $ff $txt;
    close $ff;
}

sub find_rollback_deps {
    my ($self)=@_;
    my @prjs = Util->_array( $self->projects );
    my ($prj) = @prjs;
    my @jobs = map { Baseliner::CI->new($_->{mid}) } 
        DB->BaliMaster->search({ collection=>'job', bl=>$self->bl, mid=>{'>'=>$self->mid } }, { select=>'mid' })
        ->hashref->all;
    
    # TODO check if there are later jobs for the same repository
    return ();
}

sub contract {
    my ($self, $p)=@_;
    my @prjs = Util->_array( $self->projects );
    my ($prj) = @prjs;
    _debug $prj;
    _fail _loc 'Missing project for job %1', $self->name unless $prj;
    my $vars = $prj->variables // {};
    my $bl = $self->bl;
    return { 
        username => $self->username, 
        schedtime => $self->schedtime,
        comments => $self->comments,
        projects=>join(' ', map { $_->name } @prjs),
        cs=>join(' ', map { $_->name } Util->_array( $self->changesets ) ),
        bl=>$bl, 
        vars=>{ $bl => { %{ $vars->{'*'} || {} }, %{ $vars->{$bl} || {} } } } 
    };
    #return $vars;
}

sub reset {   # aka restart
    my ($self, $p )=@_;
    my %p = %{ $p || {} };
    my $username = $p{username} or _throw 'Missing username';
    my $realuser = $p{realuser} || $username;
    my $config = Baseliner->model('ConfigStore')->get( 'config.job' );

    _fail _loc('Job %1 is currently running (%2) and cannot be rerun', $self->name, $self->status)
        if $self->is_running;

    my $msg;
    event_new 'event.job.rerun' => { job=>$self } => sub {
        my $now = mdb->now;
        if( $p{run_now} || $self->schedtime < $now ) {
            my $end = $now + ( $config->{expiry_time}{normal} // '1D' );
            $self->schedtime( "$now" );
            $self->starttime( "$now" );
            $self->maxstarttime( "$end" );
        }
        $self->rollback( 0 );
        $self->pid( 0 );
        $self->status( 'READY' );
        $self->final_status( '' );
        $self->step( $p{step} || 'PRE' );
        $self->username( $username );
        my $exec = $self->exec + 1;
        $self->exec( $exec );
        $self->save;
        my $log = $self->logger;
        $msg = _loc("Job restarted by user %1, execution %2, step %3", $realuser, $exec, $self->step );
        $log->info($msg);
    };
    return { msg=>$msg };
}

sub reschedule {
    my ($self, $p )=@_;
    my %p = %{ $p || {} };
    my $username = $p{username} or _throw 'Missing username';
    my $realuser = $p{realuser} || $username;

    _fail _loc('Job %1 is not in status %2 (currently %3)', $self->name, _loc('READY'), _loc($self->status) )
        if $self->status ne 'READY';

    my $msg;
    event_new 'event.job.reschedule' => { job=>$self } => sub {
        my $newtime = Class::Date->new( "$p->{date} $p->{time}" );
        $self->schedtime( "$newtime" );
        $self->save;
        my $log = $self->logger;
        $msg = _loc("Job %1 rescheduled by user %2 to %3", $self->name, $realuser, $newtime );
        $log->info($msg);
    };
    return { msg=>$msg };
}

sub cancel {
    my ($self, $p )=@_;
    _fail _loc('Job %1 is currently running and cannot be deleted') if $self->is_running;
    if ( $self->status =~ /^CANCELLED/ ) {
       $self->delete;
    } else {
       event_new 'event.job.cancel' => { job=>$self } => sub {
           $self->status( 'CANCELLED' );
           $self->save;
       };
    }
}

method can_approve( :$username ) {
    my $config = $self->approval_config;  # this config gets set when the approve task executes in the rule
    my $user = Baseliner->user_ci( $username );
    return 1 if $user->is_root || $user->has_action( 'action.job.approve_all' );
    my %avr = map { $_=>1 } Util->_array( $config->{approvers} );
    return 1 if $avr{ 'user/' . $user->mid };
    my @roles = keys Baseliner->model('Permissions')->user_projects_ids_with_collection( username=>$username, with_role=>1);
    for( @roles ) {
        return 1 if $avr{ 'role/'.$_ };
    }
    return 0;
}

sub approve {
    my ($self, $p)=@_;
    my $comments = $p->{comments};
    if( ! $self->can_approve( username=>$p->{username} ) ) {
        _fail _loc 'User %1 is not authorized to approve job %2', $p->{username}, $self->name;
    }
    event_new 'event.job.approved' => 
        { username => $self->username, name=>$self->name, step=>$self->step, status=>$self->status, bl=>$self->bl, comments=>$comments } => sub {
        $self->logger->info( _loc('*Job Approved by %1*: %2', $p->{username}, $comments), data=>$comments, username=>$p->{username} );
        $self->status( 'READY' );
        $self->final_status( '' );
        $self->save;
    };
    { success=>1 }
}

sub reject {
    my ($self, $p)=@_;
    my $comments = $p->{comments};
    if( ! $self->can_approve( username=>$p->{username} ) ) {
        _fail _loc 'User %1 is not authorized to approve job %2', $p->{username}, $self->name;
    }
    event_new 'event.job.rejected' => 
        { username => $self->username, name=>$self->name, step=>$self->step, status=>$self->status, bl=>$self->bl, comments=>$comments } => sub {
        $self->logger->error( _loc('*Job Rejected by %1*: %2', $p->{username}, $comments), data=>$comments, username=>$p->{username} );
        $self->status( 'REJECTED' );
        $self->final_status( '' );
        $self->last_finish_status( 'REJECTED' );  # saved for POST
        $self->step('POST');
        # $self->goto_next_step();
        $self->save;
    };
    { success=>1 }
}

sub trap_action {
    my ($self, $p)=@_;
    my $comments = $p->{comments} // _('no comment');
    my $action = $p->{action} // '';
    my $job_status = $action eq 'retry' ? 'RETRYING' : $action eq 'skip' ? 'SKIPPING' : 'ERROR';
    $self->logger->warn( _loc('Task response `*%1*` by *%2*: %3', _loc($action), $p->{username}, $comments), data=>$comments, username=>$p->{username} );
    $self->status( $job_status );
    $self->save;
    { success=>1 }
}

sub status_icon {
    my ($self, $status, $rollback) = @_; 
    given( $status || $self->status) {
        when( 'RUNNING' ) { 'gears.gif'; }
        when( 'READY' ) { 'waiting.png'; }
        when( 'APPROVAL' ) { 'user_delete.gif'; }
        when( 'FINISHED' && !( $rollback || $self->rollback) ) { 'log_i.gif' }
        when( 'IN-EDIT' ) { 'log_w.gif'; }
        when( 'WAITING' ) { 'waiting.png'; }
        when( 'PAUSED' ) { 'paused.png'; }
        when( 'CANCELLED' ) { 'close.png'; }
        default { 'log_e.gif' }
    }
}


sub gen_job_key {
    my ($self,$p ) = @_;
    { job_key => $self->job_key };
}


# used by the job dashboard
sub summary2 {
    my ($self)=@_;
    
    my $st = Class::Date->new( $self->starttime );
    my $et = Class::Date->new( $self->endtime );

    return {
        bl             => $self->bl,
        status         => $self->status,
        starttime      => $self->starttime, #$starttime,
        endtime        => $self->endtime, #$endtime,
        execution_time => $et - $st, #$execution_time,
        active_time    => $et - $st, #$active_time,
        services_time  => 0, #$services_time,
        type           => $self->job_type,
        owner          => $self->username,
        last_step      => $self->step,
        rollback       => $self->rollback,
    };
}

sub summary {
    my ($self, %p) = @_;
    my $result = {};
    $p{job_exec} //= $self->exec; 
    
    my @log_all = mdb->job_log->find({ mid => $self->mid, exec =>$p{job_exec} })
        ->fields({ step=>1, service_key=>1, ts=>1 })->all;
    
    my %log_max; 
    for my $log ( @log_all ) {
        my $mm = $log_max{ $log->{step} .';'. $log->{service_key} };
        $mm->{step} //= $log->{step};
        $mm->{service_key} //= $log->{service_key};
        $log_max{ $log->{step} .';'. $log->{service_key} }{starttime} = $log->{ts}  
            if !defined $mm->{starttime} || $mm->{starttime} gt $log->{ts}; 
        $log_max{ $log->{step} .';'. $log->{service_key} }{endtime} = $log->{ts}  
            if !defined $mm->{endtime} || $mm->{endtime} lt $log->{ts}; 
    }
    
    @log_all = sort { Class::Date->new($a->{starttime})->epoch <=> Class::Date->new($b->{starttime})->epoch } values %log_max;

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
    
    # my $execution_time;
    # if ($row->endtime){
    #     $endtime = Class::Date->new( $row->endtime );
    #     $execution_time = $endtime - $starttime;
    # } else {
    #     my $now = Class::Date->now;
    #     $execution_time = $now - $starttime;
    # }

    # Fill services time
    my $st = Class::Date->new( $self->starttime );
    my $et = Class::Date->new( $self->endtime );
    return {
        bl             => $self->bl,
        status         => $self->status,
        starttime      => $self->starttime, #$starttime,
        endtime        => $self->endtime, #$endtime,
        execution_time => $et - $st, #$execution_time,
        #active_time    => $et - $st, #$active_time,
        type           => $self->job_type,
        owner          => $self->username,
        last_step      => $self->step,
        rollback       => $self->rollback,
        
        #starttime => $starttime,
        #execution_time => $execution_time,
        active_time => $active_time,
        #endtime => $endtime,
        services_time => $services_time,
    };
    return $result;
}

sub service_summary {
    my ( $self, %p ) = @_;
    my $summary = $p{summary} // $self->summary;
        
    my $result = {};
    my $ss = {};
    my $log_levels = { warn => 3, error => 4, debug => 2, info => 2 };
    $p{job_exec} //= $self->exec;
    
    my @log = mdb->job_log->find(
        {
            mid    => $self->mid,
            exec   => $p{job_exec}
        },
    )->fields({ step=>1, service_key=>1, lev=>1 })->all;

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
            my $status = $ss->{$step}{$skey} // '';
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
    my @keys = mdb->job_log->find({ mid=>$self->mid, exec => $p{job_exec}, service_key=>{ '$ne'=>undef } })
        ->sort({ id=>1 })->fields({ step=>1, service_key=>1, id=>1 })->all;
    # reset keys for current exec 
    for my $r ( @keys ) {
        $result->{$r->{step}}=[];
    }
    $load_results->( @keys );
    
    return $result;  # {   PRE=>[ {},{} ], RUN=>... }
} 

sub artifacts {
    my ( $self, %p ) = @_;
    $p{job_exec} //= $self->exec;
    my $rs = mdb->job_log->find({
            mid  => $self->mid,
            exec => $p{job_exec},
            lev    => { '$ne' => 'debug' },
            more      => { '$ne' => undef },
            milestone => '1',
        })->sort({ id=>1 });
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
}

method bom( :$username ) {
    return $self;
    return { 
        changesets => $self->changesets,
        projects   => $self->projects,
        #items=>$job->items,
    }; 
}

sub _select_words {
    my ( $self, $text, $cnt ) = @_;
    my @ret = ();
    for ( $text =~ /(\w+)/g ) {
        next if length( $_ ) <= 3;
        push @ret, $_;
        last if @ret >= $cnt;
    }
    return join '_', @ret;
} 

sub annotate {
    my ($self,$p)=@_;
    my $level = $p->{level} ||= 'info';
    _fail 'Missing text' unless $p->{text};

    my $text = $p->{text};
    $text = substr($text, 0, 2048 );
    #$text = '<b>' . $c->username . '</b>: ' . $p->{text};
    $level = 'comment' if !$level || $level eq 'info';
    my $log = $self->logger; 
    $log->exec( "$p->{job_exec}" ) if $p->{job_exec} > 0;
    $log->$level( $text, data=>$p->{data}, username=>$p->{username} );
}

# 
#===================  JOB EXECUTION METHODS ===================
#

has pid                => qw(is rw isa Num lazy 1), default=>sub{ return $$ };
has host               => qw(is rw isa Str lazy 1), default=>sub{ return Util->my_hostname() };
has owner              => qw(is rw isa Str lazy 1), default=>sub{ return $ENV{USER} || $ENV{USERNAME} };
has last_error         => qw(is rw isa Maybe[Str] default '');
has approval_config    => ( is=>'rw', isa=>'Any' ), default => sub{ +{} };  # approval config form goes here
has prev_status        => ( is=>'rw', isa=>'Any' );  # saves previous status
has last_finish_status => ( is=>'rw', isa=>'Any' );  # saves ending statuses, so that POST can keep them - done by Daemon
has final_status       => ( is=>'rw', isa=>'Any' );  # so that services can request a final status like PAUSE
has final_step         => ( is=>'rw', isa=>'Any' );  # so that we set the next step at the very end
has pause_timeout      => qw(is rw isa Num default), 3600 * 24;  # 1 day max
has pause_frequency    => qw(is rw isa Num default 5);  # 5 seconds
has has_errors         => ( is=>'rw', isa=>'Num', default=>0 ); 
has has_warnings       => ( is=>'rw', isa=>'Num', default=>0 ); 

with 'Baseliner::Role::JobRunner';   # TODO legacy

service 'job.run' => {
    name    => 'Job CI Runner',
    handler => sub{
        my ($self,$c,$config)=@_;
        $self->run();
    },
};

sub run {
    my ($self, %p) = @_;

    local $Baseliner::CI::_no_record = 1; # prevent _ci in CIs
    
    $self->final_status( $self->last_finish_status ) if $self->step eq 'POST'; # post should not change status at end
    $self->status('RUNNING');
    $self->write_pid;
    if( !$p{same_exec} && ( ($self->endtime && $self->step) || $self->rollback ) ) {
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
        $self->has_errors( $self->has_errors + 1 ) if $lev eq 'error';
        $self->has_warnings( $self->has_warnings + 1 ) if $lev eq 'warn';
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
        $job_error = 1;
        $self->finish( 'ERROR' );
        $self->logger->error( _loc( 'Job failure: %1', $err ) );
        $self->last_error( $err );
        $self->job_stash( $stash );
    };

    my $rollback_now = 0;
    my $nr = $stash->{needs_rollback} // {};
    my @needing_rollback = map { $_ } grep { $nr->{$_} } keys %$nr;
    if( $job_error ) {
        if( @needing_rollback && !$self->rollback ) {
            # rinse and repeat
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
    goto ROLLBACK if $rollback_now;

    #$self->logger->debug( "Job natures....", $self->natures );
    #$self->logger->debug( "Job children", $self->children );
    
    # last line on log
    if( $self->status eq 'ERROR' ) {
        $self->logger->error( _loc( 'Job step %1 finished with error', $self->step, $self->status ) );
        $self->step eq 'POST' ? $self->final_step('END') : $self->final_step( 'POST' );
    } elsif( $self->status eq 'FINISHED' ) { 
        $self->logger->info( _loc( 'Job step %1 finished ok', $self->step ) );
        $self->goto_next_step( $self->final_status );  # goto_next_step only works for jobs 'FINISHED'
        $self->final_step('END') if $self->step eq 'POST'; # from POST we goto END always
    } else {
        $self->logger->info( _loc( 'Job step %1 finished with status %2', $self->step, $self->status ) );
        $self->goto_next_step( $self->final_status ); 
        $self->final_step('END') if $self->step eq 'POST'; # from POST we goto END always
    }
    unlink $self->pid_file;
    $self->step( $self->final_step );
    $self->save;
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
our %next_status = (
    CHECK => 'IN-EDIT',
    INIT  => 'READY',
    PRE   => 'READY',
    RUN   => 'READY',
    POST  => 'FINISHED'
);

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
         _loc('Going from step %1 to next step %2 (status %3)', $current_step, $next_step, $self->status )
    );
    $self->final_step( $next_step );
    
    return ( $next_step, $next_status );
}

sub finish {
    my ($self, $status ) = @_;
    $status ||= 'FINISHED';

    _debug( "JOB FINISHED=$status, rollback=". $self->rollback );
    $self->status( $status );
    $self->step_status->{ $self->step } = $status;
    $self->last_finish_status( $status );  # saved for POST
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
    while( $self->load->{status} eq 'PAUSED' ) {
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
    my $last_status = $self->load->{status};
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
