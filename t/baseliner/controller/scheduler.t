use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
use TestUtils ':catalyst';

BEGIN {
    TestEnv->setup;
}

use Baseliner::Core::Registry;
use Baseliner::Controller::Scheduler;
use Baseliner::Model::Scheduler;

subtest 'save_schedule: saves task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( save_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id_rule => 1, date => '2015-01-01', time => '00:00:00' } } );

    $controller->save_schedule($c);

    cmp_deeply { $scheduler->mocked_call_args('save_task') },
      {
        'name'        => 'noname',
        'taskid'      => undef,
        'description' => undef,
        'frequency'   => undef,
        'workdays'    => 0,
        'next_exec'   => '2015-01-01 00:00:00',
        'id_rule'     => 1
      };
};

subtest 'save_schedule: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( save_task => sub { } );

    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id_rule => 1, date => '2015-01-01', time => '00:00:00' } } );

    $controller->save_schedule($c);

    cmp_deeply $c->stash, { json => { msg => 'ok', success => \1 } };
};

subtest 'save_schedule: returns correct validation response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( save_task => sub { die 'error' } );

    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => {} } );

    $controller->save_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Validation failed',
            success => \0,
            errors  => ignore()
        }
      };
};

subtest 'save_schedule: returns correct error response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( save_task => sub { die 'error' } );

    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id_rule => 1, date => '2015-01-01', time => '00:00:00' } } );

    $controller->save_schedule($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/Error saving configuration schedule: error/), success => \0 } };
};

subtest 'run_schedule: schedules task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( schedule_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->run_schedule($c);

    cmp_deeply { $scheduler->mocked_call_args('schedule_task') },
      {
        'taskid' => '123',
        'when'   => 'now'
      };
};

subtest 'run_schedule: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( schedule_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->run_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'ok',
            success => \1,
        }
      };
};

subtest 'run_schedule: returns correct validation error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( schedule_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => {} } );

    $controller->run_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Validation failed',
            success => \0,
            errors  => ignore()
        }
      };
};

subtest 'run_schedule: returns correct error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( schedule_task => sub { die 'error' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->run_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => re(qr/Error running schedule: error/),
            success => \0,
        }
      };
};

subtest 'delete_schedule: schedules task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( delete_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->delete_schedule($c);

    cmp_deeply { $scheduler->mocked_call_args('delete_task') },
      { 'taskid' => '123' };
};

subtest 'delete_schedule: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( delete_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->delete_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'ok',
            success => \1,
        }
      };
};

subtest 'delete_schedule: returns correct validation error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( delete_task => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => {} } );

    $controller->delete_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Validation failed',
            success => \0,
            errors  => ignore()
        }
      };
};

subtest 'delete_schedule: returns correct error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( delete_task => sub { die 'error' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->delete_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => re(qr/Error deleting schedule: error/),
            success => \0,
        }
      };
};

subtest 'toggle_activation: schedules task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( toggle_activation => sub { 'ACTIVE' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123', status => 'IDLE' } } );

    $controller->toggle_activation($c);

    cmp_deeply { $scheduler->mocked_call_args('toggle_activation') },
      {
        'taskid' => '123',
        'status' => 'IDLE'
      };
};

subtest 'toggle_activation: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( toggle_activation => sub { 'ACTIVE' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123', status => 'IDLE' } } );

    $controller->toggle_activation($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Task is now ACTIVE',
            success => \1,
        }
      };
};

subtest 'toggle_activation: returns correct validation error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( toggle_activation => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => {} } );

    $controller->toggle_activation($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Validation failed',
            success => \0,
            errors  => ignore()
        }
      };
};

subtest 'toggle_activation: returns correct error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( toggle_activation => sub { die 'error' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123', status => 'IDLE' } } );

    $controller->toggle_activation($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => re(qr/Error changing activation: error/),
            success => \0,
        }
      };
};

subtest 'kill_schedule: schedules task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( kill_schedule => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->kill_schedule($c);

    cmp_deeply { $scheduler->mocked_call_args('kill_schedule') },
      { 'taskid' => '123', };
};

subtest 'kill_schedule: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( kill_schedule => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->kill_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Task killed',
            success => \1,
        }
      };
};

subtest 'kill_schedule: returns correct validation error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( kill_schedule => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => {} } );

    $controller->kill_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Validation failed',
            success => \0,
            errors  => ignore()
        }
      };
};

subtest 'kill_schedule: returns correct error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( kill_schedule => sub { die 'error' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->kill_schedule($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => re(qr/Error killing task: error/),
            success => \0,
        }
      };
};

subtest 'last_log: schedules task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( task_log => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->last_log($c);

    cmp_deeply { $scheduler->mocked_call_args('task_log') },
      { 'taskid' => '123', };
};

subtest 'last_log: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( task_log => sub { 'foo bar baz' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->last_log($c);

    is $c->res->content_type, 'text/plain';
    is $c->res->body,         'foo bar baz';
};

subtest 'last_log: returns correct empty response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( task_log => sub { '' } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->last_log($c);

    is $c->res->content_type, 'text/plain';
    is $c->res->body,         'No log';
};

subtest 'last_log: returns correct not found response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( task_log => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->last_log($c);

    is $c->res->status,       404;
    is $c->res->content_type, 'text/plain';
    is $c->res->body,         'Error: task log not found';
};

subtest 'last_log: returns correct validation error' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( task_log => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => {} } );

    $controller->last_log($c);

    cmp_deeply $c->stash,
      {
        json => {
            msg     => 'Validation failed',
            success => \0,
            errors  => ignore()
        }
      };
};

subtest 'json: searches task with correct default params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( search_tasks => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->json($c);

    cmp_deeply { $scheduler->mocked_call_args('search_tasks') },
      {
        start => 0,
        limit => 0,
        dir   => 'asc',
        sort  => 'name',
        query => ''
      };
};

subtest 'json: searches task with correct params' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( search_tasks => sub { } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req =>
          { params => { id => '123', start => 5, limit => 10, dir => 'desc', sort => 'frequency', query => 'foo' } } );

    $controller->json($c);

    cmp_deeply { $scheduler->mocked_call_args('search_tasks') },
      {
        start => 5,
        limit => 10,
        dir   => 'desc',
        sort  => 'frequency',
        query => 'foo'
      };
};

subtest 'json: returns correct successful response' => sub {
    _setup();

    my $scheduler = _mock_scheduler();
    $scheduler->mock( search_tasks => sub { { rows => [ { foo => 'bar' } ], total => 1 } } );
    my $controller = _build_controller( scheduler => $scheduler );

    my $c = _build_c( req => { params => { id => '123' } } );

    $controller->json($c);

    cmp_deeply $c->stash,
      {
        json => {
            data       => [ { foo => 'bar' } ],
            totalCount => 1
        }
      };
};

done_testing;

sub _mock_user_ci {
    my $user_ci = Test::MonkeyMock->new;
    $user_ci->mock( from_user_date => sub { $_[1] } );
    return $user_ci;
}

sub _build_c {
    mock_catalyst_c( user_ci => _mock_user_ci(), @_ );
}

sub _setup {
    TestUtils->setup_registry();
}

sub _mock_scheduler {
    my (%params) = @_;

    my $scheduler = Baseliner::Model::Scheduler->new;
    $scheduler = Test::MonkeyMock->new($scheduler);

    return $scheduler;
}

sub _build_controller {
    my (%params) = @_;

    my $scheduler = $params{scheduler} || _mock_scheduler();

    my $controller = Baseliner::Controller::Scheduler->new( application => '' );
    $controller = Test::MonkeyMock->new($controller);

    $controller->mock( _build_scheduler => sub { $scheduler } );

    return $controller;
}
