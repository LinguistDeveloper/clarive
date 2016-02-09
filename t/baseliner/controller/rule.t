use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst', 'mock_time';
BEGIN { TestEnv->setup }
use TestSetup;

use JSON ();

use_ok 'Baseliner::Controller::Rule';

subtest 'stmts_load: returns error when no rule id' => sub {
    _setup();

    my $c = mock_catalyst_c();

    my $controller = _build_controller();

    $controller->stmts_load($c);

    is_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'Missing rule id',
            'success' => \0
        }
      };
};

subtest 'stmts_load: returns empty rule tree' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    is_deeply $c->stash, { 'json' => [] };
};

subtest 'stmts_load: returns rule tree' => sub {
    _setup();

    my $id_rule = _create_rule(
        rule_tree => [
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "CHECK",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => []
            },
        ]
    );

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'disabled' => \0,
                'text'     => 'CHECK',
                'active'   => 1,
                'expanded' => \1,
                'children' => [],
                'key'      => 'statement.step',
                'leaf'     => JSON::false
            }
        ]
      };
};

subtest 'stmts_load: returns rule tree with versions' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    mock_time '2016-01-01 12:15:00', sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'someuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    mock_time '2016-01-02 12:15:00', sub {
        $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'newuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    my $c = mock_catalyst_c(
        req => { params => { id_rule => $id_rule, load_versions => 1 } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'icon'       => '/static/images/icons/history.png',
                'is_current' => \1,
                'text'       => 'Current: 2016-01-02 12:15:00 (newuser)',
                'children'   => [
                    {
                        'disabled' => \0,
                        'text'     => 'CHECK2',
                        'active'   => 1,
                        'expanded' => \1,
                        'children' => [],
                        'key'      => 'statement.step',
                        'leaf'     => JSON::false,
                    }
                ],
                'leaf' => \0
            },
            {
                'icon'     => '/static/images/icons/history.png',
                'text'     => 'Version: 2016-01-01 12:15:00 (someuser)',
                'children' => [
                    {
                        'disabled' => \0,
                        'text'     => 'CHECK',
                        'active'   => 1,
                        'expanded' => \1,
                        'children' => [],
                        'key'      => 'statement.step',
                        'leaf'     => JSON::false
                    }
                ],
                'version_id' => ignore(),
                'is_version' => \1,
                'leaf'       => \0
            }
        ]
      };
};

subtest 'rollback_version: rolls back to previous version' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    mock_time '2016-01-01 12:15:00', sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'someuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    mock_time '2016-01-02 12:15:00', sub {
        $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'newuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $c =
      mock_catalyst_c( req => { params => { version_id => $version_id } } );

    my $controller = _build_controller();

    mock_time '2016-01-03 12:15:00', sub {
        $controller->rollback_version($c);
    };

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'Rule rollback to 2016-01-01 12:15:00 (someuser)',
            'success' => \1
        }
      };

    $c = mock_catalyst_c(
        req => { params => { id_rule => $id_rule, load_versions => 1 } } );
    $controller->stmts_load($c);

    cmp_deeply $c->stash->{json}->[0],
      {
        'icon'       => '/static/images/icons/history.png',
        'is_current' => \1,
        'text' =>
          'Current: 2016-01-03 12:15:00 (someuser) was: 2016-01-01 12:15:00',
        'children' => [
            {
                'disabled' => \0,
                'text'     => 'CHECK',
                'active'   => 1,
                'expanded' => \1,
                'children' => [],
                'key'      => 'statement.step',
                'leaf'     => JSON::false
            }
        ],
        'leaf' => \0
      };
};

subtest 'dsl: returns rule dsl' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    my $stmts = mdb->rule->find_one( { id => "$id_rule" } )->{rule_tree};

    my $c = mock_catalyst_c(
        req => {
            params => {
                stmts     => $stmts,
                id_rule   => $id_rule,
                rule_type => 'independent'
            }
        }
    );

    my $controller = _build_controller();

    $controller->dsl($c);

    cmp_deeply $c->stash,
      {
        json => {
            success   => \1,
            data_yaml => "--- {}\n",
            dsl       => re(qr/current_task\(/)
        }
      };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'Baseliner::Model::Topic',
        'Baseliner::Model::Rules'
    );

    mdb->rule->drop;
    mdb->rule_version->drop;
}

sub _create_rule {
    my (%params) = @_;

    if ( $params{rule_tree} && ref $params{rule_tree} ) {
        $params{rule_tree} = JSON::encode_json( $params{rule_tree} );
    }

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            rule_seq  => $id_rule,
            rule_type => 'independent',
            %params,
        }
    );

    return "$id_rule";
}

sub _build_controller {
    Baseliner::Controller::Rule->new( application => '' );
}
