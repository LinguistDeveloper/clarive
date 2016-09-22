package Baseliner::SetupProfile::TestPermissionsExplorerCI;
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

    TestUtils->create_ci( 'ssh_agent', name => 'SSH' );

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
            role    => 'CanViewSSHAgentCI',
            actions => [
                { action => 'action.home.show_lifecycle' },
                {
                    action => 'action.ci.view',
                    bounds => [ { role => 'Baseliner::Role::CI::Agent', collection => 'ssh_agent' } ]
                },
            ]
        },
        project  => $project,
        username => 'can_view_ssh_agent_ci',
    );

    TestSetup->create_user(
        id_role => {
            role    => 'CanEditSSHAgentCI',
            actions => [
                { action => 'action.home.show_lifecycle' },
                {
                    action => 'action.ci.admin',
                    bounds => [ { role => 'Baseliner::Role::CI::Agent', collection => 'ssh_agent' } ]
                },
            ]
        },
        project  => $project,
        username => 'can_edit_ssh_agent_ci',
    );
}

1;
