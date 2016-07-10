use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst);
use TestSetup;

use_ok 'Baseliner::Helper::Topic';

subtest 'topic_grid: returns topics' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field"   => "project",
                        "name_field" => "project",
                        meta_type    => 'project',
                        collection   => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field"   => "topic_grid",
                        "name_field" => "topic_grid",
                    },
                    "key" => "fieldlet.topic_grid",
                }
            }
        ],
    );
    my $id_changeset_category = TestSetup->create_category(
        name      => 'My Changeset',
        id_rule   => $id_changeset_rule,
        id_status => $status->mid
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    my $topic = ci->new($changeset_mid);
    my $meta  = $topic->get_meta;

    my ($meta_field) = grep { $_->{id_field} eq 'topic_grid' } @$meta;

    my $data = Baseliner::Model::Topic->new->get_data( $meta, $changeset_mid );

    my $c = _build_c( username => $user->username );

    my $helper = _build_helper( c => $c );

    my $grid = $helper->topic_grid( $meta_field, { topic_grid => $data } );

    is_deeply( $grid->{topics}->[0]->{name_category}, "My Changeset" );
    is_deeply( $grid->{topics}->[0]->{title},         "Fix everything" );
};

subtest 'topic_grid: returns correct headers' => sub {
    _setup();

    my $c = _build_c();
    my $helper = _build_helper( c => $c );

    cmp_deeply(
        $helper->topic_grid( { id_field => 'topic_grid' } )->{head},
        [
            {
                'name' => 'ID',
                'key'  => 'name'
            },
            {
                'name' => 'Title',
                'key'  => 'title'
            },
            {
                'name' => 'Status',
                'key'  => 'name_status'
            },
            {
                'key'  => 'created_by',
                'name' => 'Created By'
            },
            {
                'key'  => 'created_on',
                'name' => 'Created On'
            },
            {
                'key'  => 'modified_by',
                'name' => 'Modified By'
            },
            {
                'name' => 'Modified On',
                'key'  => 'modified_on'
            }
        ]
    );
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',                       'BaselinerX::Fieldlets',
        'BaselinerX::LcController',             'BaselinerX::Service::TopicServices',
        'BaselinerX::Type::Action',             'BaselinerX::Type::Event',
        'BaselinerX::Type::Config',             'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',          'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Model::ConfigStore', 'Baseliner::Model::Rules',
        'Baseliner::Model::Topic',              'Baseliner::Model::TopicExporter'
    );
    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->topic->drop;
}

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_helper {
    my (%params) = @_;

    Baseliner::Helper::Topic->new(%params);
}
