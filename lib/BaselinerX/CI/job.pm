package BaselinerX::CI::job;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
use Baseliner::Sugar qw(event_new);
use Try::Tiny;
use v5.10;
with 'Baseliner::Role::CI::Internal';

has id_job       => qw(is rw isa Any); 
has bl                 => qw(is rw isa Any);
has pid                => qw(is rw isa Any);
has host               => qw(is rw isa Any);
has rollback           => qw(is rw isa BoolCheckbox default 0);
has job_key            => qw(is rw isa Any), default => sub { Util->_md5() };
has job_type           => qw(is rw isa Any default promote);  # promote, demote, static
has current_service    => qw(is rw isa Any default job_run);
has root_dir           => qw(is rw isa Any);
has schedtime          => qw(is rw isa Any);
has starttime          => qw(is rw isa Any);
has endtime            => qw(is rw isa Any);
has ts                 => qw(is rw isa Any);
has maxstarttime       => qw(is rw isa Any);
has comments           => qw(is rw isa Any);
has logfile            => qw(is rw isa Any);
has step               => qw(is rw isa Str default CHECK);
has exec               => qw(is rw isa Num default 1);
has status             => qw(is rw isa Any default IN-EDIT);
has contents           => qw(is rw isa Any);
has approval           => qw(is rw isa Any);
has username           => qw(is rw isa Any);
has runner             => qw(is rw isa Any);
has milestones         => qw(is rw isa HashRef default), sub { +{} };
has service_levels     => qw(is rw isa HashRef default), sub { +{} };
has job_dir            => qw(is rw isa Any lazy 1), default => sub { 
    my ($self) = @_;
    my $job_home = $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir();
    File::Spec->catdir( $job_home, $self->name ); 
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

# adds extra data to _ci during loading
around load_post_data => sub {
    my ($orig, $class, $mid, $data ) = @_;
    
    return {} unless $mid;
    
    my $row = DB->BaliJob->search({ mid=>$mid }, {})->first;
    if ( $row ) {

        my $job_row = +{ $row->get_columns };
        
        $job_row->{job_type} = $job_row->{type};
        $job_row->{id_job} = $job_row->{id};
        delete $job_row->{mid};
        delete $job_row->{ns};

        return $job_row;
    } else {
        return {};
    }
};

around update_ci => sub {
    my $orig = shift;
    my $self = shift;
    my ($master_row, $data ) = @_;
    my $mid = $self->mid;
    
    if( my $row = DB->BaliJob->search({ mid=>$mid })->first ) {
        $row->update({
            pid         => $self->pid,
            exec        => $self->exec,
            rollback    => $self->rollback,
            step        => $self->step,
            status      => $self->status,
            endtime     => $self->endtime,
        });
    }
    $self->$orig( @_ ); 
};


###### methods 
#

# get and set the job stash, this does not merge!
sub job_stash {
    my ($self, $new_stash)=@_;
    my $row = DB->BaliJob->search({ mid=>$self->mid })->first;
    if( $new_stash ) {
        # set
        _fail "Invalid stash type ".ref($new_stash) unless ref $new_stash eq 'HASH';
        delete $new_stash->{job}; # never serialize job
        delete $new_stash->{$_} for grep /^_state_/, keys %$new_stash;  # no _state_ vars, usually have CODE in them
        #$row->stash( Util->_dump($new_stash) );
        $row->stash( Util->_stash_dump($new_stash) );
        return $new_stash;
    } else {
        # get
        my $job_stash_str = $row->stash;
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

sub jobid { shift->id_job }

sub job_row {
    my ($self, $id_job )=@_;
    DB->BaliJob->find( $id_job // $self->id_job );
}

sub job_update {
    my $self = shift;
    DB->BaliJob->search({ id=>$self->id_job })->update( @_ );
}

sub job_data {
    my ($self)=@_;
    +{ $self->job_row->get_columns };
}

sub create_runner {
    my ($self, %p) =@_; 
    local $Baseliner::CI::_no_record = 1; # prevent _ci in CIs
    my $job_run = BaselinerX::CI::job_run->new( %$self, parent_job=>$self->mid, %p );
    return $job_run;
}

sub _create {
    my ($self, %p )=@_;
    my $bl = $p{bl} || '*';

    my $job_mid = $self->mid;
    my $changesets = $p{changesets};
    my $config = Baseliner->model('ConfigStore')->get( 'config.job' );
    
    my $status = $p{status} || 'IN-EDIT';

    # TODO set urgent somewhere
    my $jobType = $p{urgent} 
        ? $config->{emer_window}
        : $config->{normal_window};

    #$now->set_time_zone('CET');
    my $now = DateTime->now(time_zone=>Util->_tz);
    my $end = $now->clone->add( hours => $config->{expiry_time}->{$jobType} || 24 );

    $p{starttime}||=$now;
    $p{maxstarttime}||=$end;

    ## allow the creation of jobs executed outside Baseliner, with older dates
    my ($starttime, $maxstarttime ) = ( $now, $end );
    ($starttime, $maxstarttime ) = $p{starttime} < $now
        ? ( $now , $end )
        : ($p{starttime} , $p{maxstarttime} );

    $starttime =  $starttime->strftime('%Y-%m-%d %T');
    $maxstarttime =  $maxstarttime->strftime('%Y-%m-%d %T');

    my $type = $p{job_type} || $p{type} || $config->{type};
    
    my $row_data = {
            name         => 'temp' . $$,
            mid          => $job_mid,
            starttime    => $starttime,
            schedtime    => $starttime,
            maxstarttime => $maxstarttime,
            status       => $status,
            step         => $p{step} || 'PRE',
            type         => $type,
            runner       => $p{runner} || $config->{runner},
            id_rule      => $p{id_rule},
            username     => $p{username} || $config->{username} || 'internal',
            comments     => $p{description},
            job_key      => $p{job_key},
            ns           => '/', # not used, deprecated
            bl           => $bl,
    };
    
    # CHECK
    my $ret = Baseliner->model('Rules')->run_single_rule( id_rule=>$p{id_rule}, stash=>{ %p, %$row_data, job_step=>'CHECK' });
    
    # create db row
    my $job_row = Baseliner->model('Baseliner::BaliJob')->create($row_data);

    # setup name
    my $name = $config->{name}
        || $self->gen_job_name({ mask=>$config->{mask}, type=>$type, bl=>$bl, id=>$job_row->id });

    _log "****** Creating JOB id=" . $job_row->id . ", name=$name, mask=" . $config->{mask};

    $job_row->name( $name );
    $job_row->ns( 'job/' . $job_row->id );  # my own id here, which transpires to the CI
    $job_row->update;

    # create a hash stash

    my $log = new BaselinerX::Job::Log({ jobid=>$job_row->id });

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
            if ( $active_job->job_type ne 'static') {
                _fail _loc("Job element '%1' is in an active job: %2", $cs->name, $active_job->name )
            } elsif ( $active_job->bl eq $self->bl ) {
                _fail _loc("Job element '%1' is in an active job to bl %3: %2", $cs->name, $active_job->name, $self->bl )
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
    $self->id_job( $job_row->id );
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
    $self->ns( 'job/' . $job_row->id );
    
    $job_row->status( 'READY' );
    $job_row->update;
    
    # INIT
    $self->create_runner( step=>'INIT' )->run;

    return $job_row;
}

sub gen_job_name {
    my $self = shift;
    my $p = shift;
    my $prefix = $p->{type} eq 'promote' || $p->{type} eq 'static' ? 'N' : 'B';
    return sprintf( $p->{mask}, $prefix, $p->{bl} eq '*' ? 'ALL' : $p->{bl} , $p->{id} );
}

sub is_active {
    my $self = shift;
    if( my $row = DB->BaliJob->find( $self->id_job ) ) {
        my $status = $row->status;
        return 1 if $status !~ /REJECTED|CANCELLED|ERROR|FINISHED|KILLED|EXPIRED/;
    }
    return 0;
}

sub is_running {
    my $self = shift;
    if( my $row = DB->BaliJob->find( $self->id_job ) ) {
        my $status = $row->status;
        return 1 if $status =~ /RUNNING|PAUSE/;
    }
    return 0;
}

sub logger { 
    my ($self)=@_;
    return BaselinerX::CI::job_log->new(
        step            => $self->step,
        exec            => $self->exec,
        jobid           => $self->id_job,
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
    my $runner = $self->create_runner();
    require Capture::Tiny;
    Util->_log('************** Starting JOB IN-PROC %1 ***************', $self->name );
    my ($err,$out);
    try {
        ($out) = Capture::Tiny::tee_merged( sub {
            $runner->run();
        });
    } catch {
        $err = shift;
    };
    Util->_log('************** Finished JOB IN-PROC %1 ***************', $self->name );
    return { output=>$out, error=>$err };
}

sub reset {
    my ($self, $p )=@_;
    my %p = %{ $p || {} };
    my $username = $p{username} or _throw 'Missing username';
    my $realuser = $p{realuser} || $username;

    _fail _loc('Job %1 is currently running (%2) and cannot be rerun', $self->name, $self->status)
        if $self->is_running;

    my $msg;
    event_new 'event.job.rerun' => { job=>$self } => sub {
        if( $p{run_now} ) {
            my $now = DateTime->now;
            $now->set_time_zone( Util->_tz );
            my $end = $now->clone->add( hours => 1 );
            my $ora_now =  $now->strftime('%Y-%m-%d %T');
            my $ora_end =  $end->strftime('%Y-%m-%d %T');
            $self->schedtime( $ora_now );
            $self->starttime( $ora_now );
            $self->maxstarttime( $ora_end );
        }
        $self->rollback( 0 );
        $self->status( 'READY' );
        $self->step( $p{step} || 'PRE' );
        $self->username( $username );
        my $exec = $self->exec + 1;
        $self->exec( $exec );
        $self->save;
        my $log = new BaselinerX::Job::Log({ jobid=>$self->id_job });
        $msg = _loc("Job restarted by user %1, execution %2, step %3", $realuser, $exec, $self->step );
        $log->info($msg);
    };
    return { msg=>$msg };
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

sub approve {
    my ($self, $p)=@_;
    my $comments = $p->{comments};
    event_new 'event.job.approved' => 
        { username => $self->username, name=>$self->name, step=>$self->step, status=>$self->status, bl=>$self->bl, comments=>$comments } => sub {
        $self->logger->info( _loc('*Job Approved by %1*: %2', $p->{username}, $comments), data=>$comments, username=>$p->{username} );
        $self->status( 'READY' );
        $self->save;
    };
    1;
}

sub reject {
    my ($self, $p)=@_;
    my $comments = $p->{comments};
    event_new 'event.job.rejected' => 
        { username => $self->username, name=>$self->name, step=>$self->step, status=>$self->status, bl=>$self->bl, comments=>$comments } => sub {
        $self->logger->error( _loc('*Job Rejected by %1*: %2', $p->{username}, $comments), data=>$comments, username=>$p->{username} );
        $self->status( 'REJECTED' );
        $self->save;
    };
    1;
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

1;

__END__

  active: '1'
  bl: IT
  changesets:
  - '6904'
  ci_class: BaselinerX::CI::job
  ci_form: /ci/job.js
  ci_icon: /static/images/icons/job.png
  collection: job
  comments: ~
  endtime: ~
  exec: '1'
  host: localhost
  id: '608'
  id_rule: '125'
  id_stash: ~
  job_key: 30723acbdc9ee6da62dec00ea4a09c75
  mid: '6918'
  moniker: ~
  name: N.IT-00000608
  now: '0'
  ns: /
  owner: ~
  pid: ~
  request_status: ~
  rollback: '0'
  runner: service.job.runner.rule
  schedtime: 2013-09-06 19:29:34
  starttime: 2013-09-06 19:29:34
  maxstarttime: 2013-09-07 19:29:34
  status: READY
  step: PRE
  ts: 2013-09-06 19:29:34
  type: promote
  username: root
  versionid: '1'

