use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;
use TestUtils ':catalyst';

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

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view' } ] );

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
        'BaselinerX::Fieldlets',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Event',
        'BaselinerX::Service::TopicServices',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules'
    );
    TestUtils->cleanup_cis;

    mdb->topic->drop;
    mdb->category->drop;
}
