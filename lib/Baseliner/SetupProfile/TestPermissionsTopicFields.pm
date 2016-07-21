package Baseliner::SetupProfile::TestPermissionsTopicFields;
use strict;
use warnings;
use base 'Baseliner::SetupProfile::Base';

BEGIN { unshift @INC, 't/lib' }

use TestSetup;
use TestUtils;

use Baseliner::SetupProfile::Reset;

sub setup {
    my $self = shift;

    Baseliner::SetupProfile::Reset->new->setup;

    my $bl_common = TestUtils->create_ci( 'bl', name => 'Common', bl => '*' );
    my $bl_qa     = TestUtils->create_ci( 'bl', name => 'QA',     bl => 'QA' );
    my $bl_prod   = TestUtils->create_ci( 'bl', name => 'PROD',   bl => 'PROD' );

    my $status_new = TestUtils->create_ci(
        'status',
        name => 'New',
        type => 'I',
        bls  => [ $bl_common->mid ]
    );
    my $status_in_progress = TestUtils->create_ci(
        'status',
        name => 'In Progress',
        type => 'G',
        bls  => [ $bl_common->mid ]
    );
    my $status_finished = TestUtils->create_ci(
        'status',
        name => 'Finished',
        type => 'D',
        bls  => [ $bl_qa->mid ]
    );
    my $status_closed = TestUtils->create_ci( 'status', name => 'Closed', type => 'F' );

    my $id_changeset_rule     = TestSetup->create_rule_form_changeset();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
        id_status    => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project  = TestUtils->create_ci_project( name => 'Project' );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status_new,
        username    => 'root',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanEditTopics',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.edit' }
            ]
        },
        project  => $project,
        username => 'can_edit_topics',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanEditTopicFields',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.edit' },
                { action => 'action.topics.changeset.edit' },
                { action => 'action.topicsfield.changeset.project.new.write' },
                { action => 'action.topicsfield.changeset.release.new.write' },
            ]
        },
        project  => $project,
        username => 'can_edit_topic_fields',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeSomeTopicFields',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.edit' },
                { action => 'action.topics.changeset.edit' },
                { action => 'action.topicsfield.changeset.release.new.read' },
            ]
        },
        project  => $project,
        username => 'can_see_some_topic_fields',
    );
}

1;
