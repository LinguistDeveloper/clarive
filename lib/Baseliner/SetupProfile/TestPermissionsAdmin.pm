package Baseliner::SetupProfile::TestPermissionsAdmin;
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

    my $project = TestUtils->create_ci_project( name => 'Project' );

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
            role    => 'CanSeeServerInfo',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.help.server_info' } ]
        },
        project  => $project,
        username => 'can_see_server_info',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminConfigList',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.config_list' } ]
        },
        project  => $project,
        username => 'can_admin_config_list',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminDaemons',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.daemon' } ]
        },
        project  => $project,
        username => 'can_admin_daemon',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminEvents',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.event' } ]
        },
        project  => $project,
        username => 'can_admin_event',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminNotifications',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.notification' } ]
        },
        project  => $project,
        username => 'can_admin_notification',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminRoles',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.role' } ]
        },
        project  => $project,
        username => 'can_admin_role',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminRules',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.rules' } ]
        },
        project  => $project,
        username => 'can_admin_rule',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminScheduler',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.scheduler' } ]
        },
        project  => $project,
        username => 'can_admin_scheduler',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminSemaphores',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.semaphore' } ]
        },
        project  => $project,
        username => 'can_admin_semaphore',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminSystemMessages',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.sms' } ]
        },
        project  => $project,
        username => 'can_admin_sms',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanUpgrade',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.upgrade' } ]
        },
        project  => $project,
        username => 'can_upgrade',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanAdminCategories',
            actions => [ { action => 'action.home.show_menu' }, { action => 'action.admin.topics' } ]
        },
        project  => $project,
        username => 'can_admin_categories',
    );
}

1;
