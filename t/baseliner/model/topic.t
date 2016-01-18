use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;
use Test::Deep;
use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup qw(_topic_setup _setup_clear _setup_user);
use TestUtils;

use List::MoreUtils qw(pairwise);
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Statement;
use BaselinerX::Type::Event;
use Baseliner::Utils qw(_load _file);

use_ok 'Baseliner::Model::Topic';

subtest 'get next status for user' => sub {
    _setup_clear();
    _setup_user();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow =
      [ { id_role => '1', id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef } ];
    mdb->category->update( { id => "$base_params->{category}" },
        { '$set' => { workflow => $workflow }, '$push' => { statuses => $id_status_to } } );

    my @statuses = model->Topic->next_status_for_user(
        username       => 'root',
        id_category    => $base_params->{category},
        id_status_from => $id_status_from,
        topic_mid      => $topic_mid
    );

    my $transition = shift @statuses;
    is $transition->{id_status_from}, $id_status_from;
    is $transition->{id_status_to},   $id_status_to;
};

subtest 'get_short_name: returns same name when no category exists' => sub {
    my $topic = _build_model();

    is $topic->get_short_name( name => 'foo' ), 'foo';
};

subtest 'get_short_name: returns acronym' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'Category', acronym => 'cat' } );

    my $topic = _build_model();

    is $topic->get_short_name( name => 'Category' ), 'cat';
};

subtest 'get_short_name: returns auto acronym when does not exist' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'Category' } );

    my $topic = _build_model();

    is $topic->get_short_name( name => 'Category' ), 'C';
};

subtest 'get_short_name: returns auto acronym when does not exist removing special characters' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'C123A##TegoRY' } );

    my $topic = _build_model();

    is $topic->get_short_name( name => 'C123A##TegoRY' ), 'CATRY';
};

subtest 'get meta returns meta fields' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $meta = Baseliner::Model::Topic->new->get_meta($topic_mid);

    is ref $meta, 'ARRAY';

    my $fieldlets        = TestSetup->_fieldlets();
    my @fields           = map { $$_{attributes}{data}{id_field} } @$fieldlets;
    my @fields_from_meta = map { $$_{id_field} } @$meta;
    is_deeply \@fields_from_meta, [ 'category', @fields ];
};

subtest 'include into fieldlet gets its topic list' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my ( undef, $topic_mid2 ) =
      Baseliner::Model::Topic->new->update( { %$base_params, parent => $topic_mid, action => 'add' } );
    my $field_meta = { include_options => 'all_parents' };
    my $data = { category => { is_release => 0, id => $base_params->{category} }, topic_mid => $topic_mid2 };
    my ( $is_release, @parent_topics ) = Baseliner::Model::Topic->field_parent_topics( $field_meta, $data );

    ok scalar @parent_topics == 1;
    is $parent_topics[0]->{mid}, $topic_mid;
};

subtest 'include into fieldlet filters out releases' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $rel_cat = TestSetup->_topic_release_category($base_params);
    my ( undef, $topic_mid ) =
      Baseliner::Model::Topic->new->update( { %$base_params, category => $rel_cat, action => 'add' } );
    my ( undef, $topic_mid2 ) =
      Baseliner::Model::Topic->new->update( { %$base_params, parent => $topic_mid, action => 'add' } );

    my $field_meta = { include_options => 'none' };
    my $data = { category => { is_release => 0, id => $base_params->{category} }, topic_mid => $topic_mid2 };
    my ( $is_release, @parent_topics ) = Baseliner::Model::Topic->field_parent_topics( $field_meta, $data );

    ok scalar @parent_topics == 0;
};

subtest 'upload: related field NOT exists for upload file' => sub {
    _setup_clear();
    _setup_user();

    my $base_params = _topic_setup();
    my $topic       = _build_model();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'not_exists_this_id', qqfile => 'testFile.fake', topic_mid => "$topic_mid" };

    my $file = Util->_file( Util->_tmp_dir . '/fakefile.txt' );
    my %res = $topic->upload( f => $file, p => $params, username => 'root' );

    like $res{msg}, qr/related field does not exist for the topic/;
};

subtest 'upload: file not exists for upload file' => sub {
    _setup_clear();
    _setup_user();

    my $base_params = _topic_setup();
    my $topic       = _build_model();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params    = { filter => 'test_file', qqfile => 'testFile.fake', topic_mid => "$topic_mid" };
    my $temp_file = Util->_tmp_dir . '/fakefile.txt';
    my $file      = Util->_file($temp_file);

    my %res = $topic->upload( f => $file, p => $params, username => 'root' );
    $file->remove();
    like $res{msg}, qr/file $temp_file does not exis/;
};

subtest 'upload: upload file complete' => sub {
    _setup_clear();
    _setup_user();

    my $base_params = _topic_setup();
    my $topic       = _build_model();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'testFile.fake', topic_mid => "$topic_mid" };

    my $file = Util->_file( Util->_tmp_dir . '/fakefile.txt' );
    open my $f, '>', $file or _throw _loc( "Could not open file %1: %2", $file, $! );
    $f->print("Fake test file");
    $f->close();

    my %res = $topic->upload( f => $file, p => $params, username => 'root' );
    $file->remove();

    is $res{success}, 'true';
};

subtest 'save_data: check master_rel for from_cl and to_cl from set_topics' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my ( undef, $topic_mid2 ) =
      Baseliner::Model::Topic->new->update( { %$base_params, parent => $topic_mid, action => 'add' } );
    my $doc = mdb->master_rel->find_one( { from_mid => "$topic_mid", to_mid => "$topic_mid2" } );
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl},   'topic';
};

subtest 'save_data: check master_rel for from_cl and to_cl from set_projects' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $doc = mdb->master_rel->find_one( { from_mid => "$topic_mid" } );
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl},   'project';
};

subtest 'update: creates correct event.topic.create' => sub {
    _setup();

    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.create' } );
    my $event_data = _load $event->{event_data};

    my $topic = mdb->master->find_one( { mid => "$topic_mid" } );
    my $category = mdb->category->find_one;

    is $event_data->{mid},           $topic_mid;
    is $event_data->{title},         $topic->{title};
    is $event_data->{topic},         $topic->{title};
    is $event_data->{name_category}, $category->{name};
    is $event_data->{category},      $category->{name};
    is $event_data->{category_name}, $category->{name};
    is_deeply $event_data->{notify_default}, [];
    like $event_data->{subject}, qr/New topic: Category #\d+/;
    is_deeply $event_data->{notify},
      {
        'project'         => [ $base_params->{project} ],
        'category_status' => $category->{statuses}->[0],
        'category'        => $category->{id}
      };
};

subtest 'upload: uploads file' => sub {
    _setup();

    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $filename = 'my-file.txt';

    my $f = _create_file($filename);

    my %response = Baseliner::Model::Topic->new->upload(
        username => 'clarive',
        f        => $f,
        p        => { topic_mid => $topic_mid, qqfile => $filename, filter => 'test_file' }
    );

    my $asset = ci->asset->find_one;

    is $asset->{name},       $filename;
    is $asset->{versionid},  '1';
    is $asset->{extension},  'txt';
    is $asset->{created_by}, 'clarive';
};

subtest 'upload: creates correct event.file.create event' => sub {
    _setup();

    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $filename = 'my-file.txt';

    my $f = _create_file($filename);

    Baseliner::Model::Topic->new->upload(
        username => 'clarive',
        f        => $f,
        p        => { topic_mid => $topic_mid, qqfile => $filename, filter => 'test_file' }
    );

    my $event = mdb->event->find_one( { event_key => 'event.file.create' } );
    my $event_data = _load $event->{event_data};

    my $asset = ci->asset->find_one;

    is $event_data->{username}, 'clarive';
    is $event_data->{mid},      $topic_mid;
    is $event_data->{id_file},  $asset->{mid};
    is $event_data->{id_field_asset},  'test_file';
    is $event_data->{filename}, $filename;
    is_deeply $event_data->{notify_default}, [];
    like $event_data->{subject}, qr/Created file $filename to topic \[\d+\]/;
};

subtest 'topics_for_user: returns topics' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic' );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic2' );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username});

    cmp_deeply $data,
      {
        'last_query' => {
            'category_status.type' => {
                '$nin' => [ 'F', 'FC' ]
            },
            '$or' => [
                {
                    '_project_security.project' => {
                        '$in' => [$project->mid]
                    },
                    'category.id' => {
                        '$in' => [$id_category]
                    }
                },
                {
                    '_project_security' => undef
                }
            ],
            'category.id' => {
                '$in' => [$id_category]
            }
        },
        'sort'  => { 'modified_on' => -1 },
        'count' => 2
      };

    is scalar @rows, 2;
};

subtest 'topics_for_user: returns topics' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic' );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic2' );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username});

    cmp_deeply $data,
      {
        'last_query' => {
            'category_status.type' => {
                '$nin' => [ 'F', 'FC' ]
            },
            '$or' => [
                {
                    '_project_security.project' => {
                        '$in' => [$project->mid]
                    },
                    'category.id' => {
                        '$in' => [$id_category]
                    }
                },
                {
                    '_project_security' => undef
                }
            ],
            'category.id' => {
                '$in' => [$id_category]
            }
        },
        'sort'  => { 'modified_on' => -1 },
        'count' => 2
      };

    is scalar @rows, 2;
};

subtest 'topics_for_user: returns topics limited' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic $_" )
      for 1 .. 10;

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, limit => 5});

    is scalar @rows, 5;
};

subtest 'topics_for_user: returns topics sorted' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic $_" )
      for 1 .. 2;

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, sort => 'topic_name'});

    my ($topic_number)  = $rows[0]->{topic_name} =~ m/#(\d+)/;
    my ($topic_number2) = $rows[1]->{topic_name} =~ m/#(\d+)/;

    ok $topic_number > $topic_number2;

    ($data, @rows) = $model->topics_for_user({username => $user->username, sort => 'topic_name', dir => -1});

    ($topic_number)  = $rows[0]->{topic_name} =~ m/#(\d+)/;
    ($topic_number2) = $rows[1]->{topic_name} =~ m/#(\d+)/;

    ok $topic_number < $topic_number2;
};

subtest 'topics_for_user: returns topics filtered by category' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
            {
                action => 'action.topics.othercategory.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 = TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    TestSetup->create_topic( project => $project, id_category => $id_category2, status => $status, title => "Other Topic" );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, categories => [$id_category]});

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics filtered by category negative' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
            {
                action => 'action.topics.othercategory.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 = TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    TestSetup->create_topic( project => $project, id_category => $id_category2, status => $status, title => "Other Topic" );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, categories => ["!$id_category"]});

    is @rows, 1;
    is $rows[0]->{title}, 'Other Topic';
};

subtest 'topics_for_user: returns topics filtered topic mid' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $mid = TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    my $mid2 = TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Other Topic" );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, topic_list => [$mid2]});

    is @rows, 1;
    is $rows[0]->{title}, 'Other Topic';
};

subtest 'topics_for_user: returns topics filtered by assigned to me' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid =
      TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user->mid, rel_type => 'topic_users' } );

    my $topic_mid2 =
      TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Other Topic" );
    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user2->mid, rel_type => 'topic_users' } );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, assigned_to_me => 1});

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics filtered by statuses' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status_initial  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_finished  = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status_initial->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status_initial, title => "Topic" );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status_finished, title => "Finished Topic" );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username});

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics clear filtered' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status_initial  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress  = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished  = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status_initial->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status_initial, title => "Topic" );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status_in_progress, title => "In Progress Topic" );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status_finished, title => "Finished Topic" );

    my $model = _build_model();

    my ($data, @rows) = $model->topics_for_user({username => $user->username, clear_filter => 1});

    is @rows, 3;
};

subtest 'topics_for_user: returns topics filtered by labels' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_label_one = TestSetup->create_label(name => 'one');
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_one],
        title       => "Topic one"
    );

    my $id_label_two = TestSetup->create_label(name => 'two');
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels       => [$id_label_two],
        title       => "Topic two"
    );

    my $id_label_three = TestSetup->create_label(name => 'three');
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_three],
        title       => "Topic three"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user(
        { username => $user->username, labels => [$id_label_one]} );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic one';
};

subtest 'build_sort: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->build_sort('some_field', 1), {'_sort.some_field' => 1};
    is_deeply $model->build_sort('some_field', -1), {'_sort.some_field' => -1};

    for (
        qw/
        category_status_name
        modified_on
        created_on
        modified_by
        created_by
        category_name
        moniker
        /
      )
    {
        is_deeply $model->build_sort($_, 1), {$_ => 1};
        is_deeply $model->build_sort($_, -1), {$_ => -1};
    }

    is_deeply $model->build_sort('topic_mid', 1), {'_id' => 1};
    is_deeply $model->build_sort('topic_mid', -1), {'_id' => -1};

    my $ix_hash = $model->build_sort('topic_name', 1);
    my @keys = $ix_hash->Keys;
    my @values = $ix_hash->Values;

    my %hash = pairwise { no warnings 'once'; ( $a, $b ) } @keys, @values;

    is_deeply \%hash, {created_on => 1, mid => 1};
};

subtest 'grep_in_and_nin: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->grep_in_and_nin([1, 2, 3], []), [1, 2, 3];
    is_deeply $model->grep_in_and_nin([1, 2, 3], [1]), [1];
    is_deeply $model->grep_in_and_nin([1, 2, 3], ['!2']), [1, 3];
    is_deeply $model->grep_in_and_nin([1, 2, 3], [1, 2, 3, '!1', '!2']), [3];
    is_deeply $model->grep_in_and_nin([1, 2, 3, 4], [1, 2, 3, '!1', '!2', '!3']), [];
};

subtest 'build_in_and_nin_query: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->build_in_and_nin_query( []), undef;
    is_deeply $model->build_in_and_nin_query( [1]),  { '$in'  => [1] };
    is_deeply $model->build_in_and_nin_query( ['!2']), { '$nin' => [2] };
    is_deeply $model->build_in_and_nin_query( [ 1, 2, 3, '!1', '!2' ] ), { '$in' => [ 1, 2, 3 ], '$nin' => [ 1, 2 ] };
};

done_testing();

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic'
    );

    TestUtils->cleanup_cis;

    mdb->event->drop;
    mdb->rule->drop;
    mdb->role->drop;
    mdb->category->drop;
    mdb->label->drop;
}

sub _create_file {
    my ($filename) = @_;

    my $tempdir = tempdir();
    TestUtils->write_file( 'test_file', "$tempdir/$filename" );

    return _file("$tempdir/$filename");
}

sub _build_model {
    return Baseliner::Model::Topic->new;
}
