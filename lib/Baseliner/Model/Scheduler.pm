package Baseliner::Model::Scheduler;
use Moose;

use Try::Tiny;
use Capture::Tiny qw(tee_merged);
use Clarive::mdb;
use Baseliner::Model::SchedulerCalendar;
use Baseliner::Model::Rules;
use Baseliner::Utils qw(_log _loc _fail);

sub search_tasks {
    my $self = shift;
    my (%params) = @_;

    my $start = $params{start} // 0;
    my $limit = $params{limit} // 0;
    my $dir   = $params{dir}   // 'asc';
    my $sort  = $params{sort}  // 'name';
    my $query = $params{query};

    my $where = {};

    $query and $where = mdb->query_build(
        query  => $query,
        fields => {
            name        => 'name',
            parameters  => 'parameters',
            next_exec   => 'next_exec',
            last_exec   => 'last_exec',
            description => 'description',
            frequency   => 'frequency',
            workdays    => 'workdays',
            status      => 'status',
            pid         => 'pid'
        }
    );

    my $rs = mdb->scheduler->find($where)->fields( { last_log => 0 } );
    my $count = $rs->count;

    $rs->skip($start)  if length $start;
    $rs->limit($limit) if length $limit;
    $rs->sort( { $sort => ( lc($dir) eq 'desc' ? -1 : 1 ) } ) if length $sort;

    my @rows;
    my %rule_names = map { $_->{id} => $_ } mdb->rule->find->fields( { rule_tree => 0 } )->all;
    while ( my $r = $rs->next ) {
        $r->{what_name}   = _loc( 'Rule: %1 (%2)', $rule_names{ $r->{id_rule} }{rule_name}, $r->{id_rule} );
        $r->{id}          = '' . delete $r->{_id};
        $r->{id_last_log} = $r->{id};

        push @rows, $r;
    }

    return { rows => \@rows, total => $count };
}

sub save_task {
    my $self = shift;
    my (%p) = @_;

    my $id = $p{taskid};

    my %task_params;

    foreach my $field (qw/id_rule next_exec name description parameters frequency workdays/) {
        $task_params{$field} = $p{$field} if exists $p{$field};
    }

    $task_params{name}        //= 'noname';
    $task_params{description} //= '';
    $task_params{workdays}    //= 0;

    if ( !$id ) {
        _fail('id_rule required')   unless $task_params{id_rule};
        _fail('next_exec required') unless $task_params{next_exec};

        $id = mdb->scheduler->insert( { %task_params, status => 'IDLE', pid => 0, } );
    }
    else {
        mdb->scheduler->update( { _id => mdb->oid($id) }, { '$set' => {%task_params} } );
    }

    return $id;
}

sub delete_task {
    my $self = shift;
    my (%p) = @_;

    my $id = $p{taskid} || _fail 'taskid required';

    mdb->scheduler->remove( { _id => mdb->oid($id) } );
}

sub tasks_list {
    my ( $self, %p ) = @_;

    my $status = $p{status};

    my @tasks_to_return = ();

    my $tasks = mdb->scheduler->find( { status => $status || mdb->in( 'IDLE', 'KILLED', 'RUNNOW' ) } );

    while ( my $task = $tasks->next ) {
        _log "Evaluating task " . $task->{description};

        if ( $self->_needs_execution($task) ) {
            my $task_to_run = {};
            for ( keys %{$task} ) {
                $task_to_run->{$_} = $task->{$_};
            }
            push @tasks_to_return, $task_to_run;
        }
    }

    return @tasks_to_return;
}

sub road_kill {
    my ($self) = @_;

    my $rs = mdb->scheduler->find( { status => mdb->in('RUNNING') } );

    require Proc::Exists;

    while ( my $r = $rs->next ) {
        my $pid = $r->{pid};
        next unless $pid > 0;

        _log _loc("Checking if process $pid exists");

        next if Proc::Exists::pexists($pid);

        _log _loc("Process $pid does not exist");

        $self->_set_task_data( taskid => $r->{_id}, status => 'IDLE' );
        $self->schedule_task( taskid => $r->{_id}, when => $self->next_from_last_schedule( taskid => $r->{_id} ) );
    }
}

sub run_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $pid    = $p{pid};

    my $task = mdb->scheduler->find_one( { _id => mdb->oid($taskid) } );

    _log sprintf q{Running task '%s' (%s)}, ( $task->{name} // 'noname' ), $taskid;

    $self->_set_last_execution( taskid => $taskid, when => $self->_build_calendar->now );
    $self->_set_task_data( taskid => $taskid, status => 'RUNNING', pid => $pid );

    _fail _loc 'Could not find rule or service for scheduler task run `%1` (%2)', ( $task->{name} || 'noname' ), $taskid
      unless $task->{id_rule};

    _log "============================ SCHED RUN START ============================";

    my $output;

    try {
        $output = tee_merged {
            $self->_run_rule($task);
        };
    }
    catch {
        my $e = shift;

        $output = $e;
    };

    _log "============================ SCHED RUN END   ============================";

    # 4MB max last log
    mdb->scheduler->update( { _id => mdb->oid( $task->{_id} ) },
        { '$set' => { last_log => substr( ( $task->{last_log} // '' ) . "\n" . $output, -( 1024 * 1024 * 4 ) ) } } );

    if ( !$task->{frequency} || $task->{frequency} eq 'ONCE' ) {
        mdb->scheduler->update( { _id => mdb->oid( $task->{_id} ) }, { '$set' => { next_exec => undef } } );
    }
    elsif ( $task->{status} ne 'RUNNOW' ) {
        $self->schedule_task( taskid => $taskid, when => $self->next_from_last_schedule( taskid => $taskid ) );
    }

    $self->_set_task_data( taskid => $taskid, status => 'IDLE', pid => 0 );

    return $self;
}

sub schedule_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when   = $p{when};

    if ( $when eq 'now' ) {
        mdb->scheduler->update( { _id => mdb->oid($taskid) }, { '$set' => { status => 'RUNNOW' } } );

        _log "Task will run now";
    }
    else {
        mdb->scheduler->update( { _id => mdb->oid($taskid) }, { '$set' => { next_exec => "$when" } } );

        _log "New next exec is " . $when;
    }
}

sub task_log {
    my ($self, %p) = @_;

    my $taskid = $p{taskid};

    my $doc = mdb->scheduler->find_one( { _id => mdb->oid($taskid) } );
    return unless $doc;

    return $doc->{last_log} // '';
}

sub next_from_last_schedule {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $task = mdb->scheduler->find_one( { _id => mdb->oid($taskid) } );

    return $self->_build_calendar->calculate_next_exec(
        $task->{next_exec},
        frequency => $task->{frequency},
        workdays  => $task->{workdays}
    );
}

sub toggle_activation {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $status = $p{status};
    my $new_status;

    if ( $status =~ /IDLE|KILLED/ ) {
        $self->_set_task_data( taskid => $taskid, status => 'INACTIVE' );
        $new_status = 'inactive';
    }
    else {
        $new_status = 'active';
        $self->_set_task_data( taskid => $taskid, status => 'IDLE' );
    }
    return $new_status;
}

sub kill_schedule {
    my ( $self, %p ) = @_;

    require Proc::Exists;

    my $taskid = $p{taskid};
    my $task = mdb->scheduler->find_one( { _id => mdb->oid($taskid) } );

    my $pid = $task->{pid};
    _log "Killing PID $pid";

    if ( Proc::Exists::pexists($pid) ) {
        kill 9, $pid;
        $self->schedule_task( taskid => $taskid, when => $self->next_from_last_schedule( taskid => $taskid ) );
    }

    $self->_set_task_data( taskid => $taskid, status => 'KILLED' );
}

sub _set_last_execution {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when   = $p{when};

    mdb->scheduler->update( { _id => mdb->oid($taskid) }, { '$set' => { last_exec => "$when" } } );
}

sub _set_task_data {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $status = $p{status};
    my $pid    = $p{pid};

    my $up;
    $up->{status} = $status if $status;
    $up->{pid}    = $pid    if $pid;

    mdb->scheduler->update( { _id => mdb->oid($taskid) }, { '$set' => $up } ) if $up;
}

sub _run_rule {
    my $self = shift;
    my ($task) = @_;

    my $stash = $task->{parameters} || {};

    return Baseliner::Model::Rules->run_single_rule(
        id_rule => $task->{id_rule},
        logging => 1,
        stash   => $stash,

        # hide "Error Running Rule...Error DSL" even as _error
        simple_error => 2,
    );
}

sub _needs_execution {
    my ( $self, $task ) = @_;

    my $exec_now = 0;

    if ( $task->{status} eq 'RUNNOW' ) {
        $exec_now = 1;
    }
    else {
        $exec_now = $self->_build_calendar->has_time_passed( $task->{next_exec} );
    }

    return $exec_now;
}

sub _build_calendar {
    my $self = shift;

    return Baseliner::Model::SchedulerCalendar->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
