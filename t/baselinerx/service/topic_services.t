use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;
use TestUtils ':catalyst';

use Baseliner::Utils qw(_load _file);

use_ok 'BaselinerX::Service::TopicServices';

subtest 'get_with_condition: returns topics with alphanumeric ids' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'G' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'G' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finish',  type => 'G' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_release_rule,
        id_status => [ $status->mid, $status2->mid, $status3->mid ]
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_release_category } ]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Topic_Test',
        status      => $status
    );

    my $topic_mid_1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Topic_Test_2',
        status      => $status2
    );

    my $topic_mid_2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Topic_Test_3',
        status      => $status3
    );

    my $config = {
        categories    => $id_release_category,
        statuses      => [ $status->{id_status}, $status2->{id_status}, $status3->{id_status} ],
        assigned_to   => 'any',
        not_in_status => ''
    };

    my $c = mock_catalyst_c( stash => { username => $user->{username} } );

    my $gs = _build_topic_services();

    my @data = $gs->get_with_condition( $c, $config );

    is $data[0][0]->{title}, 'Topic_Test';
    is $data[0][1]->{title}, 'Topic_Test_2';
    is $data[0][2]->{title}, 'Topic_Test_3';
};

subtest 'get_with_condition: returns topic filtering by not in status' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'G' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'G' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finish',  type => 'G' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name      => 'Category_1',
        id_rule   => $id_release_rule,
        id_status => [ $status->mid, $status2->mid, $status3->mid ]
    );

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category_1.view' } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Topic_1',
        status      => $status
    );

    my $topic_mid_1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Topic_2',
        status      => $status2
    );

    my $topic_mid_2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Topic_3',
        status      => $status3
    );

    my $config = {
        categories    => $id_release_category,
        statuses      => [ $status->{id_status}, $status2->{id_status}, $status3->{id_status} ],
        assigned_to   => 'any',
        not_in_status => 'on'
    };

    my $c = mock_catalyst_c( stash => { username => $user->{username} } );

    my $gs = _build_topic_services();
    my @data = $gs->get_with_condition( $c, $config );

    is $data[0][0]->{title}, undef;
};

subtest 'get_with_condition: returns topics filtering by current user' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'I' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finish',  type => 'I' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_release_rule,
        id_status => [ $status->mid, $status2->mid, $status3->mid ]
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_release_category } ]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        status      => $status,
        title       => "Topic"
    );

    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user->mid, rel_type => 'topic_users' } );

    my $config = {
        categories    => $id_release_category,
        statuses      => [ $status->{id_status}, $status2->{id_status}, $status3->{id_status} ],
        assigned_to   => 'current',
        not_in_status => ''
    };

    my $gs = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c( stash => { username => $user->{username} } );

    my @data = $gs->get_with_condition( $c, $config );

    is $data[0][0]->{title}, 'Topic';
};

subtest 'remove_file: croaks on missing topic_mid' => sub {
     _setup();

    my $service = _build_topic_services();

    like exception { $service->remove_file() }, qr/Missing or invalid parameter topic_mid/;
};

subtest 'remove_file: croaks on non existing asset' => sub {
     _setup();

    my $user = TestSetup->create_user();
    my $topic_mid = TestSetup->create_topic();

    my $service = _build_topic_services();
    my $config = {
        username => $user->username,
        topic_mid => $topic_mid,
        asset_mid => 'asset-1',
        remove    => 'asset_mid'
    };

    like exception { $service->remove_file(undef, $config) },
        qr/Error removing file from topic $topic_mid. Error: File id asset-1 not found/;
};

subtest 'remove_file: croaks on non existing field' => sub {
    _setup();

    my $user      = TestSetup->create_user();
    my $topic_mid = TestSetup->create_topic();

    my $service = _build_topic_services();
    my $config  = {
        username  => $user->username,
        topic_mid => $topic_mid,
        asset_mid => 'asset-1',
        fields    => 'test_file',
        remove    => 'fields'
    };

    like exception { $service->remove_file( undef, $config ) },
        qr/Error removing file from topic $topic_mid. Error: The related field does not exist for the topic: $topic_mid/;
};

subtest 'create: creates topic' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'I' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finish',  type => 'I' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_release_rule,
        id_status => [ $status->mid, $status2->mid, $status3->mid ]
    );

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view' } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $config = {
        category => $id_release_category,
        status   => $status->mid,
        username => $user->{username},
        title    => 'New Topic',
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c( stash => { username => $user->{username} } );

    my $topic_mid = $topic_services->create( $c, $config );

    ok $topic_mid;
    my $topic_ci = ci->new($topic_mid);

    is $topic_ci->{title},              'New Topic';
    is $topic_ci->{id_category_status}, $status->mid;
    is $topic_ci->{id_category},        $id_release_category;
};

subtest 'create: creates topic with category and status by name' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'I' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finish',  type => 'I' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_release_rule,
        id_status => [ $status->mid, $status2->mid, $status3->mid ]
    );

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view' } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $config = {
        category => 'Category',
        status   => 'New',
        username => $user->{username},
        title    => 'New Topic',
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c( stash => { username => $user->{username} } );

    my $topic_mid = $topic_services->create( $c, $config );

    ok $topic_mid;
    my $topic_ci = ci->new($topic_mid);

    is $topic_ci->{title},              'New Topic';
    is $topic_ci->{id_category_status}, $status->mid;
    is $topic_ci->{id_category},        $id_release_category;
};

subtest 'change_status: user has permissions to change statuses assigned in the workflow' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'I' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_rule  = TestSetup->create_rule_form();
    my $id_role  = TestSetup->create_role();
    my $workflow = [
        {   id_role        => $id_role,
            id_status_from => $status->id_status,
            id_status_to   => $status2->id_status,
            job_type       => 'promote'
        }
    ];
    my $id_category = TestSetup->create_category(
        name     => 'Category',
        id_rule  => $id_rule,
        workflow => $workflow
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Topic"
    );

    my $config = {
        topics     => [$topic_mid],
        old_status => $status->mid,
        new_status => $status2->mid,
        username   => $user->username
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c();

    $topic_services->change_status( $c, $config );

    my $topic_ci = ci->new($topic_mid);

    is $topic_ci->{id_category_status}, $status2->mid;
};

subtest 'change_status: user has no permissions to change statuses that are not assigned in the workflow' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres',  type => 'I' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finished', type => 'I' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_rule  = TestSetup->create_rule_form();
    my $id_role  = TestSetup->create_role();
    my $workflow = [
        {   id_role        => $id_role,
            id_status_from => $status->id_status,
            id_status_to   => $status2->id_status,
            job_type       => 'promote'
        }
    ];
    my $id_category = TestSetup->create_category(
        name     => 'Category',
        id_rule  => $id_rule,
        workflow => $workflow
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Topic"
    );

    my $config = {
        topics     => [$topic_mid],
        old_status => $status->mid,
        new_status => $status3->mid,
        username   => $user->username
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c();

    like exception { $topic_services->change_status( $c, $config ) },
        qr/has no permissions to change status from 'New' to 'Finished'/;
};

subtest 'change_status: throws when changing topic from not allowed status' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New',     type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'Progres', type => 'I' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Progres', type => 'I' );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_release_rule,
        id_status => [ $status->mid, $status2->mid, $status3->mid ]
    );

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view' } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        status      => $status,
        title       => "Topic"
    );

    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user->mid, rel_type => 'topic_users' } );

    my $config = {
        topics     => [$topic_mid],
        old_status => $status2->mid,
        new_status => $status3->mid
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c( stash => { username => $user->{username} } );

    like exception { $topic_services->change_status( $c, $config ) },
      qr/Current status is not in the valid old_status list/;
};

subtest 'change_status: throws when unknown status' => sub {
    _setup();

    my $config = {
        topics     => ['123'],
        new_status => '123'
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c( stash => {} );

    like exception { $topic_services->change_status( $c, $config ) }, qr/Status 123 does not exist in the system/;
};

subtest 'change_status: throws when unknown topic' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $config = {
        topics     => ['123'],
        new_status => $status->id_status
    };

    my $topic_services = BaselinerX::Service::TopicServices->new();

    my $c = mock_catalyst_c( stash => {} );

    like exception { $topic_services->change_status( $c, $config ) }, qr/Topic 123 does not exist in the system/;
};

subtest 'upload: uploads file' => sub {
    _setup();

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username = ci->user->find_one()->{username};

    my $doc_topic = mdb->topic->find_one({mid => $topic_mid});

    my $filename = 'my-file.txt';

    my $file   = TestUtils->create_temp_file( filename => $filename );
    my $fullpath = $file->stringify;
    my $config   = {
        mid      => $topic_mid,
        path     => $fullpath,
        username => $username,
        field    => 'test_file',
    };

    my $c = mock_catalyst_c( stash => { username => $username } );
    my $service = _build_topic_services();

    my $status = $service->upload( $c, $config );

    is $status, '200';
};

done_testing();

sub _build_topic_services {
    return BaselinerX::Service::TopicServices->new();
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            }
        ],
    );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::Service::TopicServices',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Rules'
    );

    TestUtils->cleanup_cis;

    mdb->topic->drop;
    mdb->category->drop;
}
