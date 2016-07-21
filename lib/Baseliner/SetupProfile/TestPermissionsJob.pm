package Baseliner::SetupProfile::TestPermissionsJob;
use strict;
use warnings;
use base 'Baseliner::SetupProfile::Base';

BEGIN { unshift @INC, 't/lib' }

use TestSetup;
use TestUtils;

use Capture::Tiny qw(capture);
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

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status_new,
        username    => 'root',
    );

    my $id_pipeline = TestSetup->create_rule_pipeline();

    my $job1 = BaselinerX::CI::job->new( id_rule => $id_pipeline, bl => 'QA', changesets => [$changeset_mid] );
    capture { $job1->save };

    my $changeset_mid2 = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Topic With Comments',
        status      => $status_new,
        username    => 'root',
    );

    my $job1 = BaselinerX::CI::job->new( id_rule => $id_pipeline, bl => 'PROD', changesets => [$changeset_mid2] );
    capture { $job1->save };

    my $changeset_mid3 = TestSetup->create_topic(
        project     => $project2,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything 2',
        status      => $status_new,
        username    => 'root',
    );

    my $job1 = BaselinerX::CI::job->new( id_rule => $id_pipeline, bl => 'QA', changesets => [$changeset_mid3] );
    capture { $job1->save };

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
            role    => 'CanSeeJobMonitor',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.job.view_monitor' } ]
        },
        project  => $project,
        username => 'can_see_job_monitor',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanCreateNewJobs',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.job.create' } ]
        },
        project  => $project,
        username => 'can_create_new_jobs',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanCreateNewJobsOutsideOfSlots',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.create' },
                { action => 'action.job.no_cal' },
            ]
        },
        project  => $project,
        username => 'can_create_new_jobs_outside_of_slots',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanChangePipeline',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.create' },
                { action => 'action.job.chain_change' }
            ]
        },
        project  => $project,
        username => 'can_change_pipeline',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeAllProjectJobs',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.view_monitor' },
                { action => 'action.job.viewall', bl => '*' }
            ]
        },
        project  => $project,
        username => 'can_see_project_jobs',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeJobsWithBl',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.view_monitor' },
                { action => 'action.job.viewall', bl => 'QA' }
            ]
        },
        project  => $project,
        username => 'can_see_jobs_with_bl',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeAdvancedJobMenu',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.view_monitor' },
                { action => 'action.job.viewall', bl => '*' },
                { action => 'action.job.advanced_menu' }
            ]
        },
        project  => $project,
        username => 'can_see_advanced_job_menu',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanRunJobInProcess',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.view_monitor' },
                { action => 'action.job.viewall', bl => '*' },
                { action => 'action.job.run_in_proc' }
            ]
        },
        project  => $project,
        username => 'can_run_job_in_process',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanRestartJob',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.view_monitor' },
                { action => 'action.job.viewall' },
                { action => 'action.job.restart' }
            ]
        },
        project  => $project,
        username => 'can_restart_job',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanDeleteJob',
            actions => [
                { action => 'action.home.show_menu' },
                { action => 'action.job.view_monitor' },
                { action => 'action.job.viewall' },
                { action => 'action.job.delete' }
            ]
        },
        project  => $project,
        username => 'can_delete_job',
    );
}

1;
