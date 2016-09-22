use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'BaselinerX::CI::topic';

subtest 'activity: filters field updates based on user permissions' => sub {
    _setup();

    my $id_rule     = TestSetup->create_common_topic_rule_form();
    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    Baseliner::Model::Topic->new->update(
        {
            username    => 'root',
            topic_mid   => $topic_mid,
            action      => 'update',
            title       => 'New Title',
            description => 'New Description'
        }
    );

    my $topic = ci->new($topic_mid);

    my $activity = $topic->activity( { username => $user->username } );

    ok !grep { $_->{text} =~ m/description/ } @$activity;
};

subtest 'activity: returns field updates allowed to user' => sub {
    _setup();

    my $id_rule     = TestSetup->create_common_topic_rule_form();
    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topicsfield.read',
                bounds =>
                  [ { id_category => $id_category, id_status => $status->id_status, id_field => 'description' } ]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    Baseliner::Model::Topic->new->update(
        {
            username    => 'root',
            topic_mid   => $topic_mid,
            action      => 'update',
            title       => 'New Title',
            description => 'New Description'
        }
    );

    my $topic = ci->new($topic_mid);

    my $activity = $topic->activity( { username => $user->username } );

    ok grep { $_->{text} =~ m/description/ } @$activity;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Registor',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
    );

    TestUtils->cleanup_cis;

    mdb->activity->drop;
}
