use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst);
use TestSetup;

use Baseliner::Model::Permissions;

use_ok 'Baseliner::Controller::Permissions';

subtest 'user_has_action: returns true when user has permission to do some action' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.admin.root' } ] );
    my $user    = TestSetup->create_user( username => 'test', id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => $user->username, action => 'action.admin.root' } } );

    $controller->user_has_action($c);

    my $stash = $c->stash->{json};

    ok $stash->{has};
};

subtest 'user_has_action: returns false when user has no permission to do some action' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'test', id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => $user->username, action => 'action.admin.root' } } );

    $controller->user_has_action($c);

    my $stash = $c->stash->{json};

    ok !$stash->{has};
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'Baseliner::Model::Permissions',
        'BaselinerX::CI',          'BaselinerX::Type::Action',

    );

    TestUtils->cleanup_cis;

    mdb->role->drop;
}

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_controller {
    Baseliner::Controller::Permissions->new( application => '' );
}
