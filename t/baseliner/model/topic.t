use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup qw(_topic_setup _setup_clear _setup_user);
use TestUtils qw(mock_time);

use List::MoreUtils qw(pairwise);
use Capture::Tiny qw(capture);
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Statement;
use BaselinerX::Type::Event;
use Baseliner::Utils qw(_load _file);

use_ok 'Baseliner::Model::Topic';

subtest 'get next status for user' => sub {
    _setup();
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
    _setup();

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
    _setup();
    _setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $meta = Baseliner::Model::Topic->new->get_meta($topic_mid);

    is ref $meta, 'ARRAY';

    my $fieldlets = TestSetup->_fieldlets();
    my @fields = map { $$_{attributes}{data}{id_field} } @$fieldlets;
    unshift @fields, ( 'created_by', 'modified_by', 'created_on', 'category', 'modified_on' );
    my @fields_from_meta = sort map { $$_{id_field} } @$meta;
    is_deeply \@fields_from_meta, [sort @fields];
};

subtest 'include into fieldlet gets its topic list' => sub {
    _setup();
    _setup_user();

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
    _setup();
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
    _setup();
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
    _setup();
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
    _setup();
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
    _setup();
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
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $doc = mdb->master_rel->find_one( { from_mid => "$topic_mid" } );
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl},   'project';
};

subtest 'save_doc: correctly saved common environment entry in calendar fieldlet' => sub {
    _setup();
    my $id_rule = TestSetup->create_rule_form();
    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [ { action => 'action.topics.category.view', } ] );

    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    my $doc = {
        'calendar' => [
            {   'mid'             => '32446',
                'allday'          => 0,
                'plan_start_date' => '2016-03-09 00:00:00',
                'rel_field'       => 'env',
                'plan_end_date'   => '2016-03-26 00:00:00',
                'id'              => '163',
                'slotname'        => '*'
            }
        ],
    };

    my %p = ( mid => $topic_mid, custom_fields => [], username => $user->username );
    my $meta = [ { id_field => 'calendar', meta_type => 'calendar' } ];
    my $topic_ci = ci->new($topic_mid);

    Baseliner::Model::Topic->new->save_doc( $meta, $topic_ci, $doc, %p );

    ok( $doc->{calendar}->{'*'} );
};

subtest 'update: creates correct event.topic.create' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.create' } );
    my $event_data = _load $event->{event_data};

    my $topic = mdb->topic->find_one( { mid => "$topic_mid" } );
    my $category = mdb->category->find_one;

    my @project_names = ();
    my @project_mids = $topic->{project};
    foreach my $project_mid (@project_mids){
        my $project_ci = ci->new($project_mid);
        if( $project_ci && $project_ci->name){
            push @project_names, $project_ci->name;
        }
    }

    is $event_data->{mid},           $topic_mid;
    is $event_data->{title},         $topic->{title};
    is $event_data->{topic},         $topic->{title};
    is $event_data->{name_category}, $category->{name};
    is $event_data->{category},      $category->{name};
    is $event_data->{category_name}, $category->{name};
    is_deeply $event_data->{notify_default}, [];
    is_deeply $event_data->{projects}, \@project_names;
    like $event_data->{subject}, qr/New topic: Category #\d+/;
    is_deeply $event_data->{notify},
      {
        'project'         => [ $base_params->{project} ],
        'category_status' => $category->{statuses}->[0],
        'category'        => $category->{id}
      };
};

subtest 'update: creates topic when rule fails' => sub {
    _setup();

    TestSetup->_setup_user();

    my $status_id = ci->status->new( name => 'New', type => 'I' )->save;

    my $id_rule1 = mdb->seq('id');
    mdb->rule->insert(
        {   id          => "$id_rule1",
            ts          => '2015-08-06 09:44:30',
            rule_event  => "event.topic.create",
            rule_active => '1',
            rule_type   => 'event',
            rule_when   => "post-online",
            rule_seq    => $id_rule1,
            rule_tree   => JSON::encode_json(
                [   {   "attributes" => {
                            "data"   => { "msg" => "abort here" },
                            "key"    => "statement.fail",
                            "text"   => "FAIL",
                            "name"   => "FAIL",
                            "active" => 1,
                            "nested" => "0"
                        },
                        "children" => []
                    }
                ]
                )

        }
    );
    my $id_rule = TestSetup->create_rule_form();
    my $cat_id  = mdb->seq('id');
    mdb->category->insert(
        { id => "$cat_id", name => 'Category', statuses => [$status_id], default_form => "$id_rule" } );

    my $project = ci->project->new( name => 'Project' );
    my $project_mid = $project->save;

    my $base_params = {
        'project'         => $project_mid,
        'category'        => "$cat_id",
        'status_new'      => "$status_id",
        'status'          => "$status_id",
        'category_status' => { id => "$status_id" },
        'title'           => 'Topic Create',
        'username'        => 'test',
    };

    capture { like
            exception { Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } ) }
        , qr/Error adding Topic: \(rule $id_rule1\): Error running rule '$id_rule1': abort here/;
    };

    my $topic = mdb->topic->find_one();
    is $topic->{title}, 'Topic Create';
};

subtest 'update: reload topic when have deploy in initial status' => sub {
    _setup();

    my $base_params = TestSetup->_topic_setup();

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');

    my $project = ci->new($base_params->{project});
    $project->{bls} = [ $bl->mid ];
    $project->update();

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( username => 'test', id_role => $id_role, project => $project );

    my $status1 = TestUtils->create_ci( 'status', name => 'Deploy', type => 'D', bls => [ $bl->mid ] );

    my $workflow = [ { id_role => $id_role, id_status_from => $base_params->{status}, id_status_to => $status1->mid, job_type => 'promote' } ];
    mdb->category->update( { id => "$base_params->{category}" }, { '$set' => { workflow => $workflow }, '$push' => { statuses => $status1->mid } } );

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.create' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{return_options}->{reload_tab}, 1;
};


subtest 'update: creates correct event.topic.modify' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    Baseliner::Model::Topic->new->update( { action => 'update', topic_mid => $topic_mid, title => 'Second title', username => 'test' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify' } );
    my $event_data = _load $event->{event_data};

    my $topic = mdb->topic->find_one( { mid => "$topic_mid" } );
    my $category = mdb->category->find_one;

    cmp_deeply $event_data, {
        mid => $topic_mid,
        title => $topic->{title},
        topic => $topic->{title},
        topic_data => {
            name_category => $category->{name},
            category_color => $category->{category_color},
            category_id => $category->{id},
            category_status_id => $topic->{category_status}->{id},
            category_status_name => $topic->{category_status}->{name},
            category_status_seq => ignore(),
            category_status_type => $topic->{category_status}->{type},
            color_category => ignore(),
            id_category => $topic->{category_id},
            id_category_status => $topic->{id_category_status},
            is_changeset => ignore(),
            username => ignore(),
            is_release => ignore(),
            mid => ignore(),
            username => ignore(),
            modified_on => ignore(),
            name_status => $topic->{name_status},
            status_new => $topic->{status_new},
            title => ignore(),
            topic_mid => $topic_mid,
            category => {
                _id => ignore(),
                id => $category->{id},
                statuses => ignore(),
                default_form => $category->{default_form},
                name => $category->{name},
            },
            category_name => $category->{name},
            category_status => $topic->{category_status},
            modified_by => ignore(),
        },
        notify => {
            'category_status' => $category->{statuses}->[0],
            'category'        => $category->{id}
        },
        notify_default => [],
        return_options => ignore(),
        rules_exec => ignore(),
        subject => ignore(),
        topic_mid => $topic_mid,
        username => ignore(),
    };
    like $event_data->{subject}, qr/Topic updated: Category #\d+/;
};

subtest 'upload: uploads file' => sub {
    _setup();
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

    is $event_data->{username},       'clarive';
    is $event_data->{mid},            $topic_mid;
    is $event_data->{id_file},        $asset->{mid};
    is $event_data->{id_field_asset}, 'test_file';
    is $event_data->{filename},       $filename;
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

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username } );

    cmp_deeply $data,
      {
        'last_query' => {
            'category_status.type' => {
                '$nin' => [ 'F', 'FC' ]
            },
            '$or' => [
                {
                    '_project_security.project' => {
                        '$in' => [ $project->mid ]
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
        'query' => undef,
        'sort'  => { 'modified_on' => -1 },
        'count' => 2,
        'id_project' => undef
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

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, limit => 5 } );

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

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, sort => 'topic_name' } );

    my ($topic_number)  = $rows[0]->{topic_name} =~ m/#(\d+)/;
    my ($topic_number2) = $rows[1]->{topic_name} =~ m/#(\d+)/;

    ok $topic_number > $topic_number2;

    ( $data, @rows ) = $model->topics_for_user( { username => $user->username, sort => 'topic_name', dir => -1 } );

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
    my $id_category2 =
      TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category2,
        status      => $status,
        title       => "Other Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, categories => [$id_category] } );

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
    my $id_category2 =
      TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category2,
        status      => $status,
        title       => "Other Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, categories => ["!$id_category"] } );

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

    my $mid =
      TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    my $mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Other Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, topic_list => [$mid2] } );

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

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid =
      TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user->mid, rel_type => 'topic_users' } );

    my $topic_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Other Topic"
    );
    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user2->mid, rel_type => 'topic_users' } );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, assigned_to_me => 1 } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics filtered by statuses' => sub {
    _setup();

    my $id_rule         = TestSetup->create_rule_form();
    my $status_initial  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $project         = TestUtils->create_ci_project;
    my $id_role         = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category =
      TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status_initial->mid );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_initial,
        title       => "Topic"
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_finished,
        title       => "Finished Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics clear filtered' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_initial     = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $project            = TestUtils->create_ci_project;
    my $id_role            = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
        ]
    );

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category =
      TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status_initial->mid );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_initial,
        title       => "Topic"
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_in_progress,
        title       => "In Progress Topic"
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_finished,
        title       => "Finished Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, clear_filter => 1 } );

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

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_label_one = TestSetup->create_label( name => 'one' );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_one],
        title       => "Topic one"
    );

    my $id_label_two = TestSetup->create_label( name => 'two' );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_two],
        title       => "Topic two"
    );

    my $id_label_three = TestSetup->create_label( name => 'three' );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_three],
        title       => "Topic three"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, labels => [$id_label_one] } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic one';
};

subtest 'run_query_builder: finds topics by query in a project' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project2,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );
    my $topic3 = TestSetup->create_topic(
        project     => $project2,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic3'
    );

    my $model = _build_model();

    my $where = {};
    my (@topics) = $model->run_query_builder( 'Topic', $where, $user->username, id_project => $project->mid);

    is scalar @topics, 1;
    is $topics[0], $topic2;
};

subtest 'topics_for_user: topic that does not exist' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            },
            {   "attributes" => {
                    "data" => {
                        "id_field"     => "title",
                        "name_field"   => "Title",
                        "fieldletType" => "fieldlet.system.title",
                    },
                    "key" => "fieldlet.system.title",
                    text  => 'Title',
                    }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $other_project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, id_project => $project->mid, query => 'Topic3' } );

    is scalar @rows, 0;
};

subtest 'topics_for_user: does not return topic that exist in other project' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            }
        ],
    );

    my $status        = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project       = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $other_project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, id_project => $project->mid, query => 'Topic2' } );

    is scalar @rows, 0;
};

subtest 'topics_for_user: returns topics of project' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, id_project => $project->mid } );

    is scalar @rows, 2;
    is $rows[0]->{topic_mid}, $topic2;
    is $rows[1]->{topic_mid}, $topic1;
};

subtest 'topics_for_user: Search a topic with special characters ' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            },
            {   "attributes" => {
                    "data" => {
                        "id_field"     => "title",
                        "name_field"   => "Title",
                        "fieldletType" => "fieldlet.system.title",
                    },
                    "key" => "fieldlet.system.title",
                    text  => 'Title',
                    }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows )
        = $model->topics_for_user( { username => $user->username, id_project => $project->mid, query => 'Top?c2' } );

    is scalar @rows, 1;
    is $rows[0]->{mid}, $topic2;

};

subtest 'build_sort: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->build_sort( 'some_field', 1 ),  { '_sort.some_field' => 1 };
    is_deeply $model->build_sort( 'some_field', -1 ), { '_sort.some_field' => -1 };

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
        is_deeply $model->build_sort( $_, 1 ),  { $_ => 1 };
        is_deeply $model->build_sort( $_, -1 ), { $_ => -1 };
    }

    is_deeply $model->build_sort( 'topic_mid', 1 ),  { '_id' => 1 };
    is_deeply $model->build_sort( 'topic_mid', -1 ), { '_id' => -1 };

    my $ix_hash = $model->build_sort( 'topic_name', 1 );
    my @keys    = $ix_hash->Keys;
    my @values  = $ix_hash->Values;

    my %hash = pairwise { no warnings 'once'; ( $a, $b ) } @keys, @values;

    is_deeply \%hash, { created_on => 1, mid => 1 };
};

subtest 'grep_in_and_nin: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], [] ), [ 1, 2, 3 ];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], [1] ), [1];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], ['!2'] ), [ 1, 3 ];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], [ 1, 2, 3, '!1', '!2' ] ), [3];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3, 4 ], [ 1, 2, 3, '!1', '!2', '!3' ] ), [];
};

subtest 'build_in_and_nin_query: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->build_in_and_nin_query( [] ), undef;
    is_deeply $model->build_in_and_nin_query( [1] ),    { '$in'  => [1] };
    is_deeply $model->build_in_and_nin_query( ['!2'] ), { '$nin' => [2] };
    is_deeply $model->build_in_and_nin_query( [ 1, 2, 3, '!1', '!2' ] ), { '$in' => [ 1, 2, 3 ], '$nin' => [ 1, 2 ] };
};

subtest 'status_changes: returns all the status changes' => sub {
    my $model = _build_model();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $topic_mid = TestSetup->create_topic(
        status => $status,
        title  => "Topic"
    );

    my $status1 = TestUtils->create_ci( 'status', name => 'Change1', type => 'I' );
    mock_time '2016-01-01T00:00:00', sub {
        $model->change_status( mid => $topic_mid, id_status => $status1->mid, change => 1, username => 'user' );
    };

    my $status2 = TestUtils->create_ci( 'status', name => 'Change2', type => 'I' );
    mock_time '2016-01-02T00:00:00', sub {
        $model->change_status( mid => $topic_mid, id_status => $status2->mid, change => 1, username => 'user' );
    };

    my @changes = $model->status_changes( { mid => $topic_mid } );

    is scalar @changes, 2;
    is_deeply $changes[0],
      {
        old_status => 'Change1',
        status     => 'Change2',
        username   => 'user',
        when       => '2016-01-02 00:00:00'
      };
    is_deeply $changes[1],
      {
        old_status => 'New',
        status     => 'Change1',
        username   => 'user',
        when       => '2016-01-01 00:00:00'
      };
};

subtest 'get_users_friend: returns users with same rights for this category and status' => sub {
    _setup();

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user1   = TestSetup->create_user( name => 'user1', id_role => $id_role, project => $project );
    my $user2   = TestSetup->create_user( name => 'user2', id_role => $id_role, project => $project );

    my $id_role_other = TestSetup->create_role();
    my $user3 = TestSetup->create_user( name => 'user3', id_role => $id_role_other, project => $project );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->mid,
            id_status_to   => $status_finished->mid,
            job_type       => undef
        }
    ];
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_status => [ $status_new->mid, $status_finished->mid ],
        workflow  => $workflow
    );

    my $model = _build_model();

    my @friends = $model->get_users_friend( id_category => $id_category, id_status => $status_new->mid );

    is_deeply \@friends, [qw/user1 user2/];
};

subtest 'get_users_friend: returns empty when no category found' => sub {
    _setup();

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user1   = TestSetup->create_user( name => 'user1', id_role => $id_role, project => $project );
    my $user2   = TestSetup->create_user( name => 'user2', id_role => $id_role, project => $project );

    my $id_role_other = TestSetup->create_role();
    my $user3 = TestSetup->create_user( name => 'user3', id_role => $id_role_other, project => $project );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->mid,
            id_status_to   => $status_finished->mid,
            job_type       => undef
        }
    ];
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_status => [ $status_new->mid, $status_finished->mid ],
        workflow  => $workflow
    );

    my $model = _build_model();

    my @friends = $model->get_users_friend( id_category => 'unknown-123', id_status => $status_new->mid );

    is_deeply \@friends, [];
};

subtest 'get_users_friend: returns empty when no role found' => sub {
    _setup();

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user1   = TestSetup->create_user( name => 'user1', id_role => $id_role, project => $project );
    my $user2   = TestSetup->create_user( name => 'user2', id_role => $id_role, project => $project );

    my $id_role_other = TestSetup->create_role();
    my $user3 = TestSetup->create_user( name => 'user3', id_role => $id_role_other, project => $project );

    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_status => [ $status_new->mid, $status_finished->mid ],
    );

    my $model = _build_model();

    my @friends = $model->get_users_friend( id_category => $id_category, id_status => $status_new->mid );

    is_deeply \@friends, [];
};

subtest 'get_meta_permissions: returns meta with readonly flags' => sub {
    _setup();

    my $model = _build_model();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topicsfield.changeset.release.new.write',
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule = TestSetup->create_rule_form(
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
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'release',
                        release_field => 'changesets'
                    },
                    "key" => "fieldlet.system.release",
                    name  => 'Release',
                }
            }
        ],
    );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    my $topic_meta = Baseliner::Model::Topic->new->get_meta( $changeset_mid, $id_changeset_category, $user->username );

    my $meta = $model->get_meta_permissions(
        'data' => {
            'topic_mid' => $changeset_mid,
            'category'  => {
                'id'   => $id_changeset_category,
                'name' => 'Changeset',
            },
            'category_status' => {
                'mid'  => $status->mid,
                'name' => 'New',
            },
        },
        meta     => $topic_meta,
        username => $user->username
    );

    my ($status_field) = grep { $_->{name} && $_->{name} eq 'Status' } @$meta;
    cmp_deeply $status_field->{readonly}, \1;

    my ($release_field) = grep { $_->{name} && $_->{name} eq 'Release Combo' } @$meta;
    cmp_deeply $release_field->{readonly}, \0;
};

subtest 'get_users: returns users filtering by role' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
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
                        id_field => 'asignada',
                    },
                    "key" => "fieldlet.system.users",
                    name  => 'Asiganada',
                }
            }
        ],
    );
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic',
        asignada    => $user->mid
    );

    my $model = _build_model();
    my $users = $model->get_users( $topic_mid, 'asignada', undef, {} );

    is scalar @$users, 1;
    is $users->[0]->{username}, $user->username;
};

subtest 'get_users: adds username field to the data' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
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
                        id_field => 'asignada',
                    },
                    "key" => "fieldlet.system.users",
                    name  => 'Asiganada',
                }
            }
        ],
    );
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic',
        asignada    => $user->mid
    );
    my $data  = {};
    my $model = _build_model();
    my $users = $model->get_users( $topic_mid, 'asignada', undef, $data );

    is $data->{"asignada._user_name"}, $user->username;
};

subtest 'set_topic: saves topic into parent' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topicsfield.changeset.sprint.new.write',
            },
        ]
    );
    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $id_sprint_rule = TestSetup->create_rule_form(
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
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
    my $id_changeset_rule = TestSetup->create_rule_form(
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
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'sprint',
                        parent_field  => 'changesets'
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Sprint',
                }
            }
        ],
    );
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $sprint_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint Parent',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child',
        sprint     => $sprint_mid,
        status      => $status
    );

    my $model = _build_model();
    my $sprint = $model->get_data( undef, $sprint_mid, with_meta=>1 );
    is scalar @{ $sprint->{changesets} }, 1;
    is $sprint->{changesets}->[0]->{mid}, $changeset_mid;
};

subtest 'set_topic: saves topic into release' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topicsfield.changeset.release.new.write',
            },
        ]
    );
    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $id_release_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
    my $id_changeset_rule = TestSetup->create_rule_form(
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
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'release',
                        release_field => 'changesets'
                    },
                    "key" => "fieldlet.system.release",
                    name  => 'Release',
                }
            }
        ],
    );
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release Parent',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child',
        release     => $release_mid,
        status      => $status
    );

    my $model = _build_model();
    my $release = $model->get_data( undef, $release_mid, with_meta=>1);
    is scalar @{ $release->{changesets} }, 1;
    is $release->{changesets}->[0]->{mid}, $changeset_mid;
};

subtest 'deal_with_images: returns field in image format with src' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.description",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.description",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'asignada',
                    },
                    "key" => "fieldlet.system.users",
                    name  => 'Asiganada',
                }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic',
        asignada    => $user->mid
    );

    my $field  = q[<img src="data:image/gif;base64,R0lGODlhQABAAPEDAP//////AAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQEDwD/ACwAAAAAQABAAAAC0oSPqcvtD6OctNqLs968+w+G4kiW5okiQ9oNbvKykxsDtCzRsY6rq6JbBX2/E48YvBmORmYyaRumntRqEWXNKllaba9b7UXB0C/5iTtTZeo1tzZe/rbxKdx2qF3r2LuvQWcS+McwSMKEtIAouFiWZ3hoFTAZYJVGRUnpxtYG2fSUiSYm1zba6Rl56leiKvXZiuoB6ziSBeTFGqYItRhy47rbaxcLzLkKI9x3jLT3dgVcbBy4+aX5MGBdnQ0Yapb8+D0qPk5ebn6Onq6+zt7u/i5SAAAh+QQEDwD/ACwAAAAAQABAAAAC1ISPqcvtD6OctNqLs968+w+G4kiW5okmQ9oNrrqyk/satCzRtY4jNXzTxWw/E88nFB6OJyUxyUuyoNTqEGXN3mRaba9b7QHAVDG5zD1D02rptLjdwYtG+vB3HdNL28V++TfSpxCol8c3CPjH1MRomOhYVxVAGWCFM1lJicbWdpiSuekm9nhG6pmIhZqKuMoq4jraGvvqkUXoNSuLpBQJEuSrWCtZ+FQ8C+H0NWz8qXqlXHq6y4lZ6bx0baaJbcO9HCx8TEpebn6Onq6+zt7u/g4fD1IAACH5BAQPAP8ALAAAAABAAEAAAALShI+py+0Po5y02ouz3rz7D4biSJbmiSJD2g1u8rKTGwO0LNGxjqurolsFfb8Tjxi8GY5GZjJpG6ae1GoRZc0qWVptr1vtRcHQL/mJO1Nl6jW3Nl7+tvEp3HaoXevYu69BZxL4xzBIwoS0gCi4WJZneGgVMBlglUZFSenG1gbZ9JSJJibXNtrpGXnqV6Iq9dmK6gHrOJIF5MUapgi1GHLjuttrFwvMuQoj3HeMtPd2BVxsHLj5pfkwYF2dDRhqlvz4PSo+Tl5ufo6err7O3u7+LlIAACH5BAQPAP8ALAAAAABAAEAAAALShI+py+0Po5y02ouz3rz7D4biSJbmiR5D2g1u8rKTGwO0LNGxjiO1z9OtVL8SDyg82m4oITEZdKag1Opwas0WT1ptr1vtLcFJMZmKO6NZ6jX2Ojbsfsxm8VqDx9+N7ZPtJ6eHBOinhDRIIvVUJxg4khUgGWCVRjU56VbYlmgHhQklxngmytn4ZtoJmXpoxLro+toakqXQZVK5EDoLcgNr+7up6viIe6rL6zlMvKxIdxgsrBdWmvkwYP0Fer1tmTzaLCo+Tl5ufo6err7O3u7+/lEAACH5BAQPAP8ALAAAAABAAEAAAALShI+py+0Po5y02ouz3rz7D4biSJbmiSJD2g1u8rKTGwO0LNGxjqurolsFfb8Tjxi8GY5GZjJpG6ae1GoRZc0qWVptr1vtRcHQL/mJO1Nl6jW3Nl7+tvEp3HaoXevYu69BZxL4xzBIwoS0gCi4WJZneGgVMBlglUZFSenG1gbZ9JSJJibXNtrpGXnqV6Iq9dmK6gHrOJIF5MUapgi1GHLjuttrFwvMuQoj3HeMtPd2BVxsHLj5pfkwYF2dDRhqlvz4PSo+Tl5ufo6err7O3u7+LlIAACH5BAQPAP8ALAAAAABAAEAAAALUhI+py+0Po5y02ouz3rz7D4biSJbmiSZD2g2uurKT+xq0LNG1jiM1fNPFbD8TzycUHo4nJTHJS7Kg1OoQZc3eZFptr1vtAcBUMbnMPUPTaum0uN3Bi0b68Hcd00vbxX75N9KnEKiXxzcI+MfUxGiY6FhXFUAZYIUzWUmJxtZ2mJK56Sb2eEbqmYiFmoq4yiriOtoa++qRReg1K4ukFAkS5KtYK1n4VDwL4fQ1bPypeqVcerrLiVnpvHRtpoltw70cLHxMSl5ufo6err7O3u7+Dh8PUgAAIfkEBA8A/wAsAAAAAEAAQAAAAtKEj6nL7Q+jnLTai7PevPsPhuJIluaJIkPaDW7yspMbA7Qs0bGOq6uiWwV9vxOPGLwZjkZmMmkbpp7UahFlzSpZWm2vW+1FwdAv+Yk7U2XqNbc2Xv628Sncdqhd69i7r0FnEvjHMEjChLSAKLhYlmd4aBUwGWCVRkVJ6cbWBtn0lIkmJtc22ukZeepXoir12YrqAes4kgXkxRqmCLUYcuO622sXC8y5CiPcd4y093YFXGwcuPml+TBgXZ0NGGqW/Pg9Kj5OXm5+jp6uvs7e7v4uUgAAIfkEBA8A/wAsAAAAAEAAQAAAAtKEj6nL7Q+jnLTai7PevPsPhuJIluaJHkPaDW7yspMbA7Qs0bGOI7XP061UvxIPKDzabighMRl0pqDU6nBqzRZPWm2vW+0twUkxmYo7o1nqNfY6Nux+zGbxWoPH343tk+0np4cE6KeENEgi9VQnGDiSFSAZYJVGNTnpVtiWaAeFCSXGeCbK2fhm2gmZemjEuuj62hqSpdBlUrkQOgtyA2v7u6nq+Ih7qsvrOUy8rEh3GCysF1aa+TBg/QV6vW2ZPNosKj5OXm5+jp6uvs7e7v7+UQAAIfkEBAoA/wAsAAAAAEAAQAAAAuOEj6nL7Q+jnLTai7PevPsPhuJIluaJHkPaDW7yspMbA7Qs0bGOI7XP061UvxIPKDzabighMRl0pqDU6nBqzRZPWm2vW+0twUkxmYo7o1nqNfY6Nux+zGbxWoPH343tk+0np4cE6KeENEgi9VQnGDiSFSAZYJVGNTnpVtiWaAeFCSXGeCbK2fhm2gmZemjEuuj62hqSpdBlUrkQOgtyA2sLq8oB9wvcKKyhxwtziJyhfKrbrEhM16z0OFzdqumsbZP5MBCeTTsumX1OWW4exKwp6hgdT19vf4+fr7/P3+//D1BDAQAh+QQECgD/ACwAAAAAQABAAAAC+ISPqcvtD6OctNqLs968+w+G4khGQxkOarKikwrHJ+xKrWzIbX2sO4DD5Wi1GEtnHBJLuh7S2PyBTsCnFdkbUavX7jYn2nq9rNRxjFV8OWv0c7HWxN3vsqdNTyPimW++vnfn90N0QyjFd4HX5pS1d3h31iD16PexOJnIFXhZyZd0ZtnptKRUyjU45YkU0BpwxTlKquPqCggUNvgHGRYqU6tXRYK4C6pVDDuMbMW0fJvrbNy8zONLGVw9m4hdLcTQlK394B0uDWfOg+4bTrrqzm5KDA4/YDtuz16PPwmcT36uDp7AgQQLGjyIMKHChQwbOnwIMaJEAAUAACH5BAQKAP8ALAAAAABAAEAAAAL9hI+pO+2zopw0Pohu3dw2/nUi5YzhiGYYWqbs6p7uBjPgDNZJe8gGj2PodjxgJigZqloPD1IR8v2aml70ubP6LlztSjn7NqdcahUATsnK7DYszSK65zVprE6fQ7HDfNv21OdXBogkONiVFQiFSKhoKNd41sMntzRFdnm0qEmJ+WO5CdnJmLRVSUpkWofqJWQ35jnqhRdLpgMn8uYW0Bvg9shJ++Dry7aHhRYpWSg87FDsGBwo6aecjFY9iJ2tTcd9630M/uxN7lF9XpG4ZKuObtft/t6exk6/TDKPL7++j/+vHj9Gu4BMGhiu1kGEP4wxcMgQCsQdEyP2qHixVyEuegM0JvFoUdWEeCFLmjyJMqXKlSxbunwJM6bMmTRRFgAAIfkEBAoA/wAsAAAAAEAAQAAAAv2Ej6nL7Q+jnLTai7PebfAfDWIygqZYAqgJoqXLUqmxHp6N1LHi1j2s+u0WOtqvZysOjcaj87UkBZ9UZFTVrFKD0VtWK6QtvV8wkBsjl8069UfNfuZY8LhzfiLNfLdi251RB5eEk7PXwjOj13H4lgjIxOCHqKeYRaQEWeFmlXR2KcXBSRVQGrAVKvr4Y2p6x0NpaKckFivL6hoGm7caR0TXa5fKuyZcCFw8W7vjMbuludHsLNeFeks9hl0J88k80onZfXX9AD5+C2F+Duqgvu736f5u/rpO5HpfCv2Oz9Nvn+9UwH3nBujrcBCgpH2WFDp8CDGixIkUK1q8iDGjCsaNHDt6/AhyYwEAIfkEBAoA/wAsAAAAAEAAQAAAAuOEj6nL7Q+jnLTai7PevPsPhuJIluaJHkPaDW7yspMbA7Qs0bGOI7XP061UvxIPKDzabighMRl0pqDU6nBqzRZPWm2vW+0twUkxmYo7o1nqNfY6Nux+zGbxWoPH343tk+0np4cE6KeENEgi9VQnGDiSFSAZYJVGNTnpVtiWaAeFCSXGeCbK2fhm2gmZemjEuuj62hqSpdBlUrkQOgtyA2sLq8oB9wvcKKyhxwtziJyhfKrbrEhM16z0OFzdqumsbZP5MBCeTTsumX1OWW4exKwp6hgdT19vf4+fr7/P3+//D1BDAQAh+QQECgD/ACwAAAAAQABAAAAC+ISPqcvtD6OctNqLs968+w+G4khGQxkOarKikwrHJ+xKrWzIbX2sO4DD5Wi1GEtnHBJLuh7S2PyBTsCnFdkbUavX7jYn2nq9rNRxjFV8OWv0c7HWxN3vsqdNTyPimW++vnfn90N0QyjFd4HX5pS1d3h31iD16PexOJnIFXhZyZd0ZtnptKRUyjU45YkU0BpwxTlKquPqCggUNvgHGRYqU6tXRYK4C6pVDDuMbMW0fJvrbNy8zONLGVw9m4hdLcTQlK394B0uDWfOg+4bTrrqzm5KDA4/YDtuz16PPwmcT36uDp7AgQQLGjyIMKHChQwbOnwIMaJEAAUAACH5BAQKAP8ALAAAAABAAEAAAAL9hI+pO+2zopw0Pohu3dw2/nUi5YzhiGYYWqbs6p7uBjPgDNZJe8gGj2PodjxgJigZqloPD1IR8v2aml70ubP6LlztSjn7NqdcahUATsnK7DYszSK65zVprE6fQ7HDfNv21OdXBogkONiVFQiFSKhoKNd41sMntzRFdnm0qEmJ+WO5CdnJmLRVSUpkWofqJWQ35jnqhRdLpgMn8uYW0Bvg9shJ++Dry7aHhRYpWSg87FDsGBwo6aecjFY9iJ2tTcd9630M/uxN7lF9XpG4ZKuObtft/t6exk6/TDKPL7++j/+vHj9Gu4BMGhiu1kGEP4wxcMgQCsQdEyP2qHixVyEuegM0JvFoUdWEeCFLmjyJMqXKlSxbunwJM6bMmTRRFgAAIfkEBAoA/wAsAAAAAEAAQAAAAv2Ej6nL7Q+jnLTai7PebfAfDWIygqZYAqgJoqXLUqmxHp6N1LHi1j2s+u0WOtqvZysOjcaj87UkBZ9UZFTVrFKD0VtWK6QtvV8wkBsjl8069UfNfuZY8LhzfiLNfLdi251RB5eEk7PXwjOj13H4lgjIxOCHqKeYRaQEWeFmlXR2KcXBSRVQGrAVKvr4Y2p6x0NpaKckFivL6hoGm7caR0TXa5fKuyZcCFw8W7vjMbuludHsLNeFeks9hl0J88k80onZfXX9AD5+C2F+Duqgvu736f5u/rpO5HpfCv2Oz9Nvn+9UwH3nBujrcBCgpH2WFDp8CDGixIkUK1q8iDGjCsaNHDt6/AhyYwEAIfkEBAoA/wAsAAAAAEAAQAAAAuOEj6nL7Q+jnLTai7PevPsPhuJIluaJHkPaDW7yspMbA7Qs0bGOI7XP061UvxIPKDzabighMRl0pqDU6nBqzRZPWm2vW+0twUkxmYo7o1nqNfY6Nux+zGbxWoPH343tk+0np4cE6KeENEgi9VQnGDiSFSAZYJVGNTnpVtiWaAeFCSXGeCbK2fhm2gmZemjEuuj62hqSpdBlUrkQOgtyA2sLq8oB9wvcKKyhxwtziJyhfKrbrEhM16z0OFzdqumsbZP5MBCeTTsumX1OWW4exKwp6hgdT19vf4+fr7/P3+//D1BDAQAh+QQECgD/ACwAAAAAQABAAAAC+ISPqcvtD6OctNqLs968+w+G4khGQxkOarKikwrHJ+xKrWzIbX2sO4DD5Wi1GEtnHBJLuh7S2PyBTsCnFdkbUavX7jYn2nq9rNRxjFV8OWv0c7HWxN3vsqdNTyPimW++vnfn90N0QyjFd4HX5pS1d3h31iD16PexOJnIFXhZyZd0ZtnptKRUyjU45YkU0BpwxTlKquPqCggUNvgHGRYqU6tXRYK4C6pVDDuMbMW0fJvrbNy8zONLGVw9m4hdLcTQlK394B0uDWfOg+4bTrrqzm5KDA4/YDtuz16PPwmcT36uDp7AgQQLGjyIMKHChQwbOnwIMaJEAAUAACH5BAQKAP8ALAAAAABAAEAAAAL9hI+pO+2zopw0Pohu3dw2/nUi5YzhiGYYWqbs6p7uBjPgDNZJe8gGj2PodjxgJigZqloPD1IR8v2aml70ubP6LlztSjn7NqdcahUATsnK7DYszSK65zVprE6fQ7HDfNv21OdXBogkONiVFQiFSKhoKNd41sMntzRFdnm0qEmJ+WO5CdnJmLRVSUpkWofqJWQ35jnqhRdLpgMn8uYW0Bvg9shJ++Dry7aHhRYpWSg87FDsGBwo6aecjFY9iJ2tTcd9630M/uxN7lF9XpG4ZKuObtft/t6exk6/TDKPL7++j/+vHj9Gu4BMGhiu1kGEP4wxcMgQCsQdEyP2qHixVyEuegM0JvFoUdWEeCFLmjyJMqXKlSxbunwJM6bMmTRRFgAAIfkEBAoA/wAsAAAAAEAAQAAAAv2Ej6nL7Q+jnLTai7PebfAfDWIygqZYAqgJoqXLUqmxHp6N1LHi1j2s+u0WOtqvZysOjcaj87UkBZ9UZFTVrFKD0VtWK6QtvV8wkBsjl8069UfNfuZY8LhzfiLNfLdi251RB5eEk7PXwjOj13H4lgjIxOCHqKeYRaQEWeFmlXR2KcXBSRVQGrAVKvr4Y2p6x0NpaKckFivL6hoGm7caR0TXa5fKuyZcCFw8W7vjMbuludHsLNeFeks9hl0J88k80onZfXX9AD5+C2F+Duqgvu736f5u/rpO5HpfCv2Oz9Nvn+9UwH3nBujrcBCgpH2WFDp8CDGixIkUK1q8iDGjCsaNHDt6/AhyYwEAIfkEBAoA/wAsAAAAAEAAQAAAAuOEj6nL7Q+jnLTai7PevPsPhuJIluaJHkPaDW7yspMbA7Qs0bGOI7XP061UvxIPKDzabighMRl0pqDU6nBqzRZPWm2vW+0twUkxmYo7o1nqNfY6Nux+zGbxWoPH343tk+0np4cE6KeENEgi9VQnGDiSFSAZYJVGNTnpVtiWaAeFCSXGeCbK2fhm2gmZemjEuuj62hqSpdBlUrkQOgtyA2sLq8oB9wvcKKyhxwtziJyhfKrbrEhM16z0OFzdqumsbZP5MBCeTTsumX1OWW4exKwp6hgdT19vf4+fr7/P3+//D1BDAQAh+QQECgD/ACwAAAAAQABAAAAC+ISPqcvtD6OctNqLs968+w+G4khGQxkOarKikwrHJ+xKrWzIbX2sO4DD5Wi1GEtnHBJLuh7S2PyBTsCnFdkbUavX7jYn2nq9rNRxjFV8OWv0c7HWxN3vsqdNTyPimW++vnfn90N0QyjFd4HX5pS1d3h31iD16PexOJnIFXhZyZd0ZtnptKRUyjU45YkU0BpwxTlKquPqCggUNvgHGRYqU6tXRYK4C6pVDDuMbMW0fJvrbNy8zONLGVw9m4hdLcTQlK394B0uDWfOg+4bTrrqzm5KDA4/YDtuz16PPwmcT36uDp7AgQQLGjyIMKHChQwbOnwIMaJEAAUAACH5BAQKAP8ALAAAAABAAEAAAAL9hI+pO+2zopw0Pohu3dw2/nUi5YzhiGYYWqbs6p7uBjPgDNZJe8gGj2PodjxgJigZqloPD1IR8v2aml70ubP6LlztSjn7NqdcahUATsnK7DYszSK65zVprE6fQ7HDfNv21OdXBogkONiVFQiFSKhoKNd41sMntzRFdnm0qEmJ+WO5CdnJmLRVSUpkWofqJWQ35jnqhRdLpgMn8uYW0Bvg9shJ++Dry7aHhRYpWSg87FDsGBwo6aecjFY9iJ2tTcd9630M/uxN7lF9XpG4ZKuObtft/t6exk6/TDKPL7++j/+vHj9Gu4BMGhiu1kGEP4wxcMgQCsQdEyP2qHixVyEuegM0JvFoUdWEeCFLmjyJMqXKlSxbunwJM6bMmTRRFgAAIfkEBAoA/wAsAAAAAEAAQAAAAv2Ej6nL7Q+jnLTai7PebfAfDWIygqZYAqgJoqXLUqmxHp6N1LHi1j2s+u0WOtqvZysOjcaj87UkBZ9UZFTVrFKD0VtWK6QtvV8wkBsjl8069UfNfuZY8LhzfiLNfLdi251RB5eEk7PXwjOj13H4lgjIxOCHqKeYRaQEWeFmlXR2KcXBSRVQGrAVKvr4Y2p6x0NpaKckFivL6hoGm7caR0TXa5fKuyZcCFw8W7vjMbuludHsLNeFeks9hl0J88k80onZfXX9AD5+C2F+Duqgvu736f5u/rpO5HpfCv2Oz9Nvn+9UwH3nBujrcBCgpH2WFDp8CDGixIkUK1q8iDGjCsaNHDt6/AhyYwEAIfkEBAoA/wAsAAAAAEAAQAAAAuOEj6nL7Q+jnLTai7PevPsPhuJIluaJHkPaDW7yspMbA7Qs0bGOI7XP061UvxIPKDzabighMRl0pqDU6nBqzRZPWm2vW+0twUkxmYo7o1nqNfY6Nux+zGbxWoPH343tk+0np4cE6KeENEgi9VQnGDiSFSAZYJVGNTnpVtiWaAeFCSXGeCbK2fhm2gmZemjEuuj62hqSpdBlUrkQOgtyA2sLq8oB9wvcKKyhxwtziJyhfKrbrEhM16z0OFzdqumsbZP5MBCeTTsumX1OWW4exKwp6hgdT19vf4+fr7/P3+//D1BDAQAh+QQEFAD/ACwAAAAAQABAAAACzYSPqcvtD6OctNqLs968+w+G4kiW5okiQ9oNbvKykxsDtCzRsY6rq6JbBX2/E48YvBmORmYyaRumntRqEWXNKllaba9b7UXB0C/5iTtTZeo1tzZe/rbxKdx2qF3r2LuvQWcS+McwSMKEtIAouFiWZ3hoFTAZYJVGRUnpxtYG2fSUGcbZKcVIilZyahmpisra6vnRKvbo5iomKldqdjsWa9q7y3srfLnpuze8W4xLo9lLqxK6pBmtKDUwbQ3huO39DR4uPk5ebn6Onq4uXgAAIfkEBBQA/wAsAAAAAEAAQAAAAtCEj6nL7Q+jnLTai7PevPsPhuJIluaJIkPaDW7yspMbA7Qs0bGOq6uiWwV9vxOPGLwZjkZmMmkbpp7UahFlzSpZWm2vW+1FwdAv+Yk7U2XqNbc2Xv628Sncdqhd69i7r0FnEvjHMEjChLSAKLhYlmd4aBUwGWCVRkVJ6cbWBtn0lBnG2SnFSIpWcmoZqYrK2ur50Sr26Frr9+YIs5jLi7TXi3sLbOc7TDsmLBf7ebWKvDw4oAltQ60Yijx9DVRqZlwdLj5OXm5+jp6uvs7ezl4AACH5BAQUAP8ALAAAAABAAEAAAALShI+py+0Po5y02ouz3rz7D4biSJbmiSJD2g1u8rKTGwO0LNGxjqurolsFfb8Tjxi8GY5GZjJpG6ae1GoRZc0qWVptr1vtRcHQL/mJO1Nl6jW3Nl7+tvEp3HaoXevYu69BZxL4xzBIwoS0gCi4WJZneGgVMBlglUZFSenG1gbZ9JSJJibXNtrpGXnqV6Iq9dmK6gHrOJIF5MUapgi1GHLjuttrFwvMuQoj3HeMtPd2BVzs3Cj6pfkwYF2dDRhqlvz4PSo+Tl5ufo6err7O3u7+PlIAACH5BAQUAP8ALAAAAABAAEAAAALMhI+py+0Po5y02ouz3rz7D4biSJbmiR5D2g1u8rKTGwO0LNGxjiO1z9OtVL8SDyg82m4oITEZdKag1Opwas0WT1ptr1vtLcFJMZmKO6NZ6jX2Ojbsfsxm8VqDx9+N7ZPtJ6eHBOinhDRIIvVUJxg4khUgGWCVRjU56VbYlmgHhRkmwwnlOVpmZBoKmaopwnpqwirGuEg7O1aL2MkFu5C7+Yi7G/ure1tse9xYeUs7OJDZbBPtC3ps7YtcGizd7f0NHi4+Tl5ufo6efl4AACH5BAQUAP8ALAAAAABAAEAAAALNhI+py+0Po5y02ouz3rz7D4biSJbmiR5D2g1u8rKTGwO0LNGxjiO1z9OtVL8SDyg82m4oITEZdKag1Opwas0WT1ptr1vtLcFJMZmKO6NZ6jX2Ojbsfsxm8VqDx9+N7ZPtJ6eHBOinhDRIIvVUJxg4khUgGWCVRjU56VbYlmgHhRkmwwnlOVpmZBoKmaopwnpqwirGeEo6OwaL22hpS9tZmqt7q7sofFtJO0zcWHxMk9mrrAIqlymNuEN93de87f0NHi4+Tl5ufo6ers5QAAAh+QQEFAD/ACwAAAAAQABAAAAC0oSPqcvtD6OctNqLs968+w+G4kiW5okiQ9oNbvKykxsDtCzRsY6rq6JbBX2/E48YvBmORmYyaRumntRqEWXNKllaba9b7UXB0C/5iTtTZeo1tzZe/rbxKdx2qF3r2LuvQWcS+McwSMKEtIAouFiWZ3hoFTAZYJVGRUnpxtYG2fSUiSYm1zba6Rl56leiKvXZiuoB6ziSBeTFGqYItRhy47rbaxcLzLkKI9x3jLT3dgVc7Nwo+qX5MGBdnQ0Yapb8+D0qPk5ebn6Onq6+zt7u/j5SAAAh+QQEFAD/ACwAAAAAQABAAAACzISPqcvtD6OctNqLs968+w+G4kiW5okeQ9oNbvKykxsDtCzRsY4jtc/TrVS/Eg8oPNpuKCExGXSmoNTqcGrNFk9aba9b7S3BSTGZijujWeo19jo27H7MZvFag8ffje2T7SenhwTop4Q0SCL1VCcYOJIVIBlglUY1OelW2JZoB4UZJsMJ5TlaZmQaCpmqKcJ6asIqxrhIOztWi9jJBbuQu/mIuxv7q3tbbHvcWHlLOziQ2WwT7Qt6bO2LXBos3e39DR4uPk5ebn6Onn5eAAAh+QQEFAD/ACwAAAAAQABAAAACzYSPqcvtD6OctNqLs968+w+G4kiW5okeQ9oNbvKykxsDtCzRsY4jtc/TrVS/Eg8oPNpuKCExGXSmoNTqcGrNFk9aba9b7S3BSTGZijujWeo19jo27H7MZvFag8ffje2T7SenhwTop4Q0SCL1VCcYOJIVIBlglUY1OelW2JZoB4UZJsMJ5TlaZmQaCpmqKcJ6asIqxnhKOjsGi9toaUvbWZqre6u7KHxbSTtM3Fh8TJPZq6wCKpcpjbhDfd3XvO39DR4uPk5ebn6Onq7OUAAAIfkEBBQA/wAsAAAAAEAAQAAAAtKEj6nL7Q+jnLTai7PevPsPhuJIluaJIkPaDW7yspMbA7Qs0bGOq6uiWwV9vxOPGLwZjkZmMmkbpp7UahFlzSpZWm2vW+1FwdAv+Yk7U2XqNbc2Xv628Sncdqhd69i7r0FnEvjHMEjChLSAKLhYlmd4aBUwGWCVRkVJ6cbWBtn0lIkmJtc22ukZeepXoir12YrqAes4kgXkxRqmCLUYcuO622sXC8y5CiPcd4y093YFXOzcKPql+TBgXZ0NGGqW/Pg9Kj5OXm5+jp6uvs7e7v4+UgAAIfkEBAoA/wAsAAAAAEAAQAAAAuiEj6nL7Q+jnLTai7PevPsPhuJIliY0nN/AJq0apQbbpvQsw0tN2z2uA+J8tx7xpvoVjUYAE9Z0MqdPKPU6DWK3SB2XGxx+q1Dx+Jd8nanJw5rtLPGWcLOUxLtv71L0KP/wZTIHtid31JSo+BIXQrj42MfY2OEjeXkJiZBTaTMkSQSK2LXiqUQnijbp+HbVZ5VVyHnSShqWajibZiY4o1WboztYKzTIe8ZHOzqWnKZmeOuyuunmJ4wH/OrFLH19+Ba9uRYubptF7kKJLoHE6H1bdbTO4DpPP22fr7/P3+//DzCgwIEEPxQAACH5BAQKAP8ALAAAAABAAEAAAALohI+py+0Po5y02ouz3rz7D4biSJbmNJzYkCJsq0Ks8QLpC8N27Lb4jbPldKYfsPYT+mYqo9I4Q9Zi0GrwSSxZt04ellv1fsFdL9kqpp2hNN46rGy+2W0tthdOMknd6FYIuDdCJgNU9LcG+GH49HWHJshx9Bikl5e1cVW5ycRpiLkCaXnk56MI0ilK2sgYIjUHp0V6SZcGO2Wm9iY2tHt60gtrtiTMO+sLKlI692vLpZuMepBUt4Ard5w4nKWdNgbmjXcWLn59Rx5xg249TbxujQQduY72Xhhtn6+/z9/v/w8woMCBBDEUAAAh+QQECgD/ACwAAAAAQABAAAAC6ISPqcvtD6OctNqLs968+w+G4kiWJjSc38AmrRqlBtum9CzDS03bPa4D4ny3HvGm+hWNRgAT1nQyp08o9ToNYrdIHZcbHH6rUPH4l3ydqcnDmu0s8ZZws5TEu2/vUvQo//BlMge2J3fUlKj4EhdCuPjYx9jY4SN5eQmJkFNpMyRJBIrYteKpRCeKNun4dtVnlVXIedJKGpZqOJtmJjijVZujO1grNMh7xkc7OpacpmZ467K66eYnjAf86sUsfX34Fr25Fi5um0XuQokugcTofVt1tM7gOk8/bZ+vv8/f7/8PMKDAgQQ/FAAAIfkEBAoA/wAsAAAAAEAAQAAAAuiEj6nL7Q+jnLTai7PevPsPhuJIluY0nNiQImyrQqzxAukLw3bstviNs+V0ph+w9hP6Ziqj0jhD1mLQavBJLFm3Th6WW/V+wV0v2SqmnaE03jqsbL7ZbS22F04ySd3oVgi4N0ImA1T0twb4Yfj0dYcmyHH0GKSXl7VxVbnJxGmIuQJpeeTnowjSKUrayBgiNQenRXpJlwY7Zab2Jja0e3rSC2u2JMw76wsqUjr3a8ulm4x6kFS3gCt3nDicpZ02BuaNdxYufn1HHnGDbj1NvAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADs=">];

    my $model = _build_model();
    my $image = $model->deal_with_images( {topic_mid=>$topic_mid, field=>$field}  );
    my $img_id;

    is $image =~ qq{<img class="bali-topic-editor-image" src="/topic/img/.+">}, 1;

};

subtest 'deal_with_images: returns field in image format without src' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.description",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.description",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'asignada',
                    },
                    "key" => "fieldlet.system.users",
                    name  => 'Asiganada',
                }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic',
        asignada    => $user->mid
    );

    my $field  = q[<img "fsavewaeqwefqwfeewfqwfwq">];

    my $model = _build_model();
    my $image = $model->deal_with_images( {topic_mid=>$topic_mid, field=>$field}  );
    my $img_id;

    is $image =~ qq{ class="bali-topic-editor-image" .+}, 1;

};

done_testing();

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',          'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic', 'Baseliner::Model::Rules',
        'BaselinerX::Type::Statement'
    );

    TestUtils->cleanup_cis;

    mdb->event->drop;
    mdb->activity->drop;
    mdb->rule->drop;
    mdb->role->drop;
    mdb->category->drop;
    mdb->label->drop;
    mdb->topic->drop;
    mdb->activity->drop;
    mdb->index_all('topic');
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

sub from_base64 {
    require MIME::Base64;
    return  MIME::Base64::decode_base64( shift );
}