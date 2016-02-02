use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;
use Test::TempDir::Tiny;

use TestEnv;
use TestUtils ':catalyst';
use TestSetup;

TestEnv->setup;

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
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid, statuses=>[ $base_params->{status_new} ]  } } );
    $controller->kanban_config($c);
    ok ${ $c->stash->{json}{success} };

    $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config( $c );
    is $c->stash->{json}{config}{statuses}->[0], $base_params->{status_new};
};

subtest 'kanban no config, default' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config($c);
    is keys %{ $c->stash->{json}{config} }, 0;
};

subtest 'next status for topic by root user' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid=>"$topic_mid" } } );
    $c->{username} = 'root'; # change context to root
    $controller->list_admin_category($c);
    my $data = $c->stash->{json}{data};

    # 2 rows, root can take the topic 
    is $data->[0]->{status}, $id_status_from;
    is $data->[1]->{status}, $id_status_to;
};

subtest 'next status for topics by root user' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topics=>["$topic_mid"] } } );
    $c->{username} = 'root'; # change context to root
    $controller->next_status_for_topics($c);
    my $data = $c->stash->{json}{data};

    is $data->[0]->{id_status_from}, $id_status_from;
    is $data->[0]->{id_status_to}, $id_status_to;
};

subtest 'list statuses fieldlet for new topics not yet in database' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { categoryId=>$base_params->{category}, statusId=>$id_status_from } } );
    $c->{username} = 'root'; # change context to root
    $controller->list_admin_category($c);
    my $data = $c->stash->{json}{data};

    # 2 rows, root can take the topic 
    is $data->[0]->{status}, $id_status_from;
    is $data->[1]->{status}, $id_status_to;
};

subtest 'add label to topic' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $label_id = TestSetup->_setup_label;

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid=>$topic_mid, label_ids=>["$label_id"] } } );
    $c->{username} = 'root'; # change context to root
    $controller->update_topic_labels($c);
    cmp_deeply( $c->stash, { json => { msg => 'Labels assigned', success => \1 } } );
    is_deeply( mdb->topic->find_one({ mid=>"$topic_mid" })->{labels}, [$label_id] );
};

subtest 'grid: sets correct template' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { } } );

    $controller->grid($c);

    is $c->stash->{template}, '/comp/topic/topic_grid.js';
};

subtest 'grid: prepares stash' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { } } );

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

    my $c = _build_c( req => { params => {query => '123', project => '456', id_project => '789' } } );

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

    my $c = _build_c( req => { params => {category_id => '123'} } );

    $controller->grid($c);

    is $c->stash->{category_id}, '123';
};

subtest 'grid: replaces category_id if different' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => {category_id => '123'} } );

    $c->stash->{category_id} = 321;
    $controller->grid($c);

    is $c->stash->{category_id}, '123';
};

subtest 'related: returns 1 (proper topic) for new topic before created' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { } } );
    $c->{username} = 'root'; # change context to root

    $controller->related($c);
    my $topics = $c->stash->{json}->{data};
    
    is scalar @$topics, 0;
    is $c->stash->{json}->{totalCount}, 0;
};

subtest 'related: returns self for a newly created topic' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid=>$topic_mid } } );
    $c->{username} = 'root'; # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 1;
    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'related: returns 2 (self and related) related topics' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    $base_params->{parent} = [$topic_mid];

    my ( undef, $topic_mid_2 ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid=>$topic_mid } } );
    $c->{username} = 'root'; # change context to root

    $controller->related($c);

    my $topics = $c->stash->{json}->{data};

    is scalar @$topics, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'create a topic' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { 
            new_category_id=> $base_params->{category}, new_category_name=> 'Changeset', swEdit=> '1', tab_cls=> 'ui-tab-changeset', tab_icon=> '' 
            } } 
    );
    $c->{username} = 'root'; # change context to root
    $controller->view($c);
    my $stash = $c->stash;

    ok !exists $stash->{json}{success}; # this only shows up in case of failure 
};

subtest 'new topics have category_id in stash' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { 
            new_category_id=> $base_params->{category}, new_category_name=> 'Changeset', swEdit=> '1', tab_cls=> 'ui-tab-changeset', tab_icon=> '' 
            } } 
    );
    $c->{username} = 'root'; # change context to root
    $controller->view($c);
    my $stash = $c->stash;
    is $stash->{category_id}, $base_params->{category};
};

subtest 'list_status_changes: returns status changes' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $topic_mid = TestSetup->create_topic(
        status => $status,
        title  => "Topic"
    );

    my $model = Baseliner::Model::Topic->new;

    my $status1 = TestUtils->create_ci( 'status', name => 'Change1', type => 'I' );
    $model->change_status( mid => $topic_mid, id_status => $status1->mid, change => 1, username => 'user' );

    my $status2 = TestUtils->create_ci( 'status', name => 'Change2', type => 'I' );
    $model->change_status( mid => $topic_mid, id_status => $status2->mid, change => 1, username => 'user' );

    my @changes = $model->status_changes($topic_mid);

    my $c = _build_c( req => { params => { mid => $topic_mid } } );

    my $controller = _build_controller();
    $controller->list_status_changes($c);

    cmp_deeply $c->stash, {json => {data => [ignore(), ignore()]}};
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
        { action => 'update', topic_mid => $changeset_mid, sprint => [$sprint_mid] } );

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
        { action => 'update', topic_mid => $changeset_mid, release => [$release_mid] } );

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
        { action => 'update', topic_mid => $changeset_mid, release => [$release_mid] } );

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

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file('content', "$tempdir/filename.jpg");

    my $c = _build_c(username => 'user', req => {params => {extension => 'jpg', topic_mid => $topic_mid, filter => 'test_file', qqfile => 'filename.jpg'}, body => "$tempdir/filename.jpg"});

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => {success => \1, msg => re(qr/Uploaded file filename.jpg/) }};
};

subtest 'upload: fails to upload not allowed extension' => sub {
    _setup();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };

    my $tempdir = tempdir();
    TestUtils->write_file('content', "$tempdir/filename.jpg");

    my $c = _build_c(username => 'user', req => {params => {extension => 'sql,txt', topic_mid => $topic_mid, filter => 'test_file', qqfile => 'filename.jpg'}, body => "$tempdir/filename.jpg"});

    my $controller = _build_controller();

    $controller->upload($c);

    cmp_deeply $c->stash, { json => {success => \0, msg => re(qr/This type of file is not allowed: jpg/) }};
};

subtest 'list_users: doesnt fail if role is not found and returns 0' => sub {
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { 
            roles => 'TestRole'
        } } 
    );
    $c->{username} = 'root'; # change context to root
    $controller->list_users($c);
    my $stash = $c->stash;

    cmp_deeply $stash, { json => { totalCount => 0, data => [] } };
};

# subtest 'list_users: returns role' => sub {
#     TestSetup->_setup_clear();
#     my $controller = _build_controller();
#     my $project = TestUtils->create_ci_project;
#     my $id_role = TestSetup->create_role(
#         role => 'TestRole',
#         actions => [
#             {
#                 action => 'action.topics.category.view',
#             }
#         ]
#     );

#     my $user = TestSetup->create_user( username => 'test_user', id_role => $id_role, project => $project );
#     my $user2 = TestSetup->create_user( username => 'test_user2', id_role => $id_role, project => $project );

# my @roles = mdb->role->find()->all;
# warn Data::Dumper::Dumper( \@roles );

#     my $c = _build_c( req => { params => { 
#             roles => 'TestRole'
#         } } 
#     );
#     $c->{username} = 'test_user'; # change context to root
#     $controller->list_users($c);
#     my $stash = $c->stash;

#     is $stash->{json}{totalCount}, 1;
# };

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
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules'
    );

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->category->drop;
    mdb->role->drop;
    mdb->rule->drop;
}

done_testing;
