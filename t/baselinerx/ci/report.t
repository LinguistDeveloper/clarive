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

subtest 'report_update: deletes report' => sub {
    _setup();

    my $project     = TestUtils->create_ci_project;
    my $id_role     = TestSetup->create_role();
    my $user        = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $report      = TestUtils->create_ci('report');
    my $id_form     = TestSetup->create_rule_form();
    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_category = TestSetup->create_category(
        id_rule      => $id_form,
        name         => 'Category',
        id_status    => $status->mid,
        default_grid => $report->{mid}
    );
    my $topic_mid = TestSetup->create_topic( id_category => $id_category, default_grid => $report->{mid} );

    my $return_data = $report->report_update( { action => 'delete', username => $user->username } );

    my $category_grid = mdb->category->find_one();

    ok !exists $category_grid->{default_grid};

    is_deeply $return_data,
        {
        'success' => \1,
        'msg'     => 'Search deleted'
        };
};

subtest 'report_update: deletes report then exists several categories' => sub {
    _setup();

    my $project     = TestUtils->create_ci_project;
    my $id_role     = TestSetup->create_role();
    my $user        = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $report        = TestUtils->create_ci('report');
    my $id_form       = TestSetup->create_rule_form();
    my $status        = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_category_1 = TestSetup->create_category(
        id_rule      => $id_form,
        name         => 'Category_1',
        id_status    => $status->mid,
        default_grid => $report->{mid}
    );
    my $id_category_2 = TestSetup->create_category(
        id_rule      => $id_form,
        name         => 'Category_2',
        id_status    => $status->mid,
        default_grid => $report->{mid}
    );

    my $return_data = $report->report_update( { action => 'delete', username => $user->username } );

    my $category_grid_1 = mdb->category->find_one( { id => $id_category_1 } );
    my $category_grid_2 = mdb->category->find_one( { id => $id_category_2 } );

    ok !exists $category_grid_1->{default_grid};
    ok !exists $category_grid_2->{default_grid};
};

subtest 'reports_from_rule: returns empty tree when no report rules' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => $user->username } );

    is_deeply $tree, [];
};

subtest 'reports_from_rule: builds tree from report rules' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = _create_report_rule( code => q/$stash->{report_security} = 1;/ );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => $user->username } );

    cmp_deeply $tree,
      [
        {
            'icon' => ignore(),
            'text' => 'Rule',
            'data' => {
                'id_report_rule' => $id_rule,
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
            'key'  => $id_rule,
        }
      ];
};

subtest 'reports_from_rule: returns nothing when security fails' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    _create_report_rule();

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => $user->username } );

    is @$tree, 0;
};

subtest 'reports_from_rule: returns nothing when security fails as a function' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    _create_report_rule( code => q/$stash->{report_security} = sub {0}/ );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => $user->username } );

    is @$tree, 0;
};

subtest 'reports_from_rule: sends username to security function' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $username = $user->username;

    _create_report_rule(
        code => qq/
                    \$stash->{report_security} = sub {
                        my %params = \@_;
                        \$params{username} eq '$username' ? 1 : 0;
                      }
                /
    );

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => $user->username } );

    is @$tree, 1;
};

subtest 'reports_from_rule: always shows reports to root' => sub {
    _setup();

    _create_report_rule();

    my $report = TestUtils->create_ci('report');

    my $tree = $report->reports_from_rule( { username => 'root' } );

    is @$tree, 1;
};

subtest 'report_meta: returns meta from rule' => sub {
    _setup();

    my $id_rule = _create_report_rule( code => q/$stash->{report_meta} = {foo => 'bar'};/ );

    my $report = TestUtils->create_ci('report');

    my $meta = $report->report_meta( { id_report_rule => $id_rule } );

    is_deeply $meta, { foo => 'bar' };
};

subtest 'report_meta: returns meta from rule as coderef' => sub {
    _setup();

    my $id_rule = _create_report_rule(
        code => q/
        $stash->{report_meta} = sub {
            my %params = @_;
            return { %params, bar => 'baz' };
        };
        /
    );

    my $report = TestUtils->create_ci('report');

    my $meta = $report->report_meta( { id_report_rule => $id_rule, config => { foo => 'bar' } } );

    is_deeply $meta, { foo => 'bar', bar => 'baz' };
};

subtest 'get_where: builds correct IN where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'children' => [
                        {
                            'options'  => [ 'Release #11309' ],
                            'value'    => [ '11309' ],
                            'children' => [],
                            'where'    => 'ci',
                            'oper'     => '$in',
                            'text'     => 'IN Release #11309',
                            'type'     => 'value',
                            'field'    => 'ci',
                        }
                    ],
                    'text'      => 'Release',
                    'category'  => 'Changeset',
                    'meta_type' => 'release',
                    'id_field'  => 'Release',
                    'type'      => 'where_field'
                }
            ],
        }
    );

    is_deeply $where, { Release => { '$in' => ['11309'] } };
};

subtest 'get_where: builds correct EMPTY where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'children' => [
                        {
                            'options'  => [],
                            'children' => [],
                            'where'    => 'ci',
                            'oper'     => 'EMPTY',
                            'text'     => 'EMPTY',
                            'type'     => 'value',
                            'field'    => 'ci',
                        }
                    ],
                    'text'      => 'Release',
                    'category'  => 'Changeset',
                    'meta_type' => 'release',
                    'id_field'  => 'Release',
                    'type'      => 'where_field'
                }
            ],
        }
    );

    is_deeply $where,
      {
        '$or' => [
            { 'Release' => { '$exists' => 0 } },
            { 'Release' => { '$in'     => [ undef, '' ] } },
            { 'Release' => { '$eq'     => [] } }
        ]
      };
};

subtest 'get_where: builds correct NOT EMPTY where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'children' => [
                        {
                            'options'  => [],
                            'children' => [],
                            'where'    => 'ci',
                            'oper'     => 'NOT EMPTY',
                            'text'     => 'NOT EMPTY',
                            'type'     => 'value',
                            'field'    => 'ci',
                        }
                    ],
                    'text'      => 'Release',
                    'category'  => 'Changeset',
                    'meta_type' => 'release',
                    'id_field'  => 'Release',
                    'type'      => 'where_field'
                }
            ],
        }
    );

    is_deeply $where,
      {
        'Release' => {
            '$exists' => 1,
            '$nin'    => [ undef, '' ],
            '$ne'     => [],
        }
      };
};

subtest 'get_where: builds correct string equals where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'type'     => 'where_field',
                    'text'     => "Title",
                    'children' => [
                        {
                            'where'    => 'string',
                            'oper'     => '',
                            'type'     => 'value',
                            'children' => [],
                            'field'    => 'string',
                            'icon'     => '/static/images/icons/where.svg',
                            'value'    => 'foo',
                            'text'     => '= foo'
                        }
                    ],
                    'id_field' => 'title',
                }
            ]
        }
    );

    cmp_deeply $where, { title => 'foo' };
};

subtest 'get_where: builds correct string not equals where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'type'     => 'where_field',
                    'text'     => "Title",
                    'children' => [
                        {
                            'where'    => 'string',
                            'oper'     => '$ne',
                            'type'     => 'value',
                            'children' => [],
                            'field'    => 'string',
                            'icon'     => '/static/images/icons/where.svg',
                            'value'    => 'foo',
                            'text'     => '<> foo'
                        }
                    ],
                    'id_field' => 'title',
                }
            ]
        }
    );

    cmp_deeply $where, { title => { '$ne' => 'foo' } };
};

subtest 'get_where: builds correct string like where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'type'     => 'where_field',
                    'text'     => "Title",
                    'children' => [
                        {
                            'where'    => 'string',
                            'oper'     => 'like',
                            'type'     => 'value',
                            'children' => [],
                            'field'    => 'string',
                            'icon'     => '/static/images/icons/where.svg',
                            'value'    => 'foo',
                            'text'     => 'LIKE foo'
                        }
                    ],
                    'id_field' => 'title',
                }
            ]
        }
    );

    cmp_deeply $where, { title => qr/foo/i };
};

subtest 'get_where: builds correct string not like where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'type'     => 'where_field',
                    'text'     => "Title",
                    'children' => [
                        {
                            'where'    => 'string',
                            'oper'     => 'not_like',
                            'type'     => 'value',
                            'children' => [],
                            'field'    => 'string',
                            'icon'     => '/static/images/icons/where.svg',
                            'value'    => 'foo',
                            'text'     => 'NOT LIKE foo'
                        }
                    ],
                    'id_field' => 'title',
                }
            ]
        }
    );

    cmp_deeply $where, { title => { '$not' => qr/foo/i } };
};

subtest 'get_where: builds correct string in where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'type'     => 'where_field',
                    'text'     => "Title",
                    'children' => [
                        {
                            'where'    => 'string',
                            'oper'     => '$in',
                            'type'     => 'value',
                            'children' => [],
                            'field'    => 'string',
                            'icon'     => '/static/images/icons/where.svg',
                            'value'    => 'foo,bar,baz',
                            'text'     => 'IN foo'
                        }
                    ],
                    'id_field' => 'title',
                }
            ]
        }
    );

    cmp_deeply $where, { title => { '$in' => [qw/foo bar baz/] } };
};

subtest 'get_where: builds correct string not in where' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');

    my $where = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'type'     => 'where_field',
                    'text'     => "Title",
                    'children' => [
                        {
                            'where'    => 'string',
                            'oper'     => '$nin',
                            'type'     => 'value',
                            'children' => [],
                            'field'    => 'string',
                            'icon'     => '/static/images/icons/where.svg',
                            'value'    => 'foo,bar,baz',
                            'text'     => 'NOT IN foo'
                        }
                    ],
                    'id_field' => 'title',
                }
            ]
        }
    );

    cmp_deeply $where, { title => { '$nin' => [qw/foo bar baz/] } };
};

subtest 'all_fields: returns categories' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form;

    my $id_category1 = TestSetup->create_category(id_rule => $id_rule);

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_category1 } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $report = TestUtils->create_ci('report');

    my $fields = $report->all_fields({username => $user->username});

    cmp_deeply $fields,
      [
        {
            'leaf'     => \0,
            'icon'     => ignore(),
            'children' => [
                {
                    'leaf' => \0,
                    'type' => 'category',
                    'icon' => ignore(),
                    'data' => {
                        'id_category'   => ignore(),
                        'name_category' => 'Category',
                        fields          => [ [ 'title', '' ], [ 'status_new', '' ], [ 'category', 'Category' ] ]
                    },
                    'text' => 'Category'
                }
            ],
            'expanded'  => \1,
            'draggable' => \0,
            'text'      => 'Categories'
        }
      ];
};

subtest 'all_fields: returns category fields' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form;

    my $id_category = TestSetup->create_category(id_rule => $id_rule);

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_category } ]
            },
            {
                action => 'action.topicsfield.read',
                bounds => [ { } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $report = TestUtils->create_ci('report');

    my $fields = $report->all_fields( { username => $user->username, id_category => $id_category } );

    my ($title) = grep {$_->{id_field} eq 'title'} @$fields;

    cmp_deeply $title,
      {
        'leaf'               => \1,
        'collection_extends' => undef,
        'type'               => 'select_field',
        'category'           => 'Category',
        'format'             => undef,
        'meta_type'          => '',
        'icon'               => ignore(),
        'id_field'           => 'title',
        'text'               => '',
        'collection'         => undef,
        'ci_class'           => undef,
        'options'            => undef,
        'gridlet'            => undef,
        'filter'             => undef
      };
};

subtest 'all_fields: returns category fields filtering out not readable' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form;

    my $id_category = TestSetup->create_category(id_rule => $id_rule);

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_category } ]
            },
            {
                action => 'action.topicsfield.read',
                bounds => [ { id_field => 'title' } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $report = TestUtils->create_ci('report');

    my $fields = $report->all_fields( { username => $user->username, id_category => $id_category } );

    ok !grep {$_->{id_field} eq 'description'} @$fields;
};

subtest 'get_where: builds correct IN where for status' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');
    my $where  = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'children' => [
                        {
                            'options'  => [ 'In QA', 'NEW',    'In PreProd', 'In DEV' ],
                            'value'    => [ 'id_qa', 'id_new', 'id_pre',     'id_dev' ],
                            'children' => [],
                            'where'    => 'status',
                            'oper'     => '$in',
                            'text'     => 'In QA, New, In PreProd, In Dev',
                            'type'     => 'value',
                            'field'    => 'status',
                        }
                    ],
                    'text'      => 'Status',
                    'category'  => 'Changeset',
                    'meta_type' => 'status',
                    'id_field'  => 'status',
                    'type'      => 'value'
                }
            ],
        }
    );

    is_deeply $where, { status => { '$in' => [ 'id_qa', 'id_new', 'id_pre', 'id_dev' ] } };
};

subtest 'get_where: builds correct NIN where for status' => sub {
    _setup();

    my $report = TestUtils->create_ci('report');
    my $where  = $report->get_where(
        {
            'dynamic_filter' => {},
            'name_category'  => 'Changeset',
            'filters_where'  => [
                {
                    'children' => [
                        {
                            'options'  => [ 'In QA', 'NEW',    'In PreProd', 'In DEV' ],
                            'value'    => [ 'id_qa', 'id_new', 'id_pre',     'id_dev' ],
                            'children' => [],
                            'where'    => 'status',
                            'oper'     => '$nin',
                            'text'     => 'In QA, New, In PreProd, In Dev',
                            'type'     => 'value',
                            'field'    => 'status',
                        }
                    ],
                    'text'      => 'Status',
                    'category'  => 'Changeset',
                    'meta_type' => 'status',
                    'id_field'  => 'status',
                    'type'      => 'value'
                }
            ],
        }
    );

    is_deeply $where, { status => { '$nin' => [ 'id_qa', 'id_new', 'id_pre', 'id_dev' ] } };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Registor',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Topic',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->user->drop;
    mdb->role->drop;
    mdb->category->drop;
    mdb->topic->drop;
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
