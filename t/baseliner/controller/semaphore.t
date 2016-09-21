use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';
use TestSetup;

use Baseliner::Sem;

use_ok 'Baseliner::Controller::Semaphore';

subtest 'sems: returns empty data when no semaphores' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    $controller->sems($c);

    is_deeply $c->stash, { json => { data => [], totalCount => 0 } };
};

subtest 'sems: returns semaphores' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    mdb->sem->insert( { key => '123' } );

    $controller->sems($c);

    cmp_deeply $c->stash,
      {
        json => {
            data => [
                {
                    id      => ignore(),
                    waiting => 0,
                    busy    => 0,
                    key     => '123'
                }
            ],
            totalCount => 1
        }
      };
};

subtest 'sems: does not return internal semaphores' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    mdb->sem->insert( { key => '123', internal => '1' } );

    $controller->sems($c);

    cmp_deeply $c->stash,
      {
        json => {
            data       => [],
            totalCount => 0
        }
      };
};

subtest 'queue: returns empty queue when no semaphores' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    $controller->queue($c);

    is_deeply $c->stash, { json => { data => [], totalCount => 0 } };
};

subtest 'queue: returns semaphores queue' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    mdb->sem->insert(
        {
            key   => '123',
            queue => [
                {
                    key    => '123',
                    _id    => '123',
                    who    => 'Class.pm',
                    status => 'waiting',
                    ts     => '1234567890',
                }
            ]
        }
    );

    $controller->queue($c);

    cmp_deeply $c->stash, {
        json => {
            data => [
                {
                    'key'       => '123',
                    'id'        => '123',
                    'who'       => 'Class.pm',
                    'status'    => 'waiting',
                    'wait_time' => '',
                    'run_time'  => '',
                    'ts'        => '1234567890'
                }

            ],
            totalCount => 1
        }
    };
};

subtest 'queue: returns semaphores queue' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    mdb->sem->insert(
        {
            key   => '123',
            queue => [
                {
                    key    => '123',
                    _id    => '123',
                    who    => 'Class.pm',
                    status => 'waiting',
                    ts     => '1234567890',
                }
            ]
        }
    );

    $controller->queue($c);

    cmp_deeply $c->stash, {
        json => {
            data => [
                {
                    'key'       => '123',
                    'id'        => '123',
                    'who'       => 'Class.pm',
                    'status'    => 'waiting',
                    'wait_time' => '',
                    'run_time'  => '',
                    'ts'        => '1234567890'
                }

            ],
            totalCount => 1
        }
    };
};

done_testing;

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    Baseliner::Controller::Semaphore->new( application => '' );
}

sub _setup {
    mdb->sem->drop;
    mdb->index_all('sem');
}
