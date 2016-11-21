use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;
use Test::TempDir::Tiny;
use Test::LongString;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst mock_time);
use TestSetup;

use Class::Date;
use POSIX ":sys_wait_h";
use Baseliner::Role::CI;
use Baseliner::Model::Topic;
use Baseliner::RuleFuncs;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Fieldlets;
use Baseliner::Queue;
use Baseliner::Model::Topic;
use Baseliner::Utils qw(_encode_json _load _decode_json);
use Clarive::mdb;

use_ok 'Baseliner::Controller::Topic';

subtest 'grid: check that customized fields is set correctly into stash' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $report      = TestUtils->create_ci('report');
    my $id_rule     = TestSetup->create_rule();
    my $id_category = TestSetup->create_category(
        name         => 'Category',
        id_rule      => $id_rule,
        default_grid => $report->{mid}
    );

    $report->report_update(
        {   action   => 'update',
            username => $user->{username},
            data     => {
                name           => 'Test',
                permissions    => 'private',
                recursivelevel => '2',
                rows           => 50,
                selected       => [
                    {   type     => 'categories',
                        query    => { $id_category => { id_category => [$id_category] } },
                        text     => 'Categories',
                        children => [
                            {   name => 'Category',
                                type => 'categories_field',
                                text => 'Category',
                                data => {
                                    name_category => 'Category',
                                    fields        => [ [ 'field1', 'field1' ], [ 'field2', 'field2' ] ],
                                    id_category   => $id_category
                                },
                                text => 'Category'
                            }
                        ]
                    },
                    {   'text'     => 'Fields',
                        'type'     => 'select',
                        'children' => [
                            {   meta_type => '',
                                children  => [],
                                id_field  => 'field1',
                                text      => 'Category: field1',
                                category  => 'Category',
                                type      => 'select_field'
                            },
                            {   meta_type => '',
                                children  => [],
                                id_field  => 'field2',
                                text      => 'Category: field2',
                                category  => 'Category',
                                type      => 'select_field'
                            }
                        ]
                    }
                ]
            }
        }
    );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->{username}, req => { params => { category_id => $id_category } } );

    $controller->grid($c);

    is $c->stash->{template}, '/comp/topic/topic_grid.js';

    cmp_deeply(
        _decode_json( $c->stash->{data_fields} ),
        {   'fields' => {
                'columns' => [
                    {   'as'        => undef,
                        'id'        => 'field1',
                        'filter'    => undef,
                        'id_field'  => 'field1',
                        'type'      => 'select_field',
                        'meta_type' => '',
                        'children'  => [],
                        'text'      => 'Category: field1',
                        'category'  => 'Category'
                    },
                    {   'meta_type' => '',
                        'filter'    => undef,
                        'as'        => undef,
                        'id'        => 'field2',
                        'type'      => 'select_field',
                        'id_field'  => 'field2',
                        'category'  => 'Category',
                        'text'      => 'Category: field2',
                        'children'  => []
                    }
                ],
                'ids' => [
                    'mid',         'topic_mid',       'category_name', 'category_color',
                    'modified_on', 'field1_Category', 'field2_Category'
                ]
            }
        }
    );
};

subtest 'grid: set default params when default_grid is not exists' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $report      = TestUtils->create_ci('report');
    my $id_rule     = TestSetup->create_rule();
    my $id_category = TestSetup->create_category(
        name         => 'Category',
        id_rule      => $id_rule,
        default_grid => '1'
    );

    $report->report_update(
        {   action   => 'update',
            username => $user->{username},
            data     => {
                name           => 'Test',
                permissions    => 'private',
                recursivelevel => '2',
                rows           => 50,
                selected       => [
                    {   type     => 'categories',
                        query    => { $id_category => { id_category => [$id_category] } },
                        text     => 'Categories',
                        children => [
                            {   name => 'Category',
                                type => 'categories_field',
                                text => 'Category',
                                data => {
                                    name_category => 'Category',
                                    fields        => [ [ 'field1', 'field1' ], [ 'field2', 'field2' ] ],
                                    id_category   => $id_category
                                },
                                text => 'Category'
                            }
                        ]
                    },
                    {   'text'     => 'Fields',
                        'type'     => 'select',
                        'children' => [
                            {   meta_type => '',
                                children  => [],
                                id_field  => 'field1',
                                text      => 'Category: field1',
                                category  => 'Category',
                                type      => 'select_field'
                            },
                            {   meta_type => '',
                                children  => [],
                                id_field  => 'field2',
                                text      => 'Category: field2',
                                category  => 'Category',
                                type      => 'select_field'
                            }
                        ]
                    }
                ]
            }
        }
    );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->{username}, req => { params => { category_id => $id_category } } );

    $controller->grid($c);

    is $c->stash->{template},           '/comp/topic/topic_grid.js';
    is $c->stash->{no_report_category}, 1;
    is $c->stash->{id_report},          '';
};

subtest 'category_list: returns categories when filter on category name' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category( name => 'MyCategory', color => '#FFFFFF' );
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();
    my $c          = _build_c(
        username => $user->username,
        req      => { params => { query => 'mycategory' } }
    );

    my $controller = _build_controller();

    $controller->category_list($c);

    cmp_deeply(
        $c->stash->{json},
        {
            data => [
                {
                    'name'  => 'MyCategory',
                    'color' => '#FFFFFF',
                    'id'    => $category_1
                }
            ],
            totalCount => 1
        }
    );
};

subtest 'category_list: returns categories when filter on id' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category( name => 'Category_1', color => '#FFFFFF' );
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category( name => 'Category_2', color => '#FFFFFF' );

    my $query = "$category_1|$category_3";

    my $c = _build_c(
        username => $user->username,
        req      => { params => { query => $query, valuesqry => 'true' } }
    );

    my $controller = _build_controller();

    $controller->category_list($c);

    cmp_deeply(
        $c->stash->{json},
        {
            data => [
                {
                    'name'  => 'Category_1',
                    'color' => '#FFFFFF',
                    'id'    => $category_1
                },
                {
                    'name'  => 'Category_2',
                    'color' => '#FFFFFF',
                    'id'    => $category_3
                },
            ],
            totalCount => 2
        }
    );
};

subtest 'category_list: returns categories when filter on category name with special symbols' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category( name => 'My$Category', color => '#FFFFFF' );
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();
    my $c          = _build_c(
        username => $user->username,
        req      => { params => { query => 'my$category' } }
    );

    my $controller = _build_controller();

    $controller->category_list($c);

    cmp_deeply(
        $c->stash->{json},
        {
            data => [
                {
                    'name'  => 'My$Category',
                    'color' => '#FFFFFF',
                    'id'    => $category_1
                }
            ],
            totalCount => 1
        }
    );
};

subtest 'category_list: returns query when extra values' => sub {
    _setup();

    my $c = _build_c(
        username => 'root',
        req      => { params => { query => 'custom value', valuesqry => 'true', with_extra_values => 'true' } }
    );

    my $controller = _build_controller();

    $controller->category_list($c);

    cmp_deeply(
        $c->stash->{json},
        {
            data => [
                {
                    'name' => 'custom value',
                    'id'   => 'custom value'
                }
            ],
            totalCount => 1
        }
    );
};

subtest 'kanban config save' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid => $topic_mid, statuses => [ $base_params->{status_new} ] } } );
    $controller->kanban_config($c);
    ok ${ $c->stash->{json}{success} };

    $c = _build_c( req => { params => { mid => $topic_mid } } );
    $controller->kanban_config($c);
    is $c->stash->{json}{config}{statuses}->[0], $base_params->{status_new};
};

subtest 'kanban no config, default' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid => $topic_mid } } );
    $controller->kanban_config($c);
    is keys %{ $c->stash->{json}{config} }, 0;
};

subtest 'next status for topic by root user' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow =
      [ { id_role => '1', id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef } ];
    mdb->category->update( { id => "$base_params->{category}" },
        { '$set' => { workflow => $workflow }, '$push' => { statuses => $id_status_to } } );

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid => "$topic_mid" } } );
    $c->{username} = 'root';    # change context to root
    $controller->list_admin_category($c);
    my $data = $c->stash->{json}{data};

    # 2 rows, root can take the topic
    is $data->[0]->{status}, $id_status_from;
    is $data->[1]->{status}, $id_status_to;
};

subtest 'next status for topics by root user' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow =
      [ { id_role => '1', id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef } ];
    mdb->category->update( { id => "$base_params->{category}" },
        { '$set' => { workflow => $workflow }, '$push' => { statuses => $id_status_to } } );

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topics => ["$topic_mid"] } } );
    $c->{username} = 'root';    # change context to root
    $controller->next_status_for_topics($c);
    my $data = $c->stash->{json}{data};

    is $data->[0]->{id_status_from}, $id_status_from;
    is $data->[0]->{id_status_to},   $id_status_to;
};

subtest 'list statuses fieldlet for new topics not yet in database' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow =
      [ { id_role => '1', id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef } ];
    mdb->category->update( { id => "$base_params->{category}" },
        { '$set' => { workflow => $workflow }, '$push' => { statuses => $id_status_to } } );

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { categoryId => $base_params->{category}, statusId => $id_status_from } } );
    $c->{username} = 'root';    # change context to root
    $controller->list_admin_category($c);
    my $data = $c->stash->{json}{data};

    # 2 rows, root can take the topic
    is $data->[0]->{status}, $id_status_from;
    is $data->[1]->{status}, $id_status_to;
};

subtest 'grid: sets correct template' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

    $controller->grid($c);

    is $c->stash->{template}, '/comp/topic/topic_grid.js';
};

subtest 'grid: prepares stash' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

    $controller->grid($c);

    cmp_deeply(
        $c->stash,
        {
            'typeApplication' => undef,
            'template'        => ignore(),
            'query_id'        => undef,
            'project'         => undef,
            'id_project'      => undef
        }
    );
};

subtest 'grid: overrides stash with params' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { query => '123', project => '456', id_project => '789' } } );

    $controller->grid($c);

    cmp_deeply(
        $c->stash,
        {
            'typeApplication' => undef,
            'template'        => ignore(),
            'query_id'        => '123',
            'project'         => '456',
            'id_project'      => '789',
        }
    );
};

subtest 'grid: set category_id' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { category_id => '123' } } );

    $controller->grid($c);

    is $c->stash->{category_id}, '123';
};

subtest 'grid: replaces category_id if different' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { category_id => '123' } } );

    $c->stash->{category_id} = 321;
    $controller->grid($c);

    is $c->stash->{category_id}, '123';
};

subtest 'related: returns 1 (proper topic) for new topic before created' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => {} } );
    $c->{username} = 'root';    # change context to root

    $controller->related($c);
    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 0;
    is $c->stash->{json}->{totalCount}, 0;
};

subtest 'related: returns self for a newly created topic' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid => $topic_mid } } );
    $c->{username} = 'root';    # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 1;
    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'related: returns 2 (self and related) related topics' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    $base_params->{parent} = [$topic_mid];

    my ( undef, $topic_mid_2 ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid => $topic_mid } } );
    $c->{username} = 'root';    # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'related: valuesqry returns data for SuperBox in string mode' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    $base_params->{parent} = [$topic_mid];

    my ( undef, $topic_mid_2 ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { valuesqry=>'true', filter =>'{"statuses":["status-1"]}' ,query=>"$topic_mid $topic_mid_2" } } );
    $c->{username} = 'root'; # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'related: valuesqry non return data when exist filter' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    $base_params->{parent} = [$topic_mid];

    my ( undef, $topic_mid_2 ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { valuesqry=>'', filter =>'{"statuses":["status-1"]}' ,query=>"$topic_mid $topic_mid_2" } } );
    $c->{username} = 'root'; # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 0;
    is $c->stash->{json}->{totalCount}, 0;
};


subtest 'related: valuesqry returns data for SuperBox in array mode' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    $base_params->{parent} = [$topic_mid];

    my ( undef, $topic_mid_2 ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { valuesqry=>'true', query=>[$topic_mid, $topic_mid_2] } } );
    $c->{username} = 'root'; # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'related: sends correct parameters to DataView' => sub {
    _setup();
    TestSetup->_setup_user();

    my $data_view = Baseliner::DataView::Topic->new;
    $data_view = Test::MonkeyMock->new($data_view);
    $data_view->mock('find');

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock(_build_data_view => sub {$data_view});

    my $c = _build_c(
        req => {
            params => {
                valuesqry     => '',
                categories    => [ 1, 2, 3 ],
                statuses      => [ 4, 5, 6 ],
                not_in_status => 'on',
                query         => 'this and that',
                filter        => '{"foo":"bar"}',
                sort_field    => 'title',
                dir           => 'asc',
            }
        }
    );

    $controller->related($c);

    my %params = $data_view->mocked_call_args('find');

    is_deeply \%params,
      {
        'filter'        => '{"foo":"bar"}',
        'valuesqry'     => '',
        'where'         => undef,
        'categories'    => [1, 2, 3],
        'dir'           => 'asc',
        'username'      => 'test',
        'sort'          => 'title',
        'not_in_status' => 1,
        'limit'         => 20,
        'statuses'      => [4, 5, 6],
        'search_query'  => 'this and that',
        'start'         => 0
      };
};

subtest 'create a topic' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();
    my $controller  = _build_controller();
    my $c           = _build_c(
        req => {
            params => {
                new_category_id   => $base_params->{category},
                new_category_name => 'Changeset',
                swEdit            => '1',
                tab_cls           => 'ui-tab-changeset',
                tab_icon          => ''
            }
        }
    );
    $c->{username} = 'root';    # change context to root
    $controller->view($c);
    my $stash = $c->stash;

    ok !exists $stash->{json}{success};    # this only shows up in case of failure
};

subtest 'new topics have category_id in stash' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();
    my $controller  = _build_controller();
    my $c           = _build_c(
        req => {
            params => {
                new_category_id   => $base_params->{category},
                new_category_name => 'Changeset',
                swEdit            => '1',
                tab_cls           => 'ui-tab-changeset',
                tab_icon          => ''
            }
        }
    );
    $c->{username} = 'root';    # change context to root
    $controller->view($c);
    my $stash = $c->stash;
    is $stash->{category_id}, $base_params->{category};
};

subtest 'list_status_changes: returns status changes' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $topic_mid = TestSetup->create_topic(
        status => $status,
        title  => "Topic"
    );

    my $model = Baseliner::Model::Topic->new;

    my $status1 = TestUtils->create_ci( 'status', name => 'Change1', type => 'I' );
    $model->change_status( mid => $topic_mid, id_status => $status1->mid, change => 1, username => $user->username );

    my $status2 = TestUtils->create_ci( 'status', name => 'Change2', type => 'I' );
    $model->change_status( mid => $topic_mid, id_status => $status2->mid, change => 1, username => $user->username );

    my @changes = $model->status_changes($topic_mid);

    my $c = _build_c( req => { params => { mid => $topic_mid } } );

    my $controller = _build_controller();
    $controller->list_status_changes($c);

    cmp_deeply $c->stash, { json => { data => [ ignore(), ignore() ] } };
};

subtest 'list_category: returns ids categories' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { categories_id_filter => "" } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{data}[0]->{category}, $category_1;
    is $c->stash->{json}->{data}[1]->{category}, $category_2;
    is $c->stash->{json}->{data}[2]->{category}, $category_3;
    is $c->stash->{json}->{totalCount}, 3;
};

subtest 'list_category: returns ids categories when filter on id categories' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { categories_id_filter => [ $category_1, $category_3 ] } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{totalCount}, 2;
    is $c->stash->{json}->{data}[0]->{category}, $category_1;
    is $c->stash->{json}->{data}[1]->{category}, $category_3;
};

subtest 'list_category: returns ids categories when all option filter is activated' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();

    my @category_name = map { $_->{name} }
        mdb->category->find( { id => mdb->in( $category_1, $category_2 ) } )->fields( { name => 1 } )->all;
    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                categories_id_filter => [ $category_1, $category_2 ],
                categories_filter    => {
                    id_category   => [$category_1],
                    category_id   => [$category_1],
                    name_category => \@category_name,
                    category_name => \@category_name
                }
            }
        }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{data}[0]->{category}, $category_1;
    is $c->stash->{json}->{data}[1]->{category}, $category_2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'list_category: return ids when user has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $category_1 } ]
            }
        ],
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c(
        username => $user->username,
        req      => { params => { action => 'view' } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{totalCount}, 1;
    is $c->stash->{json}->{data}[0]->{category}, $category_1;
};

subtest 'list_category: do not return categories when user not has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my @category_name = map { $_->{name} }
        mdb->category->find( { id => mdb->in( $category_1, $category_2 ) } )->fields( { name => 1 } )->all;
    my $c = _build_c(
        username => $user->username,
        req      => { params => { action => 'create' } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{totalCount}, 0;
};

subtest 'list_category: return just categories that have permission to return' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $category_1 = TestSetup->create_category(name => 'category_1' );
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $category_1 } ]
            }
        ],
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c(
        username => 'developer',
        req      => { params => { categories_id_filter => [ $category_1, $category_3 ] } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{totalCount}, 1;
    is $c->stash->{json}->{data}[0]->{category}, $category_1;
};

subtest 'topic_drop: set error when no drop fields found' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $release_mid   = TestSetup->create_topic( project => $project );
    my $changeset_mid = TestSetup->create_topic( project => $project );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { node1 => { topic_mid => $changeset_mid }, node2 => { topic_mid => $release_mid } } }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "No drop fields available in topics $changeset_mid or $release_mid",
            'success' => \0
        }
      };
};

subtest 'topic_drop: drops child to parent' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $user = _create_user_with_drop_rules(
        project               => $project,
        id_changeset_category => $id_changeset_category,
        id_release_category   => $id_release_category,
        id_status             => $status->id_status,
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { node1 => { topic_mid => $changeset_mid }, node2 => { topic_mid => $release_mid } } }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Topic #$release_mid added to #$changeset_mid in field `release`",
            'success' => \1
        }
      };

    my $changeset_doc = mdb->topic->find_one( { mid => $changeset_mid } );
    is_deeply $changeset_doc->{release}, [$release_mid];
};

subtest 'topic_drop: asks user if several variants possible' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $user = _create_user_with_drop_rules(
        project               => $project,
        id_changeset_category => $id_changeset_category,
        id_release_category   => $id_release_category,
        id_status             => $status->id_status,
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { node1 => { topic_mid => $changeset_mid }, node2 => { topic_mid => $release_mid } } }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'targets' => [ ignore(), ignore() ],
            'success' => \1
        }
      };

    is $c->stash->{json}->{targets}->[0]->{meta}->{name}, 'Sprint';
    is $c->stash->{json}->{targets}->[1]->{meta}->{name}, 'Release';
};

subtest 'topic_drop: uses selected by user variant' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $user = _create_user_with_drop_rules(
        project               => $project,
        id_changeset_category => $id_changeset_category,
        id_release_category   => $id_release_category,
        id_status             => $status->id_status,
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                selected_id_field => 'release',
                selected_mid      => $changeset_mid,
                node1             => { topic_mid => $changeset_mid },
                node2             => { topic_mid => $release_mid }
            }
        }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Topic #$release_mid added to #$changeset_mid in field `release`",
            'success' => \1
        }
      };

    my $changeset_doc = mdb->topic->find_one( { mid => $changeset_mid } );
    cmp_deeply $changeset_doc->{release}, [$release_mid];
};

subtest 'topic_drop: correctly select relese field when something was previously selected' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

    my $user = _create_user_with_drop_rules(
        project               => $project,
        id_changeset_category => $id_changeset_category,
        id_release_category   => $id_release_category,
        id_status             => $status->id_status,
    );

    my $sprint_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #1',
        status      => $status
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset_mid, sprint => [$sprint_mid], username => $user->username } );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                selected_id_field => 'release',
                selected_mid      => $changeset_mid,
                node1             => { topic_mid => $changeset_mid },
                node2             => { topic_mid => $release_mid }
            }
        }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Topic #$release_mid added to #$changeset_mid in field `release`",
            'success' => \1
        }
      };

    my $changeset_doc = mdb->topic->find_one( { mid => $changeset_mid } );
    cmp_deeply $changeset_doc->{release}, [$release_mid];
};

subtest 'topic_drop: correctly adds existing release' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

    my $user = _create_user_with_drop_rules(
        project               => $project,
        id_changeset_category => $id_changeset_category,
        id_release_category   => $id_release_category,
        id_sprint_category    => $id_sprint_category,
        id_status             => $status->id_status,
    );

    my $sprint_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #1',
        status      => $status
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status
    );

    my $release_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.2',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset_mid, release => [$release_mid], username => $user->username } );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                selected_id_field => 'release',
                selected_mid      => $changeset_mid,
                node1             => { topic_mid => $changeset_mid },
                node2             => { topic_mid => $release_mid2 }
            }
        }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Topic #$release_mid2 added to #$changeset_mid in field `release`",
            'success' => \1
        }
      };

    my $changeset_doc = mdb->topic->find_one( { mid => $changeset_mid } );

    cmp_deeply $changeset_doc->{release}, [ $release_mid, $release_mid2 ];
};

subtest 'topic_drop: correctly replaces existing release when value_type is single' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form( release => { value_type => 'single' }, with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

    my $user = _create_user_with_drop_rules(
        project               => $project,
        id_changeset_category => $id_changeset_category,
        id_release_category   => $id_release_category,
        id_sprint_category    => $id_sprint_category,
        id_status             => $status->id_status,
    );

    my $sprint_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #1',
        status      => $status
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status
    );

    my $release_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release 0.2',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset_mid, release => [$release_mid], username => $user->username } );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                selected_id_field => 'release',
                selected_mid      => $changeset_mid,
                node1             => { topic_mid => $changeset_mid },
                node2             => { topic_mid => $release_mid2 }
            }
        }
    );

    $controller->topic_drop($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Topic #$release_mid2 added to #$changeset_mid in field `release`",
            'success' => \1
        }
      };

    my $changeset_doc = mdb->topic->find_one( { mid => $changeset_mid } );
    cmp_deeply $changeset_doc->{release}, [$release_mid2];
};


subtest 'upload: returns false if param qqfile is not passed' => sub {
    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                extension => 'jpg',
                topic_mid => '1234',
                filter    => 'test_file'
            },
            body => "tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);

    cmp_deeply $c->stash,
        {
        json => {
            success => \0,
            msg     => re(qr/Validation failed/),
            errors  => { qqfile => re(qr/REQUIRED/) }
        }
        };

};

subtest 'upload: returns false if body of the file is not passed' => sub {
    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                extension => 'jpg',
                topic_mid => '1234',
                filter    => 'test_file',
                qqfile    => 'filename.jpg'
            },
            body   => '',
            upload => {}
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    cmp_deeply $c->stash,
        { json => { success => 0, msg => re(qr/qqfile is not a file/) } };

};

subtest 'upload: returns false if param topic_mid is not passed' => sub {
    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                extension => 'jpg',
                filter    => 'test_file',
                qqfile    => 'filename.jpg'
            },
            body => "tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    cmp_deeply $c->stash,
        {
        json => {
            success => \0,
            msg     => re(qr/Validation failed/),
            errors  => { topic_mid => re(qr/REQUIRED/) }
        }
        };

};

subtest 'upload: returns false if param filter is not passed' => sub {
    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                extension => 'jpg',
                topic_mid => '1234',
                qqfile    => 'filename.jpg'
            },
            body => "tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    cmp_deeply $c->stash,
        {
        json => {
            success => \0,
            msg     => re(qr/Validation failed/),
            errors  => { filter => re(qr/REQUIRED/) }
        }
        };

};

subtest 'upload: returns true if file uploaded' => sub {
    _setup();

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username  = ci->user->find_one()->{name};
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $c         = _build_c(
        username => $username,
        req      => {
            params => {
                extension => 'txt',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.txt'
            },
            body => $file->stringify
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    my $asset = ci->asset->find_one();

    cmp_deeply $c->stash,
        {
        json => {
            success => 1,
            msg     => re(
                qr/Uploaded file filename.txt, file_uploaded_mid: $asset->{mid}/
            ),
            upload_file => {
                mid      => $asset->{mid},
                name     => $asset->{name},
                fullpath => '/filename.txt'
            }
        }
        };

    $file->remove();
};

subtest 'upload complete: creates correct event.file.create event' => sub {
    _setup();

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username = 'test_user';

    my @upload_files
        = ( { mid => 'test_asset', name => 'my_test_file', fullpath => '' } );

    my $c = _build_c(
        username => $username,
        req      => {
            params => {
                topic_mid    => $topic_mid,
                idField      => 'test_file',
                username     => $username,
                upload_files => \@upload_files
            }
        }
    );

    my $controller = _build_controller();
    $controller->upload_complete($c);

    my $event = mdb->event->find_one( { event_key => 'event.file.create' } );
    my $event_data = _load $event->{event_data};

    cmp_deeply $event_data,
        superhashof(
        {   username       => $username,
            mid            => $topic_mid,
            id_files       => \@upload_files,
            id_field_asset => 'test_file',
            total_files    => scalar @upload_files,
            notify_default => [],
            subject        => re(qr/Created 1 files to topic \[$topic_mid\]/)
        }
        );

    cmp_deeply $c->stash,
        { json => { success => 1, msg => 'Upload completed' } };

};

subtest 'file_tree: returns false if param topic_mid is passed without filter param' => sub {
    _setup();

    my $username = 'test_user';

    my $c = _build_c(
        username => $username,
        req      => { params => { topic_mid => '1234' } }
    );

    my $controller = _build_controller();
    $controller->file_tree($c);

    cmp_deeply $c->stash,
        {
        json => {
            success => \0,
            msg     => re(qr/filter param is required/),
        }
        };
};

subtest 'file_tree: returns true and empty data structure if no params passed' => sub {
    _setup();

    my $username = 'test_user';

    my $c = _build_c(
        username => $username,
        req      => { params => {} }
    );

    my $controller = _build_controller();
    $controller->file_tree($c);

    my @data;

    cmp_deeply $c->stash,
        {
        json => {
            success => \1,
            total   => 0,
            data    => \@data
        }
        };
};

subtest 'file_tree: returns file data tree structure without directory' => sub {
    _setup();

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username  = ci->user->find_one()->{name};
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $c         = _build_c(
        username => $username,
        req      => {
            params => {
                extension => 'txt',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.txt',
                #fullpath  => $file->dir . "/filename.txt"
            },
            body => $file->stringify
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    my $asset_mid = ci->asset->find_one()->{mid};
    my $asset = ci->new($asset_mid);
    my ( $size, $unit ) = Util->_size_unit( $asset->filesize );
    $size = "$size $unit";

    my @asset;
    push @asset, $asset->{mid};

    $c = _build_c(
        username => $username,
        req      => { params => { files_mid => \@asset } }
    );

    $controller->file_tree($c);

    cmp_deeply $c->stash,
        {
        json => {
            success => \1,
            total   => 1,
            data    => [
                { mid => $asset->mid, _id => $asset->mid, _parent => undef, filename => $asset->name, versionid => 1, size => $size, path => '/', _is_leaf => \1 }
            ]
        }
        };
};

subtest 'file_tree: returns file data tree structure with directory when it pass files_mid' => sub {
    _setup();

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username  = ci->user->find_one()->{name};
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $c         = _build_c(
        username => $username,
        req      => {
            params => {
                extension => 'txt',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.txt',
                fullpath  => "/directory/filename.txt"
            },
            body => $file->stringify
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    my $asset_mid = ci->asset->find_one()->{mid};
    my $asset = ci->new($asset_mid);
    my ( $size, $unit ) = Util->_size_unit( $asset->filesize );
    $size = "$size $unit";

    my @asset;
    push @asset, $asset->{mid};

    $c = _build_c(
        username => $username,
        req      => { params => { files_mid => \@asset } }
    );

    $controller->file_tree($c);

    cmp_deeply $c->stash,
        {
        json => {
            success => \1,
            total   => 1,
            data    => [
                { mid => $asset->mid, _id => $asset->mid, _parent => ignore(), filename => $asset->name, versionid => 1, size => $size, path => '/directory', _is_leaf => \1 },
                { mid => undef, _id => ignore(), _parent => undef, filename => 'directory', versionid => undef, size => undef, path => '', _is_leaf => \0 }
            ]
        }
        };
};

subtest 'file_tree: returns file data tree structure with directory when it pass topic_mid and filter' => sub {
    _setup();

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username  = ci->user->find_one()->{name};
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $c         = _build_c(
        username => $username,
        req      => {
            params => {
                extension => 'txt',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.txt',
                fullpath  => "/directory/filename.txt"
            },
            body => $file->stringify
        }
    );

    my $controller = _build_controller();
    $controller->upload($c);
    my $asset_mid = ci->asset->find_one()->{mid};
    my $asset = ci->new($asset_mid);
    my ( $size, $unit ) = Util->_size_unit( $asset->filesize );
    $size = "$size $unit";

    my @asset;
    push @asset, $asset->{mid};

    $c = _build_c(
        username => $username,
        req      => { params => { topic_mid => $topic_mid, filter => 'test_file' } }
    );

    $controller->file_tree($c);

    cmp_deeply $c->stash,
        {
        json => {
            success => \1,
            total   => 1,
            data    => [
                { mid => $asset->mid, _id => $asset->mid, _parent => ignore(), filename => $asset->name, versionid => 1, size => $size, path => '/directory', _is_leaf => \1 },
                { mid => undef, _id => ignore(), _parent => undef, filename => 'directory', versionid => undef, size => undef, path => '', _is_leaf => \0 }
            ]
        }
        };
};

subtest 'is_valid_extension: returns false, not allowed extension' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => '.zip',
        filename => 'filename.jpg'
    );
    is $result, 0;

};

subtest 'is_valid_extension: returns false, file without extension is not  allowed' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => 'txt .jlc .tar.gz tgz .foo.jpg.baz',
        filename => 'filename'
    );
    is $result, 0;

};

subtest 'is_valid_extension: returns true, accepts extension list with spaces' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => '.sql txt .jpg, TXT',
        filename => 'filename.jpg'
    );
    ok $result;

};

subtest 'is_valid_extension: returns true, accepts extension list with dots' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => '.sql,.txt,.JPG,.PDF',
        filename => 'filename.jpg'
    );
    ok $result, 'extension valid, list filter with dots';

};

subtest 'is_valid_extension: returns true, correctly checks double extensions' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => 'txt .jpg .tar.gz tgz .foo.bar.baz',
        filename => 'filename.tar.gz'
    );
    ok $result;

};

subtest 'is_valid_extension: returns false, correctly checks double extensions and the file have one' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => 'txt .jpg .tar.gz tgz .foo.bar.baz',
        filename => 'filename.tar'
    );
    is $result, 0;

};

subtest 'is_valid_extension: returns false, does not check extension when none specified' => sub {
    my $controller = _build_controller();
    my $result     = $controller->is_valid_extension(
        filter   => '',
        filename => 'filename.tar.gz'
    );
    ok $result;

};

subtest 'remove_file: croaks when topic mid not found' => sub {
    _setup();

    my $c          = _build_c();
    my $controller = _build_controller();

    like exception { $controller->remove_file($c) }, qr/topic mid required/;
};

subtest 'remove_file: checks json when asset mid not found' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic();

    my $c = _build_c(
        req => {
            params => {
                asset_mid => 'asset-1',
                topic_mid => $topic_mid
            }
        }
    );
    my $controller = _build_controller();

    $controller->remove_file($c);
    cmp_deeply $c->stash, { json => { success => \0, msg => re(qr/File id asset-1 not found/) } };
};

subtest 'remove_file: checks json when the file is removed by asset_mid' => sub {
    _setup();

    my $model_topic = Baseliner::Model::Topic->new;
    my $file = TestUtils->create_temp_file( filename =>'filename.txt' );
    my $topic_mid   = TestSetup->_create_topic( title => 'my topic' );
    my $username = ci->user->find_one()->{name};

    $model_topic->upload( file => $file, topic_mid => $topic_mid, filename => 'filename.txt', filter => 'test_file', username => $username, fullpath => '' );

    my $asset = ci->asset->find_one;

    my $c = _build_c(
        req => {
            params => {
                asset_mid => $asset->{mid},
                topic_mid => $topic_mid
            },
            username => 'root'
        }
    );
    my $controller = _build_controller();
    $controller->remove_file($c);

    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Deleted files from topic $topic_mid/) } };
};

subtest 'remove_file: checks json when the file is removed by fields' => sub {
    _setup();

    my $model_topic = Baseliner::Model::Topic->new;
    my $file = TestUtils->create_temp_file( filename =>'filename.txt' );
    my $topic_mid   = TestSetup->_create_topic( title => 'my topic' );
    my $username = ci->user->find_one()->{name};

    $model_topic->upload( file => $file, topic_mid => $topic_mid, filename => 'filename.txt', filter => 'test_file', username => $username, fullpath => '' );

    my $asset = ci->asset->find_one;

    my $c = _build_c(
        req => {
            params => {
                asset_mid => [],
                topic_mid => $topic_mid,
                fields    => 'test_file'
            },
            username => 'root'
        }
    );
    my $controller = _build_controller();
    $controller->remove_file($c);

    $asset = ci->asset->find_one;

    is $asset, undef;
    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Deleted files from topic $topic_mid/) } };
};

subtest 'list_users: doesnt fail if role is not found and returns 0' => sub {
    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                roles => 'TestRole'
            }
        }
    );
    $c->{username} = 'root';    # change context to root
    $controller->list_users($c);
    my $stash = $c->stash;

    cmp_deeply $stash, { json => { totalCount => 0, data => [] } };
};

subtest 'list_users: returns users by roles' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci_project;
    my $id_role    = TestSetup->create_role( role => 'TestRole' );
    my $id_role2   = TestSetup->create_role( role => 'TestRole2' );

    my $user = TestSetup->create_user(
        username => 'test_user',
        realname => 'Test User',
        id_role  => $id_role,
        project  => $project
    );
    my $user2 = TestSetup->create_user(
        username => 'test_user2',
        realname => 'Test User2',
        id_role  => $id_role,
        project  => $project
    );
    my $user3 = TestSetup->create_user(
        username => 'test_user3',
        realname => 'Test User3',
        id_role  => $id_role2,
        project  => $project
    );

    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                roles => $id_role
            }
        }
    );

    $controller->list_users($c);

    cmp_deeply $c->stash,
      {
        json => {
            totalCount => 2,
            data       => [
                { id => ignore(), realname => 'Test User',  username => 'test_user' },
                { id => ignore(), realname => 'Test User2', username => 'test_user2' },
            ]
        }
      };
};

subtest 'list_users: returns users by roles and topic projects' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci_project;
    my $project2   = TestUtils->create_ci_project;
    my $id_role    = TestSetup->create_role( role => 'TestRole' );
    my $id_role2   = TestSetup->create_role( role => 'TestRole2' );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $user = TestSetup->create_user(
        username => 'developer',
        realname => 'Test User',
        id_role  => $id_role,
        project  => $project
    );
    my $user2 = TestSetup->create_user(
        username => 'developer2',
        realname => 'Test User2',
        id_role  => $id_role,
        project  => $project2
    );
    my $user3 = TestSetup->create_user(
        username => 'developer3',
        realname => 'Test User3',
        id_role  => $id_role2,
        project  => $project2
    );

    my $topic_mid = TestSetup->create_topic( id_category => $id_changeset_category, id_role => $id_role, project => $project );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                roles => $id_role
            }
        }
    );

    $controller->list_users($c);

    cmp_deeply $c->stash,
      {
        json => {
            totalCount => 2,
            data       => [
                { id => ignore(), realname => 'Test User',  username => $user->username },
                { id => ignore(), realname => 'Test User2', username => $user2->username },
            ]
        }
      };
};

subtest 'list_users: returns users by projects' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci_project;
    my $project2   = TestUtils->create_ci_project;
    my $project3   = TestUtils->create_ci_project;
    my $id_role    = TestSetup->create_role( role => 'TestRole' );

    my $user = TestSetup->create_user(
        username => 'test_user',
        realname => 'Test User',
        id_role  => $id_role,
        project  => $project
    );
    my $user2 = TestSetup->create_user(
        username => 'test_user2',
        realname => 'Test User2',
        id_role  => $id_role,
        project  => $project2
    );
    my $user3 = TestSetup->create_user(
        username => 'test_user3',
        realname => 'Test User3',
        id_role  => $id_role,
        project  => $project3
    );

    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                projects => [ $project->mid, $project2->mid ]
            }
        }
    );

    $controller->list_users($c);

    cmp_deeply $c->stash,
      {
        json => {
            totalCount => 2,
            data       => [
                { id => ignore(), realname => 'Test User',  username => 'test_user' },
                { id => ignore(), realname => 'Test User2', username => 'test_user2' },
            ]
        }
      };
};

subtest 'list_users: returns users filtered by query' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci_project;
    my $id_role    = TestSetup->create_role( role => 'TestRole' );

    my $user = TestSetup->create_user(
        username => 'bill',
        realname => 'Bill',
        id_role  => $id_role,
        project  => $project
    );
    my $user2 = TestSetup->create_user(
        username => 'harry',
        realname => 'Harry',
        id_role  => $id_role,
        project  => $project
    );
    my $user3 = TestSetup->create_user(
        username => 'john',
        realname => 'John',
        id_role  => $id_role,
        project  => $project
    );

    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                roles => $id_role,
                query => 'h'
            }
        }
    );

    $controller->list_users($c);

    cmp_deeply $c->stash,
      {
        json => {
            totalCount => 2,
            data       => [
                { id => ignore(), realname => 'Harry', username => 'harry' },
                { id => ignore(), realname => 'John',  username => 'john' },
            ]
        }
      };
};

subtest 'list_users: returns users paged' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci_project;
    my $id_role    = TestSetup->create_role( role => 'TestRole' );

    my $user = TestSetup->create_user(
        username => 'bill',
        realname => 'Bill',
        id_role  => $id_role,
        project  => $project
    );
    my $user2 = TestSetup->create_user(
        username => 'harry',
        realname => 'Harry',
        id_role  => $id_role,
        project  => $project
    );
    my $user3 = TestSetup->create_user(
        username => 'john',
        realname => 'John',
        id_role  => $id_role,
        project  => $project
    );

    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                roles => $id_role,
                start => 1,
                limit => 1,
            }
        }
    );

    $controller->list_users($c);

    cmp_deeply $c->stash,
      {
        json => {
            totalCount => 1,
            data       => [ { id => ignore(), realname => 'Harry', username => 'harry' }, ]
        }
      };
};

subtest 'topic_selector: sort topics on filed asc' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => 1,
                sort_field       => "title",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    is $c->stash->{json}->{data}->[0]->{title}, 'A_name';
    is $c->stash->{json}->{data}->[1]->{title}, 'B_name';
    is $c->stash->{json}->{data}->[2]->{title}, 'C_name';
    is $c->stash->{json}->{data}->[3]->{title}, 'Z_name';
};

subtest 'topic_selector: sort topics on filed desc' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => -1,
                sort_field       => "title",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    is $c->stash->{json}->{data}->[0]->{title}, 'Z_name';
    is $c->stash->{json}->{data}->[1]->{title}, 'C_name';
    is $c->stash->{json}->{data}->[2]->{title}, 'B_name';
    is $c->stash->{json}->{data}->[3]->{title}, 'A_name';
};

subtest 'topic_selector: sort topics on filed desc' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => -1,
                sort_field       => "title",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    is $c->stash->{json}->{data}->[0]->{title}, 'Z_name';
    is $c->stash->{json}->{data}->[1]->{title}, 'C_name';
    is $c->stash->{json}->{data}->[2]->{title}, 'B_name';
    is $c->stash->{json}->{data}->[3]->{title}, 'A_name';
};

subtest 'topic_selector: must operate when sort field is not specified' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => '',
                sort_field       => "",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    cmp_deeply $c->stash, { json => { totalCount => '4', data => ignore() } };
};

subtest 'topic_selector: must operate when sort field do not exist' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => 1,
                sort_field       => "tttt",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    cmp_deeply $c->stash, { json => { totalCount => '4', data => ignore() } };
};


subtest 'topic_selector: sort by mid asc' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => 1,
                sort_field       => "mid",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    is $c->stash->{json}->{data}->[0]->{title}, 'A_name';
    is $c->stash->{json}->{data}->[1]->{title}, 'Z_name';
    is $c->stash->{json}->{data}->[2]->{title}, 'B_name';
    is $c->stash->{json}->{data}->[3]->{title}, 'C_name';
};


subtest 'topic_selector: sort by mid desc' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => -1,
                sort_field       => "mid",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    is $c->stash->{json}->{data}->[0]->{title}, 'C_name';
    is $c->stash->{json}->{data}->[1]->{title}, 'B_name';
    is $c->stash->{json}->{data}->[2]->{title}, 'Z_name';
    is $c->stash->{json}->{data}->[3]->{title}, 'A_name';
};

subtest 'topic_selector: must operate when sort order is not specified or is wrong' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'A_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Z_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'B_name',
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'C_name',
        status      => $status
    );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                dir              => 0,
                sort_field       => "",
                filter           => "",
                limit            => "20",
                mid              => "1",
                query            => "",
                show_release     => "0",
                start            => "0",
                topic_child_data => "true",
                valuesqry        => ""
            }
        }
    );

    $controller->related($c);

    cmp_deeply $c->stash, { json => { totalCount => '4', data => ignore() } };
};

sub _create_topic_selector_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            }
        ],
    );
}

subtest 'get_menu_deploy: build menu deploy in topic view' => sub {
    _setup();

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');
    my $project = TestUtils->create_ci_project( bls => [ $bl->mid ] );

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status1 = TestUtils->create_ci( 'status', name => 'Deploy', type => 'D', bls => [ $bl->mid ] );

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project => $project,
        status => $status,
        username => $user->username,
        id_category => $id_changeset_category,
        title  => "Topic"
    );

    my $workflow = [ { id_role => $id_role, id_status_from => $status->mid, id_status_to => $status1->mid, job_type => 'promote' } ];
    mdb->category->update( { id => "$id_changeset_category" }, { '$set' => { workflow => $workflow }, '$push' => { statuses => $status1->mid } } );

    my $controller = _build_controller();
    my $menu = $controller->get_menu_deploy( { topic_mid => $topic_mid, username => $user->username } );

    cmp_deeply $menu,
      {
        demotable => ignore(),
        deployable => ignore(),
        menu => [{
            eval => {
                bl_to => $bl->bl,
                id => ignore(),
                id_project => ignore(),
                is_release => ignore(),
                job_type => 'promote',
                status_to => $status1->mid,
                status_to_name => $status1->name,
                title => 'To Promote',
                url => '/comp/lifecycle/deploy.js',
            },
            icon => "/static/images/icons/arrow_down_short.svg",
            id_status_from => $status->mid,
            text => ignore(),
        }],
        promotable => ignore(),
      };
};

subtest 'update: new topics have menu_deploy in stash' => sub {
    _setup();
    TestSetup->_setup_user();

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');
    my $project = TestUtils->create_ci_project( bls => [ $bl->mid ] );

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status1 = TestUtils->create_ci( 'status', name => 'Deploy', type => 'D', bls => [ $bl->mid ] );

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid, is_changeset => 1 );

    my $topic_mid = TestSetup->create_topic(
        status => $status,
        id_category => $id_changeset_category,
        title  => "Topic"
    );

    my $workflow = [ { id_role => $id_role, id_status_from => $status->mid, id_status_to => $status1->mid, job_type => 'promote' } ];
    mdb->category->update( { id => "$id_changeset_category" }, { '$set' => { workflow => $workflow }, '$push' => { statuses => $status1->mid } } );

    my $controller = _build_controller();
    my $c           = _build_c(
        req => {
            params => {
                new_category_id   => $id_changeset_category,
                new_category_name => 'Changeset',
                topic_mid => $topic_mid,
            }
        }
    );
    $c->{username} = 'root';    # change context to root
    $controller->view($c);

    my $stash = $c->stash;

    ok exists $stash->{menu_deploy};    # this only shows up in case of failure
};

subtest 'view: strips html from fields' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $id_changeset_rule = _create_changeset_form(
        rule_tree => [
            {
                "attributes" => {
                    data => {
                        id_field => 'project',
                    },
                    key  => "fieldlet.system.projects",
                    name => 'Project',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "description",
                    },
                    "key" => "fieldlet.system.description",
                    name  => 'Description',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "content",
                    },
                    "key" => "fieldlet.html_editor",
                    name  => 'Content',
                }
            },
        ]
    );
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_changeset_rule,
        id_status    => $status->mid,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_changeset_category}]
            },
            {
                action => 'action.topicsfield.read',
                bounds => [
                    {id_category => $id_changeset_category, id_status => $status->id_status, id_field => 'description'},
                    {id_category => $id_changeset_category, id_status => $status->id_status, id_field => 'content'},
                ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        status      => $status,
        id_category => $id_changeset_category,
        title       => "Topic",
        description => 'Hello <script>alert("hi")</script>there!',
        content     => 'Bye, <script>alert("hi")</script>bye!',
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 1
            }
        }
    );
    $controller->view($c);

    my $stash = $c->stash;

    my $topic_data = $stash->{topic_data};

    is $topic_data->{description}, 'Hello there!';
    is $topic_data->{content},     'Bye, bye!';
};

subtest 'view: sets correct category name/color' => sub {
    _setup();

    my $bl = TestUtils->create_ci( 'bl', name => 'TEST', bl => 'TEST', moniker => 'TEST' );
    my $project = TestUtils->create_ci_project( bls => [ $bl->mid ] );

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $id_changeset_rule = _create_changeset_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "bd_field"     => "description",
                        "fieldletType" => "fieldlet.system.description",
                        "id_field"     => "description",
                    },
                    "key" => "fieldlet.system.description",
                    name  => 'Description',
                }
            },
            {   "attributes" => {
                    "data" => {
                        "bd_field"     => "content",
                        "fieldletType" => "fieldlet.html_editor",
                        "id_field"     => "content",
                    },
                    "key" => "fieldlet.html_editor",
                    name  => 'Content',
                }
            },
        ]
    );
    my $id_changeset_category = TestSetup->create_category(
        name         => 'user_story',
        id_rule      => $id_changeset_rule,
        color        => '#FF0000',
        id_status    => $status->mid,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    {
                        id_category => $id_changeset_category
                    }
                ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        status      => $status,
        id_category => $id_changeset_category,
        title       => "Topic",
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 0
            }
        }
    );
    $controller->view($c);

    my $stash = $c->stash;

    is $stash->{category_color}, '#FF0000';
    is $stash->{category_name},  'user_story';
};

subtest 'check_modified_on: check topic was modified before' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = mock_time '2016-01-01 00:05:00' => sub { TestSetup->create_topic(username => $user->username) };

    my $modified = '2016-01-01 00:00:00';

    my $c =
      _build_c( req => { params => { topic_mid => $topic_mid, modified => $modified, rel_signature => '' } } );

    my $controller = _build_controller();

    $controller->check_modified_on($c);

    cmp_deeply(
        $c->stash->{json},
        {
            'success'                  => \1,
            'modified_before_duration' => "5m 0s",
            'modified_rel'             => ignore(),
            'modified_before'          => $user->username,
            'msg'                      => "Test"
        }
    );
};

subtest 'check_modified_on: check topic was not modified before' => sub {
    _setup();

    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $controller = _build_controller();

    my $modified  = Class::Date->now() + '5m';
    my $signature = '';

    my $c =
      _build_c( req => { params => { topic_mid => $topic_mid, modified => $modified, rel_signature => $signature } } );
    $controller->check_modified_on($c);
    cmp_deeply(
        $c->stash->{json},
        {
            'success'                  => \1,
            'modified_before_duration' => undef,
            'modified_rel'             => ignore(),
            'modified_before'          => \0,
            'msg'                      => "Test"
        }
    );
};

subtest 'list_users: returns users by id roles' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci_project;
    my $id_role    = TestSetup->create_role( role => 'TestRole', id => '21' );
    my $id_role2   = TestSetup->create_role( role => 'TestRole2', id => '22' );
    my $id_role3   = TestSetup->create_role( role => 'TestRole3', id => '23' );

    my $user = TestSetup->create_user(
        username => 'test_user',
        realname => 'Test User',
        id_role  => '21',
        project  => $project
    );
    my $user2 = TestSetup->create_user(
        username => 'test_user2',
        realname => 'Test User2',
        id_role  => '22',
        project  => $project
    );
    my $user3 = TestSetup->create_user(
        username => 'test_user3',
        realname => 'Test User3',
        id_role  => '23',
        project  => $project
    );


    my $c = _build_c(
        username => 'test_user',
        req      => {
            params => {
                roles => ['21', '22']
            }
        }
    );

    $controller->list_users($c);

    cmp_deeply $c->stash,
      {
        json => {
            totalCount => ignore(),
            data       => [
                { id => ignore(), realname => 'Test User',  username => 'test_user' },
                { id => ignore(), realname => 'Test User2', username => 'test_user2' },
            ]
        }
      };
};

subtest 'report_csv: returns the list of the dashlet in serve_body' => sub {
    _setup();

    my $controller = _build_controller();

    my $data = {
        rows    => [ { name => 'FT #2122' } ],
        columns => [
            {   id   => "name",
                name => "ID"
            }
        ]
    };
    $data = _encode_json($data);

    my $c = _build_c( req => { params => { data_json => $data } } );

    $controller->report_csv($c);

    is_string $c->stash->{serve_body}, "\xEF\xBB\xBF" . qq{"ID"\n} . qq{"FT #2122"\n} . ( "\n" x 1006 );
};

subtest 'view: returns topic data' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_changeset_category}]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 1
            }
        }
    );
    $controller->view($c);

    ok $c->stash->{topic_data};
    ok $c->stash->{topic_meta};
};

subtest 'view: returns topic with category permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 0
            }
        }
    );
    $controller->view($c);

    ok !$c->stash->{permissionEdit};
    ok !$c->stash->{permissionDelete};
};

subtest 'view: denies view of topic not allowed by project security' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_changeset_category}]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project2
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 0
            }
        }
    );
    $controller->view($c);

    cmp_deeply $c->stash->{json}, {
        success => \0,
        msg => re(qr/User developer is not allowed to access topic/)
    };
};

subtest 'view: allows users with action to see job monitor to see it' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_changeset_category}]
            },
            {
                action => 'action.topics.jobs',
                bounds => [{id_category => $id_changeset_category}]
            },
            {
                action => 'action.job.view_monitor'
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 0
            }
        }
    );
    $controller->view($c);

    my $stash = $c->stash;

    is $stash->{permissionJobsLink}, '1';
    is $stash->{permissionJobs},  '1';
};

subtest 'view: does not allow users without action to see job monitor to see it' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_changeset_category}]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                html      => 0
            }
        }
    );
    $controller->view($c);

    my $stash = $c->stash;

    is $stash->{permissionJobsLink}, '0';
    is $stash->{permissionJobs},  '0';
};

subtest 'category_list: returns the category that is of type release' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category( is_release => '1' );
    my $category_3 = TestSetup->create_category();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { is_release => '1' } }
    );

    my $controller = _build_controller();
    $controller->category_list($c);

    is $c->stash->{json}->{data}[0]->{id}, $category_2;
    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'category_list: returns empty if not exist categories of type release' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { is_release => '1' } }
    );

    my $controller = _build_controller();
    $controller->category_list($c);

    is $c->stash->{json}->{totalCount}, 0;
};

subtest 'category_list: returns all the categories if is_release = 0' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $c = _build_c(
        username => $user->username,
        req      => { params => { is_release => '0' } }
    );

    my $controller = _build_controller();
    $controller->category_list($c);

    is $c->stash->{json}->{totalCount}, 3;
};

subtest 'category_list: returns all categories' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $c = _build_c( username => $user->username );

    my $controller = _build_controller();
    $controller->category_list($c);

    is $c->stash->{json}->{totalCount}, 3;
};

subtest 'filters_list: returns labels ordered by priority' => sub {
    _setup();
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );
    my $label_id  = TestSetup->create_label( name => "MyLabel",  priority => 4 );
    my $label_id2 = TestSetup->create_label( name => "MyLabel2", priority => 3 );
    my $label_id3 = TestSetup->create_label( name => "MyLabel3", priority => 5 );
    my $label_id4 = TestSetup->create_label( name => "MyLabel4", priority => 1 );
    my $label_id5 = TestSetup->create_label( name => "MyLabel5", priority => 2 );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
    );

    $controller->filters_list($c);

    my ($labels) = grep { $_->{text} eq 'Labels' } @{ $c->stash->{json} };
    my $priority = $labels->{children};

    is $priority->[0]->{priority}, 5;
    is $priority->[1]->{priority}, 4;
    is $priority->[2]->{priority}, 3;
    is $priority->[3]->{priority}, 2;
    is $priority->[4]->{priority}, 1;
};

subtest 'report_csv: returns label name without id and color' => sub {
    _setup();

    my $controller = _build_controller();

    my $data = {
        rows    => [ { labels => '12;MyLabel;#FFFFF'}],
        columns => [
            {   id   => "labels",
                name => "labels",
            }
        ]
    };
    $data = _encode_json($data);

    my $c = _build_c( req => { params => { data_json => $data } } );

    $controller->report_csv($c);
    my $serve_body = $c->stash->{serve_body};

    like $serve_body, qr/MyLabel/;
    unlike $serve_body, qr/12;MyLabel;#FFFFF/;
};

subtest 'generate_menus: generates empty menu' => sub {
    _setup();

    my $controller = _build_controller();

    my $menus = $controller->generate_menus;

    cmp_deeply $menus,
      {
        'menu.topic' => {
            'label'   => 'Topics',
            'title'   => 'Topics',
            'actions' => [ 'action.topics.%' ]
        },
        'menu.topic.topics' => {
            'index'     => 1,
            'title'     => 'Topics',
            'icon'      => ignore(),
            'tab_icon'  => ignore(),
            'actions'   => [ 'action.topics.%' ],
            'comp_data' => {
                'tabTopic_force' => 1
            },
            'url_comp' => '/topic/grid',
            'label'    => 'All'
        },
        'menu.topic._sep_' => {
            'separator' => 1,
            'index'     => 3
        },
      };
};

subtest 'generate_menus: generates view topics menu for user' => sub {
    _setup();

    my $id_category = TestSetup->create_category(name => 'Category');

    my $controller = _build_controller();

    my $menus = $controller->generate_menus;

    cmp_deeply $menus->{'menu.topic.category'}, {
        'actions' => [
            {
                'bounds' => {
                    'id_category' => $id_category
                },
                'action' => 'action.topics.view'
            }
        ],
        'index'    => 10,
        'label'    => re(qr/Category/),
        'title'    => re(qr/Category/),
        'tab_icon' => ignore(),
        'url_comp' => '/topic/grid?category_id=' . $id_category
    };
};

subtest 'generate_menus: generates create topics menu for user' => sub {
    _setup();

    my $id_category = TestSetup->create_category(name => 'Category');

    my $controller = _build_controller();

    my $menus = $controller->generate_menus;

    cmp_deeply $menus->{'menu.topic.create'},
      {
        'label'   => 'Create',
        'icon'    => ignore(),
        'index'   => 2,
        'actions' => [
            {
                'action' => 'action.topics.create',
                'bounds' => '*'
            }
        ]
      };

    cmp_deeply $menus->{'menu.topic.create.category'},
      {
        'tab_icon'  => ignore(),
        'comp_data' => {
            'new_category_id'   => $id_category,
            'new_category_name' => 'Category',
            'swEdit'=>'1'
        },
        'label' => re(qr/Category/),
        'index'    => 11,
        'url_comp' => '/topic/view',
        'actions'  => [
            {
                'bounds' => {
                    'id_category' => $id_category
                },
                'action' => 'action.topics.create'
            }
        ]
      };
};

subtest 'generate_menus: generates view by status menu for user' => sub {
    _setup();

    my $status = TestUtils->create_ci('status', name => 'New');

    my $controller = _build_controller();

    my $menus = $controller->generate_menus;

    cmp_deeply $menus->{'menu.topic.status'},
      {
        'index' => 2,
        'icon'  => ignore(),
        'label' => 'Status'
      };

    cmp_deeply $menus->{'menu.topic.status.new'},
      {
        'url_comp'    => '/topic/grid?status_id=' . $status->id_status,
        'title'       => re(qr/New/),
        'hideOnClick' => 0,
        'tab_icon'    => ignore(),
        'label'       => re(qr/New/),
        'index'       => 10,
        'icon'        => ignore(),
      };
};

subtest 'topic_fieldlet_nodes: returns fieldlets of a form' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset_mid = TestSetup->create_topic( project => $project );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, );

    $controller->topic_fieldlet_nodes($c);

    my $fieldlets = $c->stash->{json}->{data};
    my @check_fieldlets = grep { $_->{key} =~ /fieldlet/ } @{$fieldlets};

    is( scalar @{$fieldlets}, scalar @check_fieldlets );
};

subtest 'get_category_default_workflow: fails if no parameters' => sub {
    _setup();

    my $c          = _build_c();
    my $controller = _build_controller();

    like exception { $controller->get_category_default_workflow($c) }, qr/Missing category_id/;
};

subtest 'get_category_default_workflow: returns undef if category no exists' => sub {
    _setup();

    my $c = _build_c( req => { params => { id_category => '123' } } );
    my $controller = _build_controller();

    $controller->get_category_default_workflow($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Default workflow rule for category 123",
            'data'    => undef,
            'success' => \1
        }
      };
};


subtest 'get_category_default_workflow: returns undef if no default_workflow configured' => sub {
    _setup();

    my $id_category = TestSetup->create_category();
    my $c           = _build_c( req => { params => { id_category => $id_category } } );
    my $controller  = _build_controller();

    $controller->get_category_default_workflow($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Default workflow rule for category $id_category",
            'data'    => undef,
            'success' => \1
        }
      };
};


subtest 'get_category_default_workflow: returns workflow rule_id' => sub {
    _setup();

    my $id_rule     = TestSetup->create_rule();
    my $id_category = TestSetup->create_category( default_workflow => $id_rule );
    my $c           = _build_c( req => { params => { id_category => $id_category } } );
    my $controller  = _build_controller();

    $controller->get_category_default_workflow($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => "Default workflow rule for category $id_category",
            'data'    => $id_rule,
            'success' => \1
        }
      };
};


done_testing;

sub _create_user_with_drop_rules {
    my (%params) = @_;

    my $id_changeset_category = delete $params{id_changeset_category};
    my $id_release_category   = delete $params{id_release_category};
    my $id_sprint_category    = delete $params{id_sprint_category};
    my $id_status             = delete $params{id_status};

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category }, { id_category => $id_release_category } ],
            },
            {
                action => 'action.topicsfield.write',
                bounds => [
                    { id_category => $id_changeset_category, id_status => $id_status, id_field => 'release' },
                    { id_category => $id_changeset_category, id_status => $id_status, id_field => 'sprint' },
                    { id_category => $id_release_category,   id_status => $id_status, id_field => 'changesets' },
                    { id_category => $id_sprint_category,    id_status => $id_status, id_field => 'changesets' },
                ],
            },
        ]
    );

    return TestSetup->create_user( id_role => $id_role, %params );
}

sub _create_changeset_form {
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    data => {
                        id_field => 'project',
                    },
                    key  => "fieldlet.system.projects",
                    name => 'Project',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            $params{with_sprint}
            ? (
                {
                    "attributes" => {
                        "data" => {
                            id_field      => 'sprint',
                            release_field => 'changesets'
                        },
                        "key" => "fieldlet.system.release",
                        name  => 'Sprint',
                    }
                }
              )
            : (),
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'release',
                        release_field => 'changesets',
                        %{ $params{release} || {} }
                    },
                    "key" => "fieldlet.system.release",
                    name  => 'Release',
                }
            },
            @{$params{rule_tree} || []}
        ],
    );
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
}

sub _create_sprint_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
}

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_controller {
    Baseliner::Controller::Topic->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Job',
        'BaselinerX::Fieldlets',
        'BaselinerX::LcController',
        'BaselinerX::Service::TopicServices',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Menu',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Registor',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Model::ConfigStore',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Label',
        'Baseliner::Model::TopicExporter',
        'Baseliner::Controller::Topic',
        'Baseliner::Controller::TopicAdmin',
    );
    TestUtils->cleanup_cis;

    mdb->topic->drop;
    mdb->category->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->topic->drop;
    mdb->event->drop;
    mdb->label->drop;
    mdb->user->drop;
}
