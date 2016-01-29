use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::TempDir::Tiny;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::User;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_file _dir);

subtest
    'infoactions: non admin user is not allowed to query other users action'
    => sub {
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
    my $c          = _build_c(
        req      => { params => { username => 'test' } },
        username => 'root'
    );

    $controller->infoactions($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest
    'infodetail: non admin user is not allowed to query other users detail'
    => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'root' } },
        username => 'test'
    );

    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
    };

subtest 'infodetail: non admin user is not allowed to query role details' =>
    sub {
    _setup();

    my $controller = _build_controller();
    my $params     = { id_role => 1 };
    my $c          = _build_c(
        req      => { params => { id_role => 1 } },
        username => 'test'
    );

    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
    };

subtest 'infodetail: same user is allowed to query his own details' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'test' } },
        username => 'test'
    );
    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'test' } },
        username => 'root'
    );
    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { id_role => 1 } },
        username => 'root'
    );
    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'avatar: generates user avatar if it doesnt exit' => sub {
    _setup();

    my $tempdir = tempdir();

    my $c = _build_c( username => 'root', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $controller = _build_controller();
    $controller->avatar($c);

    my ($file) = $c->mocked_call_args('serve_static_file');

    ok -d "$tempdir/root/identicon";
    ok -f "$tempdir/root/identicon/root.png";

    like $file, qr{$tempdir/root/identicon/root.png};
    like _file($file)->slurp, qr/^.PNG/;
};

subtest 'avatar: returns avatar if exists' => sub {
    _setup();

    my $tempdir = tempdir();

    _dir("$tempdir/root/identicon")->mkpath;
    TestUtils->write_file("HELLO", "$tempdir/root/identicon/root.png");

    my $c = _build_c( username => 'root', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $controller = _build_controller();
    $controller->avatar($c);

    my ($file) = $c->mocked_call_args('serve_static_file');

    like $file, qr{$tempdir/root/identicon/root.png};
    is _file($file)->slurp, 'HELLO';
};

subtest 'avatar: returns default avatar when generation fails' => sub {
    _setup();

    my $tempdir = tempdir();

    _dir("$tempdir/root/static/images/icons/")->mkpath;
    TestUtils->write_file( "DEFAULT", "$tempdir/root/static/images/icons/user.png" );

    my $c = _build_c( username => 'root', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $identicon_generator = Test::MonkeyMock->new;
    $identicon_generator->mock( generate => sub { die 'some error' } );

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_identicon_generator => sub { $identicon_generator } );
    $controller->avatar($c);

    my ($file) = $c->mocked_call_args('serve_static_file');

    like $file, qr{$tempdir/root/static/images/icons/user.png};
    is _file($file)->slurp, 'DEFAULT';
};

sub _build_c {
    mock_catalyst_c(
        username => 'test',
        model    => 'Baseliner::Model::Permissions',
        @_
    );
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
