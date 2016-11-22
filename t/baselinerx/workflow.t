use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use Baseliner::RuleFuncs qw(launch current_task);

use_ok 'BaselinerX::Workflow';

subtest 'workflow_transition_match: basic workflow' => sub {
    _setup();

    my $stash = {
        rule_context   => 'workflow',
        user_roles     => { '2' => 1 },
        id_status_from => '10',
        id_category    => '1',
    };
    my $config = {
        categories    => [ '1',  '2', '3' ],
        roles         => [ '1',  '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );
    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition_match: filtered out results by role' => sub {
    _setup();

    my $stash = {
        rule_context => 'workflow',
        user_roles   => { '3' => 1 },
        id_category  => '1',
    };
    my $config = {
        categories    => ['1'],
        roles         => [ '1', '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply( $stash->{workflow}, [] );
};

subtest 'workflow_transition_match: complete_workflow flag overrides role control' => sub {
    _setup();

    my $stash = {
        rule_context       => 'workflow',
        user_roles         => { '3' => 1 },
        id_category        => '1',
        _complete_workflow => 1,
    };
    my $config = {
        categories    => ['1'],
        roles         => ['2'],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '99',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition_match: filtered out results by category' => sub {
    _setup();

    my $stash = {
        rule_context => 'workflow',
        user_roles   => { '1' => 1 },
        id_category  => '2',
    };
    my $config = {
        categories    => ['1'],
        roles         => [ '1', '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply( $stash->{workflow}, [] );
};

subtest 'workflow_transition_match: complete_workflow overrides filtered out results by category' => sub {
    _setup();

    my $stash = {
        rule_context       => 'workflow',
        user_roles         => { '1' => 1 },
        id_category        => '2',
        _complete_workflow => 1,
    };
    my $config = {
        categories    => ['1'],
        roles         => [ '1', '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '1',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '1',
                id_status_from => '11',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '99',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition_match: filter by status_from' => sub {
    _setup();

    my $stash = {
        rule_context   => 'workflow',
        user_roles     => { '2' => 1 },
        id_category    => '1',
        id_status_from => ['11'],
    };
    my $config = {
        categories    => [ '1',  '2', '3' ],
        roles         => [ '1',  '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '99',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition_match: complete_workflow overrides filter by status_from' => sub {
    _setup();

    my $stash = {
        rule_context       => 'workflow',
        user_roles         => { '2' => 1 },
        id_category        => '1',
        status_from        => ['11'],
        _complete_workflow => 1,
    };
    my $config = {
        categories    => [ '1',  '2', '3' ],
        roles         => [ '1',  '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => '99',
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '1',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '1',
                id_status_from => '11',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '99',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition_match: filter by status_to' => sub {
    _setup();

    my $stash = {
        rule_context => 'workflow',
        user_roles   => { '2' => 1 },
        id_category  => '1',
        status_to    => '55',
    };
    my $config = {
        categories    => [ '1',  '2',  '3' ],
        roles         => [ '1',  '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => [ '44', '55', '99' ],
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '55',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '55',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition_match: complete_workflow overrides filter by status_to' => sub {
    _setup();

    my $stash = {
        rule_context       => 'workflow',
        user_roles         => { '2' => 1 },
        id_category        => '1',
        status_to          => '55',
        _complete_workflow => 1,
    };
    my $config = {
        categories    => [ '1',  '2', '3' ],
        roles         => [ '1',  '2' ],
        statuses_from => [ '10', '11' ],
        statuses_to   => [ '44', '55' ],
        job_type      => 'promote',
    };

    my $rv = launch( 'service.workflow.transition_match', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '1',
                id_status_from => '10',
                id_status_to   => '44',
                job_type       => 'promote',
            },
            {
                id_role        => '1',
                id_status_from => '10',
                id_status_to   => '55',
                job_type       => 'promote',
            },
            {
                id_role        => '1',
                id_status_from => '11',
                id_status_to   => '44',
                job_type       => 'promote',
            },
            {
                id_role        => '1',
                id_status_from => '11',
                id_status_to   => '55',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '44',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '55',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '44',
                job_type       => 'promote',
            },
            {
                id_role        => '2',
                id_status_from => '11',
                id_status_to   => '55',
                job_type       => 'promote',
            },
        ]
    );
};

subtest 'workflow_transition: basic workflow' => sub {
    _setup();

    my $stash = {
        id_status_from => '10',
        user_roles     => { '2' => 1 },
    };
    my $config = {
        statuses_to => [ '88', '99' ],
        job_type    => 'demote',
    };

    my $rv = launch( 'service.workflow.transition', 'transition test', $stash, $config, '' );

    is_deeply(
        $stash->{workflow},
        [
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '88',
                job_type       => 'demote',
            },
            {
                id_role        => '2',
                id_status_from => '10',
                id_status_to   => '99',
                job_type       => 'demote',
            },
        ]
    );
};

subtest 'statment.workflow.if_status_from: matches' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_status_from');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            statuses_from => ['11'],
            children      => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = { id_status_from => '11' };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    is $stash->{ret}, 123;
};

subtest 'statment.workflow.if_status_from: no match' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_status_from');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            statuses_from => ['11'],
            children      => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = { id_status_from => '22' };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    ok !$stash->{ret};
};

subtest 'statment.workflow.if_status_from: complete_workflow override' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_status_from');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            statuses_from => ['11'],
            children      => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = {
        id_status_from     => '22',
        _complete_workflow => 1,
    };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    is $stash->{ret}, 123;
};

subtest 'statment.workflow.if_role: matches' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_role');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            roles    => ['11'],
            children => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = { user_roles => { '11' => 1 } };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    is $stash->{ret}, 123;
};

subtest 'statment.workflow.if_role: no match' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_role');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            roles    => ['11'],
            children => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = { user_roles => { '22' => 1 } };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    ok !$stash->{ret};
};

subtest 'statment.workflow.if_role: complete_workflow override' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_role');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            roles    => ['11'],
            children => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = {
        user_roles         => { '22' => 1 },
        _complete_workflow => 1,
    };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    is $stash->{ret}, 123;
};

subtest 'statment.workflow.if_project: matches' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_project');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            projects => ['11'],
            children => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = { projects => ['11'], };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    is $stash->{ret}, 123;
};

subtest 'statment.workflow.if_project: no match' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_project');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            projects => ['11'],
            children => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = { projects => [], };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    ok !$stash->{ret};
};

subtest 'statment.workflow.if_project: complete_workflow override' => sub {
    _setup();

    local $Data::Dumper::Terse = 1;

    my $node = TestUtils->registry->get('statement.workflow.if_project');
    my $code = $node->dsl->(
        'Baseliner::Model::Rules',
        {
            projects => [11],
            children => [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.code.server",
                        "code"     => q{$stash->{ret} = 123;},
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
            ]
        }
    );
    my $stash = {
        projects           => ['22'],
        _complete_workflow => 1,
    };

    my $ret = eval "use Baseliner::Utils; $code";

    is $@, '';
    is $stash->{ret}, 123;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',   'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service', 'BaselinerX::CI',
        'BaselinerX::Workflow',      'Baseliner::Model::Rules',
    );
}
