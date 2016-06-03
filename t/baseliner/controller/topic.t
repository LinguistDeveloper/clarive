use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst mock_time);
use TestSetup;

use POSIX ":sys_wait_h";
use Baseliner::Role::CI;
use Baseliner::Model::Topic;
use Baseliner::RuleFuncs;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Fieldlets;
use Baseliner::Queue;

use Baseliner::Model::Topic;
use Clarive::mdb;
use Class::Date;

use_ok 'Baseliner::Controller::Topic';

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

subtest 'add label to topic' => sub {
    _setup();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $label_id = TestSetup->_setup_label;

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid => $topic_mid, label_ids => ["$label_id"] } } );
    $c->{username} = 'root';    # change context to root
    $controller->update_topic_labels($c);
    cmp_deeply( $c->stash, { json => { msg => 'Labels assigned', success => \1 } } );
    is_deeply( mdb->topic->find_one( { mid => "$topic_mid" } )->{labels}, [$label_id] );
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

    is $c->stash->{json}->{data}[0]->{category}, $category_1;
    is $c->stash->{json}->{data}[1]->{category}, $category_3;
    is $c->stash->{json}->{totalCount}, 2;
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

    mdb->role->insert(
        {   id      => '1',
            actions => [ { action => 'action.topics.category.view' } ],
            role    => 'Developer'
        }
    );

    TestUtils->create_ci(
        'user',
        name             => 'developer',
        username         => 'developer',
        project_security => { '1' => { project => [ $project->mid ] } }
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();

    my @category_name = map { $_->{name} }
        mdb->category->find( { id => mdb->in( $category_1, $category_2 ) } )->fields( { name => 1 } )->all;
    my $c = _build_c(
        username => 'developer',
        req      => { params => { action => 'view' } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{data}[0]->{category}, $category_1;
    is $c->stash->{json}->{data}[1]->{category}, $category_2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'list_category: do not return categories when user not has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    mdb->role->insert(
        {   id      => '1',
            actions => [ { action => 'action.topics.category.view' } ],
            role    => 'Developer'
        }
    );

    TestUtils->create_ci(
        'user',
        name             => 'developer',
        username         => 'developer',
        project_security => { '1' => { project => [ $project->mid ] } }
    );

    my $category_1 = TestSetup->create_category();
    my $category_2 = TestSetup->create_category();

    my @category_name = map { $_->{name} }
        mdb->category->find( { id => mdb->in( $category_1, $category_2 ) } )->fields( { name => 1 } )->all;
    my $c = _build_c(
        username => 'developer',
        req      => { params => { action => 'create' } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{totalCount}, 0;
};

subtest 'list_category: return just categories that have permission to return' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    mdb->role->insert(
        {   id      => '1',
            actions => [ { action => 'action.topics.category_1.create' } ],
            role    => 'Developer'
        }
    );

    TestUtils->create_ci(
        'user',
        name             => 'developer',
        username         => 'developer',
        project_security => { '1' => { project => [ $project->mid ] } }
    );

    my $category_1 = TestSetup->create_category(name => 'category_1' );
    my $category_2 = TestSetup->create_category();
    my $category_3 = TestSetup->create_category();

    my $c = _build_c(
        username => 'developer',
        req      => { params => { categories_id_filter => [ $category_1, $category_3 ] } }
    );

    my $controller = _build_controller();

    $controller->list_category($c);

    is $c->stash->{json}->{data}[0]->{category}, $category_1;
    is $c->stash->{json}->{totalCount}, 1;
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
    my $user    = _create_user_with_drop_rules( project => $project );

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

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
    my $user    = _create_user_with_drop_rules( project => $project );

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

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
    my $user    = _create_user_with_drop_rules( project => $project );

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

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
    my $user    = _create_user_with_drop_rules( project => $project );

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

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
    my $user    = _create_user_with_drop_rules( project => $project );

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

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
    my $user    = _create_user_with_drop_rules( project => $project );

    my $id_changeset_rule = _create_changeset_form( release => { value_type => 'single' }, with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_release_rule = _create_release_form();
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

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

subtest 'upload: uploads file to topic' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => { extension => 'jpg', topic_mid => $topic_mid, filter => 'test_file', qqfile => 'filename.jpg' },
            body => "$tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Uploaded file filename.jpg/) } };
};

subtest 'upload: fails to upload not allowed extension' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );
    my $c = _build_c(
        username => $user->username,
        req      => {
            params =>
              { extension => 'sql,txt', topic_mid => $topic_mid, filter => 'test_file', qqfile => 'filename.jpg' },
            body => "$tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => { success => \0, msg => re(qr/This type of file is not allowed: jpg/) } };
};

subtest 'upload: file without extension is not  allowed' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params =>
              { extension => 'sql,txt,JPG,PDF', topic_mid => $topic_mid, filter => 'test_file', qqfile => 'filename' },
            body => "$tempdir/filename"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash,
      { json => { success => \0, msg => re(qr/The file you want to upload do not have extension/) } };
};

subtest 'upload: accepts extension list with spaces' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                extension => '.sql txt .jpg, TXT',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.jpg'
            },
            body => "$tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Uploaded file filename.jpg/) } };
};

subtest 'upload: accepts extension list with dots' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                extension => '.sql,.txt,.JPG,.PDF',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.jpg'
            },
            body => "$tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Uploaded file filename.jpg/) } };
};

subtest 'upload: correctly checks double extensions' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.tar.gz', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.tar.gz" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                extension => 'txt .jpg .tar.gz tgz .foo.bar.baz',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.tar.gz'
            },
            body => "$tempdir/filename.tar.gz"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Uploaded file filename.tar.gz/) } };
};

subtest 'upload: correctly checks double extensions the the file have one extension' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.tar', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.tar" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                extension => 'txt .jpg .tar.gz tgz .foo.bar.baz',
                topic_mid => $topic_mid,
                filter    => 'test_file',
                qqfile    => 'filename.tar'
            },
            body => "$tempdir/filename.tar"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => { success => \0, msg => re(qr/This type of file is not allowed: tar/) } };
};

subtest 'upload: does not check extension when none specified' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'test' );

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => { extension => '', topic_mid => $topic_mid, filter => 'test_file', qqfile => 'filename.jpg' },
            body => "$tempdir/filename.jpg"
        }
    );

    my $controller = _build_controller();

    $controller->upload($c);
    cmp_deeply $c->stash, { json => { success => \1, msg => re(qr/Uploaded file filename.jpg/) } };
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

    my $topic_mid = TestSetup->create_topic( id_category => $id_changeset_category, project => $project );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_topic_selector_rule = _create_topic_selector_form();
    my $id_changeset_category  = TestSetup->create_category(
        name      => 'Changeset',
        id_rule   => $id_topic_selector_rule,
        id_status => $status->mid
    );

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
            icon => "/static/images/silk/arrow_down.gif",
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

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');
    my $project = TestUtils->create_ci_project( bls => [ $bl->mid ] );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $id_changeset_rule = _create_changeset_form(rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "description",
                        "fieldletType" => "fieldlet.system.description",
                        "id_field"     => "description",
                    },
                    "key" => "fieldlet.system.description",
                    name  => 'Description',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "content",
                        "fieldletType" => "fieldlet.html_editor",
                        "id_field"     => "content",
                    },
                    "key" => "fieldlet.html_editor",
                    name  => 'Content',
                }
            },
        ]);
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid, is_changeset => 1 );

    my $topic_mid = TestSetup->create_topic(
        status      => $status,
        id_category => $id_changeset_category,
        title       => "Topic",
        description => 'Hello <script>alert("hi")</script>there!',
        content => 'Bye, <script>alert("hi")</script>bye!',
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

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.changeset.view', }, ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

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

done_testing;

sub _create_user_with_drop_rules {
    my (%params) = @_;

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topicsfield.changeset.release.new.write',
            },
            {
                action => 'action.topicsfield.changeset.sprint.new.write',
            },
            {
                action => 'action.topics.release.view',
            },
            {
                action => 'action.topicsfield.release.changesets.new.write',
            },
            {
                action => 'action.topicsfield.sprint.changesets.new.write',
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
        'BaselinerX::Type::Event',            'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',                     'BaselinerX::Fieldlets',
        'BaselinerX::Service::TopicServices', 'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',            'BaselinerX::LcController',
        'BaselinerX::Type::Model::ConfigStore',
    );
    TestUtils->cleanup_cis;

    mdb->topic->drop;
    mdb->category->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->topic->drop;
}
