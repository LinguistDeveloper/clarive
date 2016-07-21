package Baseliner::SetupProfile::TestPermissionsExplorer;
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
            role => 'Nobody',
        },
        project  => $project,
        username => 'nobody',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeLifecycle',
            actions => [ { action => 'action.home.show_lifecycle' } ]
        },
        project  => $project,
        username => 'can_see_lifecycle',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeLifecycleReleases',
            actions => [ { action => 'action.home.show_lifecycle' }, { action => 'action.home.view_releases' } ]
        },
        project  => $project,
        username => 'can_see_lifecycle_releases',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeLifecycleDashboards',
            actions => [ { action => 'action.home.show_lifecycle' }, { action => 'action.dashboards.view' } ]
        },
        project  => $project,
        username => 'can_see_lifecycle_dashboards',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeLifecycleReports',
            actions => [ { action => 'action.home.show_lifecycle' }, { action => 'action.reports.view' } ]
        },
        project  => $project,
        username => 'can_see_lifecycle_reports',
    );
}

1;
