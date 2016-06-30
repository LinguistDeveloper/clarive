package Baseliner::SetupProfile::TestPermissionsUser;
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
            role    => 'CanChangePassword',
            actions => [ { action => 'action.change_password' } ]
        },
        project  => $project,
        username => 'can_change_password',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSurrogate',
            actions => [ { action => 'action.surrogate' } ]
        },
        project  => $project,
        username => 'can_surrogate',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanSeeMenu',
            actions => [ { action => 'action.home.show_menu' } ]
        },
        project  => $project,
        username => 'can_see_menu',
    );
}

1;
