use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::Role::CI::ProjectSecurity';

subtest 'toggle_roles_projects: assigns new roles and projects' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );

    my $id_role2 = TestSetup->create_role;
    my $project2 = TestUtils->create_ci('project');
    my $area2    = TestUtils->create_ci('area');

    $user->toggle_roles_projects(
        action   => 'assign',
        roles    => [ $id_role2, 999, $id_role2 ],
        projects => [ 999, $project2->mid, $project2->mid, $area2->mid ]
    );

    $user = ci->new( $user->{mid} );

    is_deeply $user->project_security,
      {
        $id_role => {
            project => [ $project->mid ]
        },
        $id_role2 => {
            project => [ $project2->mid ],
            area    => [ $area2->mid ]
        }
      };
};

subtest 'toggle_roles_projects: unassigns roles and projects' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );

    $user->toggle_roles_projects(
        action   => 'unassign',
        roles    => [$id_role],
        projects => [ $project->mid ]
    );

    $user = ci->new( $user->{mid} );

    is_deeply $user->project_security, {};
};

subtest 'delete_roles: deletes roles' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );

    $user->delete_roles( roles => [$id_role] );

    $user = ci->new( $user->{mid} );

    is_deeply $user->project_security, {};
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',    'BaselinerX::Type::Menu',
        'Baseliner::Controller::User', 'Baseliner::Controller::Role',
    );

    TestUtils->register_ci_events();

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;
}
