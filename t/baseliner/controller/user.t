use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst';

BEGIN {
    TestEnv->setup;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::User;
use Baseliner::Model::Permissions;

subtest 'infoactions: non admin user is not allowed to query other users action' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'root' } } );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
};

subtest 'infoactions: same user is allowed to query his own actions' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'test' } } );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infoactions: root user is allowed to query any user actions' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'test' } }, username => 'root' );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: non admin user is not allowed to query other users detail' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'root' } }, username => 'test' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
};

subtest 'infodetail: non admin user is not allowed to query role details' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { id_role => 1 };

    my $c = _build_c( req => { params => { id_role => 1 } }, username => 'test' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
};

subtest 'infodetail: same user is allowed to query his own details' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'test' } }, username => 'test' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'test' } }, username => 'root' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id_role => 1 } }, username => 'root' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'identicon: when no user generate identican anyway' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c();

    my $png = $controller->identicon($c, 'unknown');

    like $png, qr/^.PNG/;
};

subtest 'identicon: when user found return png' => sub {
    _setup();

    my $user = TestUtils->create_ci('user', username => 'developer');

    my $controller = _build_controller();

    my $c = _build_c();

    my $png = $controller->identicon($c, 'developer');

    like $png, qr/^.PNG/;
};

subtest 'identicon: when user found save to user' => sub {
    _setup();

    my $user = TestUtils->create_ci('user', username => 'developer');

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->identicon($c, 'developer');

    $user = ci->new($user->{mid});

    like $user->avatar, qr/^.PNG/;
};

sub _build_c {
    mock_catalyst_c( username => 'test', model => 'Baseliner::Model::Permissions', @_ );
}

sub _setup {

    Baseliner::Core::Registry->clear();
    TestUtils->register_ci_events();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::User->new( application => '' );
}

done_testing;
