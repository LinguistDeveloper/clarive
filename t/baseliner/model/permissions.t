use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::Model::Permissions';

subtest 'user_can_search_ci: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 0;
};

subtest 'user_can_search_ci: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.search.ci' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 1;
};

subtest 'user_can_search_ci: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions(username => 'root');

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 1;
};

subtest 'user_is_ci_admin: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_is_ci_admin( $user->username ), 0;
};

subtest 'user_is_ci_admin: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.admin'}]);

    my $permissions = _build_permissions();

    is $permissions->user_is_ci_admin( $user->username ), 1;
};

subtest 'user_is_ci_admin: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions(username => 'root');

    my $permissions = _build_permissions();

    is $permissions->user_is_ci_admin( $user->username ), 1;
};

subtest 'user_can_admin_ci: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 0;
};

subtest 'user_can_admin_ci: false when no collection' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.admin.%.variable'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 0;
};

subtest 'user_can_admin_ci: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.admin.%.variable'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username, 'variable' ), 1;
};

subtest 'user_can_admin_ci: true when ci admin' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.admin'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 1;
};

subtest 'user_can_admin_ci: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions(username => 'root');

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 1;
};

subtest 'user_can_view_ci: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 0;
};

subtest 'user_can_view_ci: false when no collection' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.view.%.variable'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 0;
};

subtest 'user_can_view_ci: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.view.%.variable'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username, 'variable' ), 1;
};

subtest 'user_can_view_ci: true when ci collection admin' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.admin.%.variable'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username, 'variable' ), 1;
};

subtest 'user_can_view_ci: true when ci admin' => sub {
    _setup();

    my $user = _create_user_with_actions(actions => [{action => 'action.ci.admin'}]);

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 1;
};

subtest 'user_can_view_ci: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions(username => 'root');

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 1;
};

done_testing();

sub _create_user_with_actions {
    my (%params) = @_;

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => delete $params{actions} || [] );

    return TestSetup->create_user( id_role => $id_role, project => $project, %params );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',          'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic', 'Baseliner::Model::Rules'
    );

    TestUtils->cleanup_cis;

}

sub _build_permissions {
    return Baseliner::Model::Permissions->new;
}
