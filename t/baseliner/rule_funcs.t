use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use POSIX ":sys_wait_h";
use JSON ();
use Baseliner::Role::CI;
use Baseliner::Model::Topic;
use Baseliner::RuleFuncs;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Fieldlet;
use BaselinerX::Fieldlets;
use Baseliner::Queue;

subtest 'merge_data' => sub {
    _setup();

    my $dest = {};

    my $res = merge_data $dest, { foo => 'bar' }, { bar => 'baz' };

    is_deeply $res, { foo => 'bar', bar => 'baz' };
};

subtest 'merge_data: parses variables' => sub {
    _setup();

    my $dest = {};

    my $res = merge_data $dest, { 'foo' => '${bar}', bar => 'baz' };

    is_deeply $res, { foo => 'baz', bar => 'baz' };
};

subtest 'merge_into_stash' => sub {
    _setup();

    my $stash = {};

    merge_into_stash $stash, { foo => 'bar' };

    is_deeply $stash, { foo => 'bar' };
};

subtest 'current_task' => sub {
    _setup();

    my $run_me;
    my $stash = { var => 'surprise' };

    current_task(
        $stash,
        id_rule   => 1,
        rule_name => 'some rule',
        name      => 'some task with ${var}',
        code      => sub { $run_me++ }
    );

    is $stash->{current_rule_id},   1;
    is $stash->{current_rule_name}, 'some rule';
    is $stash->{current_task_name}, 'some task with surprise';
};

subtest 'current_task: starts task' => sub {
    _setup();

    my $job = Test::MonkeyMock->new;
    $job->mock( start_task => sub { } );
    $job->mock( jobid      => sub { 1 } );

    my $stash = { job => $job };

    current_task(
        $stash,
        id_rule   => 1,
        rule_name => 'some rule',
        name      => 'some task with ${var}'
    );

    ok $job->mocked_called('start_task');
};

subtest 'current_task: cancel job in steps check or init' => sub {
    _setup();

    mdb->rule_status->drop;

    my $job = Test::MonkeyMock->new;
    $job->mock( jobid => sub { 1 } );

    my $stash = { job => $job };

    mdb->rule_status->insert(
        {
            id       => 1,
            type     => 'job',
            status   => "CANCEL_REQUESTED",
            username => 'test'
        }
    );
    like exception {
        current_task( $stash, id_rule => 9, rule_name => 'some rule', name => 'some task with ${var}' );
    }, qr/Job cancelled by user test/;
};

subtest 'launch' => sub {
    _setup();

    my $config = {};
    my $stash  = {};

    Baseliner::Core::Registry->add_class( undef, 'service' => 'TestService' );
    Baseliner::Core::Registry->add( 'main', 'service.scripting.local', { foo => 'bar' } );

    my $rv = launch( 'service.scripting.local', 'some task', $stash, $config, '' );

    is $rv, 'from TestService';
};

subtest 'changeset_projects from data' => sub {
    _setup();

    my $status_id = ci->status->new( type => 'I' )->save;

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_type => "form",
            rule_seq  => $id_rule,
            rule_tree => JSON::encode_json(
                [
                    {
                        "attributes" => {
                            "data" => {
                                "bd_field"     => "id_category_status",
                                "name_field"   => "Status",
                                "fieldletType" => "fieldlet.system.status_new",
                                "id_field"     => "status_new",
                            },
                            "key" => "fieldlet.system.status_new",
                        }
                    },
                    {
                        "attributes" => {
                            "data" => {
                                "bd_field"     => "project",
                                "fieldletType" => "fieldlet.system.projects",
                                "id_field"     => "project",
                            },
                            "key" => "fieldlet.system.projects",
                        }
                    }
                ]
            )
        }
    );

    my $cat_id = mdb->seq('id');
    mdb->category->insert(
        { id => "$cat_id", name => 'Category', statuses => [$status_id], default_form => "$id_rule" } );

    my $project     = TestUtils->create_ci_project();
    my $project_mid = $project->mid;

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $params = {
        'project'    => $project_mid,
        'category'   => "$cat_id",
        'status_new' => "$status_id",
        'action'     => 'add',
        'username'   => $user->name,
    };

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update($params);

    my $stash = { changesets => [$topic_mid] };

    my @projects = changeset_projects($stash);

    is scalar @projects, 1;
    is $projects[0]->{name}, 'Project';
};

subtest 'error_trap: does nothing when ok' => sub {
    _setup();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback => sub { } );
    my $stash = { job => $job };

    my $rv = error_trap(
        stash               => $stash,
        trap_timeout        => 1,
        trap_timeout_action => 'action',
        trap_max_retry      => '',
        trap_rollback       => 'do_rollback',
        mode                => 'ignore',
        code                => sub { 'ok' }
    );

    ok !$job->mocked_called('rollback');
};

subtest 'error_trap: on error returns nothing when no job provided' => sub {
    _setup();

    my $stash = {};

    my $rv = error_trap(
        stash               => $stash,
        trap_timeout        => 1,
        trap_timeout_action => 'action',
        trap_max_retry      => '',
        trap_rollback       => 'do_rollback',
        mode                => 'ignore',
        code                => sub { die 'error' }
    );

    ok !defined $rv;
};

subtest 'error_trap: on error fail if rollback and no rollback flag' => sub {
    _setup();

    my $job_logger = _mock_job_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback => sub { 1 } );
    $job->mock( logger   => sub { $job_logger } );

    my $stash = { job => $job };

    like exception {
        error_trap(
            stash               => $stash,
            trap_timeout        => 1,
            trap_timeout_action => 'action',
            trap_max_retry      => '',
            trap_rollback       => 0,
            mode                => 'ignore',
            code                => sub { die 'error' }
          )

    }, qr/error/;
};

subtest 'error_trap: returns undef on ignore' => sub {
    _setup();

    my $job_logger = _mock_job_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback => sub { 1 } );
    $job->mock( logger   => sub { $job_logger } );

    my $stash = { job => $job };

    ok !defined error_trap(
        stash               => $stash,
        trap_timeout        => 1,
        trap_timeout_action => 'action',
        trap_max_retry      => '',
        trap_rollback       => 1,
        mode                => 'ignore',
        code                => sub { die 'error' }
    );
};

subtest 'error_trap: creates event' => sub {
    _setup();

    my $job = _mock_job( status => 'SKIPPING' );
    my $stash = { job => $job };

    error_trap(
        stash               => $stash,
        trap_timeout        => 1,
        trap_timeout_action => 'action',
        trap_max_retry      => '',
        trap_rollback       => 1,
        mode                => '',
        code                => sub { die 'error' }
    );

    my $event = mdb->event->find_one( { event_key => 'event.job.trapped' } );

    is $event->{event_key}, 'event.job.trapped';
};

#subtest 'error_trap: traps action if timeout expired' => sub {
#    _setup();
#
#    Baseliner::Core::Registry->add_class( 'main', 'event', 'BaselinerX::Type::Event' );
#    Baseliner::Core::Registry->add( 'main', 'event.rule.trap', {} );
#
#    my $job_logger = _mock_job_logger();
#
#    my $trapped = 0;
#
#    my $job = Test::MonkeyMock->new;
#    $job->mock( rollback    => sub { 0 } );
#    $job->mock( logger      => sub { $job_logger } );
#    $job->mock( update      => sub { } );
#    $job->mock( load        => sub { { status => 'TRAPPED' } } );
#    $job->mock( trap_action => sub { $trapped++ } );
#
#    my $stash = { job => $job };
#
#    error_trap( $stash, 1, 'action', '', 1, '', sub { die 'error' } );
#
#    ok $trapped;
#};

subtest 'error_trap: sets last trap action when status is SKIPPING' => sub {
    _setup();

    my $job = _mock_job( status => 'SKIPPING' );
    my $stash = { job => $job };

    error_trap(
        stash               => $stash,
        trap_timeout        => 1,
        trap_timeout_action => 'action',
        trap_max_retry      => '',
        trap_rollback       => 1,
        mode                => '',
        code                => sub { die 'error' }
    );

    is $stash->{_last_trap_action}, 'skip';
};

subtest 'error_trap: sets last trap action when status is RETRYING' => sub {
    _setup();

    my $job = _mock_job( status => 'RETRYING' );
    my $stash = { job => $job };

    like exception {
        error_trap(
            stash               => $stash,
            trap_timeout        => 1,
            trap_timeout_action => 'action',
            trap_max_retry      => 1,
            trap_rollback       => 1,
            mode                => '',
            code                => sub { die 'error' }
          )
    }, qr/Max retries reached/;

    is $stash->{_last_trap_action}, 'retry';
};

subtest 'parralel_run: runs task in background' => sub {
    _setup();

    my $stash = {};

    my $pid = parallel_run( 'task', 'fork', $stash, sub { 'return from fork' } );

    waitpid $pid, 0;

    my $data = queue->pop( msg => "rule:child:results:$pid" );

    is_deeply $data, { ret => 'return from fork', err => undef, stash => {} };
};

subtest 'parralel_run: catches errors' => sub {
    _setup();

    my $stash = {};

    my $pid = parallel_run( 'task', 'fork', $stash, sub { die 'error from fork' } );

    waitpid $pid, 0;

    my $data = queue->pop( msg => "rule:child:results:$pid" );

    cmp_deeply $data, { ret => undef, err => re(qr/error from fork/), stash => {} };
};

subtest 'wait_for_children: waits for forked children' => sub {
    _setup();

    my $stash = {};

    my $pid = parallel_run( 'task', 'fork', $stash, sub { } );

    wait_for_children($stash);

    is kill( 0, $pid ), 0;
};

subtest 'wait_for_children: gathers values from forks' => sub {
    _setup();

    my $stash = {};

    parallel_run( 'task', 'fork', $stash, sub { $stash->{fork_result} = '123' } );

    my $result = wait_for_children( $stash, config => { parallel_stash_keys => ['fork_result'] } );

    is_deeply $result, [ { ret => '123', err => undef, fork_result => 123 } ];
};

subtest 'wait_for_children: gathers values from forks with errors in silent errors mode' => sub {
    _setup();

    my $stash = {};

    my @behaviours = ( sub { $stash->{fork_result} = 'ok' }, sub { die 'error' } );

    foreach my $behavior (@behaviours) {
        parallel_run( 'task', 'fork', $stash, $behavior );
    }

    my $result = wait_for_children( $stash, config => { errors => 'silent', parallel_stash_keys => ['fork_result'] } );

    my ($ok)    = grep { defined $_->{ret} } @$result;
    my ($error) = grep { !defined $_->{ret} } @$result;

    cmp_deeply $ok, { ret => 'ok', err => undef, fork_result => 'ok' };
    cmp_deeply $error, { ret => undef, err => re(qr/error/), fork_result => undef };
};

subtest 'wait_for_children: throws when one of the forks fails in fail errors mode' => sub {
    _setup();

    my $stash = {};

    my @behaviours = ( sub { $stash->{fork_result} = 'ok' }, sub { die 'error' } );

    foreach my $behavior (@behaviours) {
        parallel_run( 'task', 'fork', $stash, $behavior );
    }

    like
      exception { wait_for_children( $stash, config => { errors => 'fail' } ) },
      qr/^Error detected in children, pids failed: \d+\. Ok: \d+\nErrors:\n\d+: error at/;
};

subtest 'eval_code: evals code' => sub {
    _setup();

    my $stash = {};

    my $ret = eval_code( 'js', '1 + 1', $stash );

    is $ret->{ret}, 2;
};

subtest 'condition_check: returns result of boolean comparison' => sub {
    ok condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'is_true' } ] );
    ok !condition_check( { foo => 0 }, all => [ { operand_a => 'foo', operator => 'is_true' } ] );

    ok condition_check( { foo => 0 }, all => [ { operand_a => 'foo', operator => 'is_false' } ] );
    ok !condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'is_false' } ] );
};

subtest 'condition_check: returns result of empty comparison' => sub {
    ok condition_check( {}, all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok condition_check( { foo => undef }, all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok condition_check( { foo => '' },    all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok condition_check( { foo => [] },    all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok condition_check( { foo => {} },    all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok condition_check( { foo => [ {} ] }, all => [ { operand_a => 'foo', operator => 'is_empty' } ] );

    ok !condition_check( { foo => 0 },   all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok !condition_check( { foo => [0] }, all => [ { operand_a => 'foo', operator => 'is_empty' } ] );
    ok !condition_check( { foo => [ { 0 => 0 } ] }, all => [ { operand_a => 'foo', operator => 'is_empty' } ] );

    ok !condition_check( {}, all => [ { operand_a => 'foo', operator => 'not_empty' } ] );
};

subtest 'condition_check: returns comparison result' => sub {
    ok condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'eq', operand_b => 'a' } ] );
    ok !condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'eq', operand_b => 'b' } ] );

    ok !condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'not_eq', operand_b => 'a' } ] );
    ok condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'not_eq', operand_b => 'b' } ] );
};

subtest 'condition_check: returns comparison result ignore case' => sub {
    ok condition_check( { foo => 'A' },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => 'a', options => { ignore_case => 1 } } ] );
    ok !condition_check( { foo => 'A' },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => 'b', options => { ignore_case => 1 } } ] );

    ok !condition_check( { foo => 'A' },
        all => [ { operand_a => 'foo', operator => 'not_eq', operand_b => 'a', options => { ignore_case => 1 } } ] );
    ok condition_check( { foo => 'A' },
        all => [ { operand_a => 'foo', operator => 'not_eq', operand_b => 'b', options => { ignore_case => 1 } } ] );
};

subtest 'condition_check: returns comparison result numeric' => sub {
    ok condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => '01', options => { numeric => 1 } } ] );
    ok !condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => '02', options => { numeric => 1 } } ] );

    ok !condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'not_eq', operand_b => '01', options => { numeric => 1 } } ] );
    ok condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'not_eq', operand_b => '02', options => { numeric => 1 } } ] );
};

subtest 'condition_check: returns greater comparison result' => sub {
    ok condition_check( { foo => 'b' }, all => [ { operand_a => 'foo', operator => 'gt', operand_b => 'a' } ] );

    ok !condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'gt', operand_b => 'b' } ] );

    ok condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'ge', operand_b => 'a' } ] );

    ok !condition_check( { foo => 'a' }, all => [ { operand_a => 'foo', operator => 'ge', operand_b => 'b' } ] );
};

subtest 'condition_check: returns greater comparison result numeric' => sub {
    ok condition_check( { foo => 10 },
        all => [ { operand_a => 'foo', operator => 'gt', operand_b => '2', options => { numeric => 1 } } ] );

    ok !condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'gt', operand_b => '2', options => { numeric => 1 } } ] );

    ok condition_check( { foo => 2 },
        all => [ { operand_a => 'foo', operator => 'ge', operand_b => '2', options => { numeric => 1 } } ] );

    ok !condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'ge', operand_b => '2', options => { numeric => 1 } } ] );
};

subtest 'condition_check: returns less comparison result' => sub {
    ok condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'lt', operand_b => '2' } ] );

    ok !condition_check( { foo => 2 }, all => [ { operand_a => 'foo', operator => 'lt', operand_b => '1' } ] );

    ok condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'le', operand_b => '1' } ] );

    ok !condition_check( { foo => 2 }, all => [ { operand_a => 'foo', operator => 'le', operand_b => '1' } ] );
};

subtest 'condition_check: returns has comparison result' => sub {
    ok condition_check( { foo => [ 1, 2, 3 ] },
        all => [ { operand_a => 'foo', operator => 'has', operand_b => '1' } ] );
    ok !condition_check( { foo => [ 1, 2, 3 ] },
        all => [ { operand_a => 'foo', operator => 'has', operand_b => '10' } ] );

    ok condition_check( { foo => { 1 => 2, 2 => 3 } },
        all => [ { operand_a => 'foo', operator => 'has', operand_b => '1' } ] );
    ok !condition_check( { foo => { 1 => 2, 2 => 3 } },
        all => [ { operand_a => 'foo', operator => 'has', operand_b => '10' } ] );

    ok !condition_check( { foo => [ 1, 2, 3 ] },
        all => [ { operand_a => 'foo', operator => 'not_has', operand_b => '1' } ] );
    ok condition_check( { foo => [ 1, 2, 3 ] },
        all => [ { operand_a => 'foo', operator => 'not_has', operand_b => '10' } ] );

    ok !condition_check( { foo => { 1 => 2, 2 => 3 } },
        all => [ { operand_a => 'foo', operator => 'not_has', operand_b => '1' } ] );
    ok condition_check( { foo => { 1 => 2, 2 => 3 } },
        all => [ { operand_a => 'foo', operator => 'not_has', operand_b => '10' } ] );
};

subtest 'condition_check: returns in comparison result' => sub {
    ok condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'in', operand_b => [ 1, 2, 3 ] } ] );
    ok !condition_check( { foo => 10 }, all => [ { operand_a => 'foo', operator => 'in', operand_b => [ 1, 2, 3 ] } ] );

    ok condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'in', operand_b => { 1 => 1, 2 => 2 } } ] );
    ok !condition_check( { foo => 10 },
        all => [ { operand_a => 'foo', operator => 'in', operand_b => { 1 => 1, 2 => 2 } } ] );

    ok !condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'not_in', operand_b => [ 1, 2, 3 ] } ] );
    ok condition_check( { foo => 10 },
        all => [ { operand_a => 'foo', operator => 'not_in', operand_b => [ 1, 2, 3 ] } ] );

    ok !condition_check( { foo => 1 },
        all => [ { operand_a => 'foo', operator => 'not_in', operand_b => { 1 => 1, 2 => 2 } } ] );
    ok condition_check( { foo => 10 },
        all => [ { operand_a => 'foo', operator => 'not_in', operand_b => { 1 => 1, 2 => 2 } } ] );
};

subtest 'condition_check: returns like comparison result' => sub {
    ok condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'like', operand_b => '\d' } ] );
    ok !condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'like', operand_b => '[a-z]' } ] );

    ok condition_check(
        { foo => 'BAR' },
        all => [ { operand_a => 'foo', operator => 'like', operand_b => '[a-z]', options => { 'ignore_case' => 1 } } ]
    );

    ok !condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'not_like', operand_b => '\d' } ] );
    ok condition_check( { foo => 1 }, all => [ { operand_a => 'foo', operator => 'not_like', operand_b => '[a-z]' } ] );
};

subtest 'condition_check: ignores case' => sub {
    ok condition_check( { foo => 'foo' },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => 'FOO', options => { 'ignore_case' => 1 } } ] );
};

subtest 'condition_check: parses vars before comparison' => sub {
    ok condition_check( { foo => 1, bar => 1 },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => '${bar}' } ] );

    ok !condition_check( { foo => 1, bar => 2 },
        all => [ { operand_a => 'foo', operator => 'eq', operand_b => '${bar}' } ] );
};

subtest 'condition_check: returns correct result when all' => sub {
    ok condition_check(
        { foo => 1, bar => 1, baz => 1 },
        all => [
            { operand_a => 'foo', operator => 'is_true' },
            { operand_a => 'bar', operator => 'is_true' },
            { operand_a => 'baz', operator => 'is_true' },
        ]
    );

    ok !condition_check(
        { foo => 0, bar => 1, baz => 0 },
        all => [
            { operand_a => 'foo', operator => 'is_true' },
            { operand_a => 'bar', operator => 'is_true' },
            { operand_a => 'baz', operator => 'is_true' },
        ]
    );
};

subtest 'condition_check: returns correct result when any' => sub {
    ok condition_check(
        { foo => 0, bar => 1, baz => 0 },
        any => [
            { operand_a => 'foo', operator => 'is_true' },
            { operand_a => 'bar', operator => 'is_true' },
            { operand_a => 'baz', operator => 'is_true' },
        ]
    );

    ok !condition_check(
        { foo => 0, bar => 0, baz => 0 },
        any => [
            { operand_a => 'foo', operator => 'is_true' },
            { operand_a => 'bar', operator => 'is_true' },
            { operand_a => 'baz', operator => 'is_true' },
        ]
    );
};

subtest 'condition_check: returns correct result when none' => sub {
    ok condition_check(
        { foo => 0, bar => 0, baz => 0 },
        none => [
            { operand_a => 'foo', operator => 'is_true' },
            { operand_a => 'bar', operator => 'is_true' },
            { operand_a => 'baz', operator => 'is_true' },
        ]
    );

    ok !condition_check(
        { foo => 1, bar => 0, baz => 0 },
        none => [
            { operand_a => 'foo', operator => 'is_true' },
            { operand_a => 'bar', operator => 'is_true' },
            { operand_a => 'baz', operator => 'is_true' },
        ]
    );
};

done_testing();

sub _mock_job {
    my (%params) = @_;

    my $project    = TestUtils->create_ci_project();
    my $job_logger = _mock_job_logger();
    my $job        = Test::MonkeyMock->new;

    $job->mock( rollback    => sub { 0 } );
    $job->mock( logger      => sub { $job_logger } );
    $job->mock( update      => sub { } );
    $job->mock( load        => sub { { status => $params{status} } } );
    $job->mock( trap_action => sub { } );
    $job->mock( projects    => sub { $project } );

    return $job;
}

sub _mock_job_logger {
    my $job_logger = Test::MonkeyMock->new;
    $job_logger->mock( info  => sub { } );
    $job_logger->mock( debug => sub { } );
    $job_logger->mock( error => sub { } );
    $job_logger->mock( warn  => sub { } );

    return $job_logger;
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',    'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',  'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement', 'BaselinerX::Type::Config',
        'BaselinerX::Type::Menu',      'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'BaselinerX::Service::Scripting',
        'Baseliner::Model::Rules',     'Baseliner::Model::Topic',
        'BaselinerX::Job'
    );

    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->event->drop;
    mdb->queue->drop;
    mdb->rule->drop;
    mdb->topic->drop;
}

package TestService;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}
sub run_container { 'from TestService' }
