use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;

use lib 't/lib';

use TestEnv;
use TestUtils qw(mock_time);
BEGIN { TestEnv->setup }

use_ok 'Baseliner::Model::Scheduler';

subtest 'save_task: creates new task' => sub {
    _setup();

    my $model = _build_model();

    my $id = $model->save_task(
        id_rule    => 123,
        next_exec  => '2015-01-01 00:00:00',
        frequency  => '1D',
        workdays   => 0,
        parameters => {}
    );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        pid         => 0,
        status      => 'IDLE',
        name        => 'noname',
        description => '',
        next_exec   => '2015-01-01 00:00:00',
        parameters  => {},
        frequency   => '1D',
        workdays    => 0,
        id_rule     => '123'
      };
};

subtest 'save_task: updates existing task' => sub {
    _setup();

    my $model = _build_model();

    my $id = $model->save_task(id_rule => 123, next_exec => '2015-01-01 00:00:00');

    $model->save_task(taskid => $id, id_rule => 321, next_exec => '2016-01-01 00:00:00');

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        pid         => 0,
        status      => 'IDLE',
        name        => 'noname',
        description => '',
        next_exec   => '2016-01-01 00:00:00',
        workdays    => 0,
        id_rule     => '321'
      };
};

subtest 'save_task: updates existing task minimal' => sub {
    _setup();

    my $model = _build_model();

    my $id = $model->save_task(id_rule => 123, next_exec => '2015-01-01 00:00:00');

    $model->save_task(taskid => $id, name => 'foo');

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        pid         => 0,
        status      => 'IDLE',
        name        => 'foo',
        description => '',
        next_exec   => '2015-01-01 00:00:00',
        workdays    => 0,
        id_rule     => '123'
      };
};

subtest 'delete_task: deletes task' => sub {
    _setup();

    my $model = _build_model();

    my $id = $model->save_task(id_rule => 123, next_exec => '2015-01-01 00:00:00');

    $model->delete_task(taskid => $id);

    ok !defined mdb->scheduler->find_one( { _id => mdb->oid($id) } );
};

subtest 'tasks_list: returns empty list when no tasks' => sub {
    _setup();

    my $model = _build_model();

    my @tasks = $model->tasks_list;

    is_deeply \@tasks, [];
};

subtest 'tasks_list: returns empty list when no tasks to execute' => sub {
    _setup();

    mdb->scheduler->insert( { description => 'Task', status => 'IDLE', next_exec => '2100-12-12' } );

    my $model = _build_model();

    my @tasks = $model->tasks_list;

    is_deeply \@tasks, [];
};

subtest 'tasks_list: returns only tasks that need execution' => sub {
    _setup();

    mdb->scheduler->insert( { description => 'Task1', status => 'IDLE', next_exec => '2000-12-12' } );
    mdb->scheduler->insert( { description => 'Task2', status => 'RUNNOW' } );
    mdb->scheduler->insert( { description => 'Task3', status => 'IDLE', next_exec => '2100-12-12' } );
    mdb->scheduler->insert( { description => 'Task4', status => 'IDLE', next_exec => '2100-12-12' } );

    my $model = _build_model();

    my @tasks = $model->tasks_list;

    is scalar @tasks, 2;
    is $tasks[0]->{description}, 'Task1';
    is $tasks[1]->{description}, 'Task2';
};

subtest 'tasks_list: filters by status' => sub {
    _setup();

    mdb->scheduler->insert( { description => 'Task1', status => 'IDLE',   next_exec => '2000-12-12' } );
    mdb->scheduler->insert( { description => 'Task2', status => 'RUNNOW', next_exec => '2000-12-12' } );

    my $model = _build_model();

    my @tasks = $model->tasks_list(status => 'IDLE');;

    is scalar @tasks, 1;
    is $tasks[0]->{description}, 'Task1';
};

subtest 'tasks_list: returns tasks list' => sub {
    _setup();

    mdb->scheduler->insert( { description => 'Task', status => 'IDLE', next_exec => '2000-12-12' } );

    my $model = _build_model();

    my @tasks = $model->tasks_list;

    is scalar @tasks, 1;
};

subtest 'road_kill: cleans up and reschedules non running pids' => sub {
    _setup();

    my $pid = _generate_non_existent_pid();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'RUNNING',
            pid         => $pid,
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D'
        }
    );

    mock_time(
        '2015-01-01T00:00:00' => sub {
            my $model = _build_model();
            $model->road_kill;
        }
    );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        description => 'Task',
        status      => 'IDLE',
        pid         => $pid,
        next_exec   => '2015-01-02 00:00:00',
        frequency   => '1D'
      };
};

subtest 'schedule_task: schedules for now' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D'
        }
    );

    my $model = _build_model();

    $model->schedule_task( taskid => $id, when => 'now' );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        description => 'Task',
        status      => 'RUNNOW',
        next_exec   => '2015-01-01 00:00:00',
        frequency   => '1D'
      };
};

subtest 'schedule_task: schedules' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D'
        }
    );

    my $model = _build_model();

    $model->schedule_task( taskid => $id, when => '2015-01-01 12:20:00' );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        description => 'Task',
        status      => 'IDLE',
        next_exec   => '2015-01-01 12:20:00',
        frequency   => '1D'
      };
};

subtest 'toggle_activation: toggles IDLE status' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D'
        }
    );

    my $model = _build_model();

    $model->toggle_activation( taskid => $id, status => 'IDLE' );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    is $sched->{status}, 'INACTIVE';
};

subtest 'toggle_activation: toggles RUNNING status' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'RUNNING',
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D'
        }
    );

    my $model = _build_model();

    $model->toggle_activation( taskid => $id, status => 'RUNNING' );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    is $sched->{status}, 'IDLE';
};

subtest 'run_task: runs task as rule' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D',
            id_rule     => 123,
        }
    );

    mock_time(
        '2015-01-01T00:00:00' => sub {
            my $model = _build_model();
            $model->run_task( taskid => $id, pid => '123' );
        }
    );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        pid         => '123',
        description => 'Task',
        status      => 'IDLE',
        next_exec   => '2015-01-02 00:00:00',
        frequency   => '1D',
        id_rule     => 123,
        last_exec   => '2015-01-01 00:00:00',
        last_log    => "\nRULE OUTPUT"
      };
};

subtest 'run_task: do not reschedule if RUNNOW' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'RUNNOW',
            next_exec   => '2015-01-01 00:00:00',
            frequency   => '1D',
            id_rule     => 123,
        }
    );

    mock_time(
        '2015-01-01T00:00:00' => sub {
            my $model = _build_model();
            $model->run_task( taskid => $id, pid => '123' );
        }
    );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        pid         => '123',
        description => 'Task',
        status      => 'IDLE',
        next_exec   => '2015-01-01 00:00:00',
        frequency   => '1D',
        id_rule     => 123,
        last_exec   => '2015-01-01 00:00:00',
        last_log    => "\nRULE OUTPUT"
      };
};

subtest 'run_task: do not reschedule if no frequency' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            id_rule     => 123,
        }
    );

    mock_time(
        '2015-01-01T00:00:00' => sub {
            my $model = _build_model();
            $model->run_task( taskid => $id, pid => '123' );
        }
    );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    cmp_deeply $sched,
      {
        _id         => ignore(),
        pid         => '123',
        description => 'Task',
        status      => 'IDLE',
        next_exec   => undef,
        id_rule     => 123,
        last_exec   => '2015-01-01 00:00:00',
        last_log    => "\nRULE OUTPUT"
      };
};

subtest 'run_task: capture rule errors' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            id_rule     => 123,
        }
    );

    my $model = _build_model( _run_rule => sub { die 'error' } );
    $model->run_task( taskid => $id, pid => '123' );

    my $sched = mdb->scheduler->find_one( { _id => mdb->oid($id) } );

    is $sched->{status},     'IDLE';
    like $sched->{last_log}, qr/error at/;
};

subtest 'task_log: returns task log' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            id_rule     => 123,
            last_log    => 'foo bar baz'
        }
    );

    my $model = _build_model();
    my $log = $model->task_log( taskid => $id );

    is $log, 'foo bar baz';
};

subtest 'task_log: returns undef when task not found' => sub {
    _setup();

    my $model = _build_model();
    my $log = $model->task_log( taskid => 123 );

    ok !defined $log;
};

subtest 'task_log: returns empty when log is empty' => sub {
    _setup();

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            id_rule     => 123,
        }
    );

    my $model = _build_model();
    my $log = $model->task_log( taskid => $id );

    is $log, '';
};

subtest 'search_tasks: returns correct empty response' => sub {
    _setup();

    my $model = _build_model();
    my $result = $model->search_tasks();

    is_deeply $result, {rows => [], total => 0};
};

subtest 'search_tasks: returns tasks' => sub {
    _setup();

    my $id_rule = _create_rule(id => '123');

    my $id = mdb->scheduler->insert(
        {
            description => 'Task',
            status      => 'IDLE',
            next_exec   => '2015-01-01 00:00:00',
            id_rule     => '123'
        }
    );

    my $model = _build_model();
    my $result = $model->search_tasks();

    cmp_deeply $result,
      {
        rows => [
            {
                'what_name'   => "Rule: test (123)",
                'status'      => 'IDLE',
                'id_last_log' => "$id",
                'id'          => "$id",
                'next_exec'   => '2015-01-01 00:00:00',
                'description' => 'Task',
                'id_rule'     => 123
            }
        ],
        total => 1
      };
};

done_testing();

sub _setup {
    mdb->rule->drop;
    mdb->scheduler->drop;
}

sub _create_rule {
    mdb->rule->insert(
        {
            rule_name => 'test',
            @_
        }
    );
}

sub _generate_non_existent_pid {
    my $pid;

    do {
        $pid = int rand( 2**16 );
    } while ( kill 0, $pid );

    return $pid;
}

sub _build_model {
    my (%params) = @_;

    my $model = Baseliner::Model::Scheduler->new;

    $model = Test::MonkeyMock->new($model);
    $model->mock( _run_rule => $params{_run_rule} || sub { print 'RULE OUTPUT' } );

    return $model;
}
