use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'BaselinerX::CI::report';

subtest 'reports_from_rule: returns empty tree when no report rules' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'developer' } );

    is_deeply $tree, [];
};

subtest 'reports_from_rule: builds tree from report rules' => sub {
    _setup();

    _create_report_rule( code => q/$stash->{report_security} = 1;/ );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'developer' } );

    cmp_deeply $tree,
      [
        {
            'icon' => ignore(),
            'text' => 'Rule',
            'data' => {
                'id_report_rule' => ignore(),
                'click'          => {
                    'icon'  => ignore(),
                    'url'   => '/comp/topic/topic_report.js',
                    'title' => 'Rule',
                    'type'  => 'eval'
                },
                'report_name' => 'Rule',
                'hide_tree'   => \1
            },
            'leaf' => \1,
            'key'  => ignore()
        }
      ];
};

subtest 'reports_from_rule: returns nothing when security fails' => sub {
    _setup();

    _create_report_rule();

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'developer' } );

    is @$tree, 0;
};

subtest 'reports_from_rule: returns nothing when security fails as a function' => sub {
    _setup();

    _create_report_rule( code => q/$stash->{report_security} = sub {0}/ );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'developer' } );

    is @$tree, 0;
};

subtest 'reports_from_rule: sends username to security function' => sub {
    _setup();

    _create_report_rule(
        code => q/
                    $stash->{report_security} = sub {
                        my %params = @_;
                        $params{username} eq 'developer' ? 1 : 0;
                      }
                /
    );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'developer' } );

    is @$tree, 1;
};

subtest 'reports_from_rule: always shows reports to root' => sub {
    _setup();

    _create_report_rule();

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'root' } );

    is @$tree, 1;
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::CI', 'BaselinerX::Type::Event', 'BaselinerX::Type::Statement',
        'Baseliner::Model::Rules' );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->role->drop;

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );
}

sub _create_report_rule {
    my (%params) = @_;

    TestSetup->create_rule(
        rule_type => 'report',
        rule_tree => [
            {
                "attributes" => {
                    "key"    => "statement.code.server",
                    "active" => 1,
                    "name"   => "Server CODE",
                    "data"   => {
                        "lang" => "perl",
                        "code" => $params{code}
                    },
                },
            }

        ]
    );
}
