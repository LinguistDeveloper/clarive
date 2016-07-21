package Baseliner::SetupProfile::TestPermissionsTopic;
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
    my $project2 = TestUtils->create_ci_project( name => 'Project2' );

    TestSetup->create_user(
        id_role => {
            role    => 'Developer',
            actions => []
        },
        project  => $project,
        username => 'developer',
    );

    my $id_question_rule = _create_question_form();
    my $id_question_category = TestSetup->create_category(
        name         => 'Question',
        id_rule      => $id_question_rule,
        id_status    => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );
    my $question_mid      = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_question_rule,
        id_category => $id_question_category,
        title       => 'When?',
        status      => $status_new,
        username    => 'developer',
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status_new,
        username    => 'developer',
    );

    my $changeset_with_comments = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Topic With Comments',
        status      => $status_new,
        username    => 'developer',
    );

    TestSetup->create_comment( topic_mid => $changeset_with_comments, text => 'Hello there' );

    my $changeset_mid3 = TestSetup->create_topic(
        project     => $project2,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything 2',
        status      => $status_new
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeMenu',
            actions => [ { action => 'action.home.show_menu' } ]
        },
        project  => $project,
        username => 'can_see_menu',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeTopics',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.topics.changeset.view' } ]
        },
        project  => $project,
        username => 'can_see_topics',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanCreateTopics',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.create' }
            ]
        },
        project  => $project,
        username => 'can_create_topics',
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
            role    => 'CanDeleteTopics',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.delete' }
            ]
        },
        project  => $project,
        username => 'can_delete_topics',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanCommentOnTopics',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.delete' },
                { action => 'action.topics.changeset.comment' },
            ]
        },
        project  => $project,
        username => 'can_comment_on_topics',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeActivity',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.delete' },
                { action => 'action.topics.changeset.activity' },
            ]
        },
        project  => $project,
        username => 'can_see_activity',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeTopicJobs',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.topics.changeset.view' },
                { action => 'action.topics.changeset.delete' },
                { action => 'action.topics.changeset.jobs' },
            ]
        },
        project  => $project,
        username => 'can_see_topic_jobs',
    );
}

sub _create_question_form {
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_name => 'Question',
        rule_tree => [
            _build_stmt(
                id   => 'title',
                name => 'Title',
                type => 'fieldlet.system.title'
            ),
            _build_stmt(
                id   => 'description',
                name => 'Description',
                type => 'fieldlet.system.description'
            ),
            _build_stmt(
                id       => 'status_new',
                bd_field => 'id_category_status',
                name     => 'Status',
                type     => 'fieldlet.system.status_new'
            ),
            _build_stmt(
                id   => 'project',
                name => 'Project',
                type => 'fieldlet.system.projects'
            ),
        ],
    );
}

sub _build_stmt {
    my (%params) = @_;

    return {
        attributes => {
            active => 1,
            data   => {
                active       => 1,
                id_field     => $params{id},
                bd_field     => $params{bd_field} || $params{id},
                fieldletType => $params{type},
            },
            disabled       => \0,
            expanded       => 1,
            leaf           => \1,
            holds_children => \0,
            palette        => \0,
            key            => $params{type},
            name           => $params{name},
            text           => $params{name},
        },
        children => []
    };
}

1;
