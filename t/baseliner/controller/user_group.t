use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use Capture::Tiny qw(capture);
use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_file _dir _array);

use_ok 'Baseliner::Controller::UserGroup';

subtest 'list: returns complete group list' => sub {
    _setup();

    my ( $prj, $user, $role ) = _setup_security();

    my $controller = _build_controller();

    my $ci_group  = TestUtils->create_ci( 'UserGroup', name => 'group1' );
    my $ci_group2 = TestUtils->create_ci( 'UserGroup', name => 'group2' );

    my $c = _build_c( username => 'root' );

    $controller->list($c);

    is $c->stash->{json}->{data}[0]->{groupname}, 'group1';
    is $c->stash->{json}->{data}[1]->{groupname}, 'group2';
    is @{ $c->stash->{json}->{data} }, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'list: returns complete group members list' => sub {
    _setup();

    my ( $prj, $user, $role ) = _setup_security();

    my $controller = _build_controller();

    my $ci_group  = TestUtils->create_ci( 'UserGroup', name => 'group1' );
    my $ci_group2 = TestUtils->create_ci( 'UserGroup', name => 'group2' );

    $user->groups( [ $ci_group, $ci_group2 ] );
    $user->save;

    my $c = _build_c( username => 'root' );

    $controller->list($c);

    is $c->stash->{json}->{data}[0]->{user_names}[0], 'test';
    is $c->stash->{json}->{data}[1]->{user_names}[0], 'test';
    is @{ $c->stash->{json}->{data}[0]->{user_names} }, 1;
    is @{ $c->stash->{json}->{data}[1]->{user_names} }, 1;
};

subtest 'list: returns group list with limit -1' => sub {
    _setup();

    my ( $prj, $user, $role ) = _setup_security();

    my $controller = _build_controller();

    my $ci_group  = TestUtils->create_ci( 'UserGroup', name => 'group1' );
    my $ci_group2 = TestUtils->create_ci( 'UserGroup', name => 'group2' );

    my $c = _build_c(
        req      => { params => { limit => -1 } },
        username => 'root'
    );

    $controller->list($c);

    is @{ $c->stash->{json}->{data} }, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'list: returns user list with limit 1' => sub {
    _setup();

    my ( $prj, $user, $role ) = _setup_security();

    my $controller = _build_controller();

    my $ci_group  = TestUtils->create_ci( 'UserGroup', name => 'group1' );
    my $ci_group2 = TestUtils->create_ci( 'UserGroup', name => 'group2' );

    my $c = _build_c(
        req      => { params => { limit => 1 } },
        username => 'root'
    );

    $controller->list($c);

    is @{ $c->stash->{json}->{data} }, 1;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'duplicate: fails without id_group' => sub {
    _setup();

    my ( $prj, $user, $role ) = _setup_security();

    my $controller = _build_controller();

    my $c = _build_c(
        req      => { params => {} },
        username => 'root'
    );

    $controller->duplicate($c);

    is $c->stash->{json}->{msg}, 'Error duplicating user group';
};

subtest 'duplicate: duplicates a user group' => sub {
    _setup();

    my ( $prj, $user, $role ) = _setup_security();

    my $controller = _build_controller();

    my $ci_group = TestUtils->create_ci( 'UserGroup', name => 'group1' );
    $ci_group->set_users($user);
    $ci_group->save;

    my $c = _build_c(
        req      => { params => { id_group => $ci_group->mid } },
        username => 'root'
    );

    $controller->duplicate($c);

    my $new_group = ci->UserGroup->search_ci( mid => { '$ne' => $ci_group->mid } );

    is_deeply [ map { $_->mid } _array $new_group->users ], [ $user->mid ];

    is $c->stash->{json}->{msg}, 'User group duplicated';

    $c = _build_c( username => 'root' );

    $controller->list($c);

    is @{ $c->stash->{json}->{data} }, 2;
    is $c->stash->{json}->{totalCount}, 2;
};

subtest 'update (add): add a user group' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req      => { params => { groupname => 'Test' } },
        username => 'root'
    );

    $controller->update($c);

    is $c->stash->{json}->{msg}, 'User group saved';

    $c = _build_c( username => 'root' );

    $controller->list($c);

    is @{ $c->stash->{json}->{data} }, 1;
    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'update (add): add a user group fails if groupname duplicated' => sub {
    _setup();

    my $controller = _build_controller();

    my $ci_group = TestUtils->create_ci( 'UserGroup', name => 'Test' );

    my $c = _build_c(
        req      => { params => { groupname => 'Test' } },
        username => 'root'
    );

    $controller->update($c);

    like $c->stash->{json}->{msg}, qr/validation failed/i;
    like $c->stash->{json}->{errors}->{groupname}, qr/User group name already exists/;
};

subtest 'update (update): update a user group fails if group not found' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req      => { params => { id => 'non-existent-group-id', groupname => 'unknown' } },
        username => 'root'
    );

    $controller->update($c);

    like $c->stash->{json}->{msg}, qr/Error saving user group/;
};

subtest 'update (update): update a user group fails if groupname already exists' => sub {
    _setup();

    my $ci_group  = TestUtils->create_ci( 'UserGroup', name => 'Test' );
    my $ci_group2 = TestUtils->create_ci( 'UserGroup', name => 'Test2' );

    my $controller = _build_controller();

    my $c = _build_c(
        req      => { params => { id => $ci_group2->mid, groupname => 'Test' } },
        username => 'root'
    );

    $controller->update($c);

    like $c->stash->{json}->{msg}, qr/validation failed/i;
    like $c->stash->{json}->{errors}->{groupname}, qr/User group name already exists/;
};

subtest 'update: updates user group' => sub {
    _setup();

    my $user = TestSetup->create_user;
    my $ci_group = TestUtils->create_ci( 'UserGroup', name => 'Test' );

    my $controller = _build_controller();

    my $c = _build_c(
        req => { params => { id => $ci_group->mid, groupname => 'Testrenamed', users => [$user->mid] } },
        username => 'root'
    );

    $controller->update($c);

    $ci_group = $ci_group->search_ci( mid => $ci_group->mid );

    is_deeply [ map { $_->mid } _array $ci_group->users ], [ $user->mid ];

    like $c->stash->{json}->{msg}, qr/User group saved/;

    $c = _build_c( username => 'root' );

    $controller->list($c);

    is $c->stash->{json}->{data}[0]->{groupname}, 'Testrenamed';
};

subtest 'delete: fails if no group id' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req      => { params => { } },
        username => 'root'
    );

    $controller->delete($c);

    like $c->stash->{json}->{msg}, qr/Missing id/;
};

subtest 'delete: deletes the group' => sub {
    _setup();

    my $ci_group  = TestUtils->create_ci( 'UserGroup', name => 'Test' );
    my $ci_group2 = TestUtils->create_ci( 'UserGroup', name => 'Test2' );

    my $controller = _build_controller();

    my $c = _build_c(
        req      => { params => { id => $ci_group->mid } },
        username => 'root'
    );

    $controller->delete($c);

    like $c->stash->{json}->{msg}, qr/User group deleted/;

    $c = _build_c( username => 'root' );

    $controller->list($c);

    is @{ $c->stash->{json}->{data} }, 1;
    is $c->stash->{json}->{totalCount}, 1;
};

done_testing;

sub _build_c {
    mock_catalyst_c(
        username => 'test',
        model    => 'Baseliner::Model::Permissions',
        @_
    );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',    'BaselinerX::Type::Menu',
        'Baseliner::Controller::User', 'Baseliner::Controller::Role'
    );

    TestUtils->register_ci_events();
    TestUtils->cleanup_cis();
}

sub _setup_security {
    my $ci_prj  = TestUtils->create_ci( 'project', name => 'test' );
    my $ci_user = TestUtils->create_ci( 'user',    name => 'test' );
    my $role    = TestSetup->create_role(role => 'Test role 1');

    $ci_prj->save();
    $ci_user->save();

    return ( $ci_prj, $ci_user, $role );
}

sub _build_controller {
    Baseliner::Controller::UserGroup->new( application => '' );
}
