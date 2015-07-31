use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils;

BEGIN {
    TestEnv->setup;
    $Carp::Verbose ++;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::User;
use Baseliner::Model::Permissions;

subtest 'infoactions: non admin user is not allowed to query other users action' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { username => 'root'};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'test' );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/)} }
};

subtest 'infoactions: same user is allowed to query his own actions' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { username => 'test'};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'test' );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { data => ignore()} }
};

subtest 'infoactions: root user is allowed to query any user actions' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { username => 'test'};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'root' );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { data => ignore()} }
};

subtest 'infodetail: non admin user is not allowed to query other users detail' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { username => 'root'};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'test' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/)} }
};

subtest 'infodetail: non admin user is not allowed to query role details' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { id_role => 1 };

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'test' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/)} }
};

subtest 'infodetail: same user is allowed to query his own details' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { username => 'test'};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'test' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { data => ignore()} }
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { username => 'test'};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'root' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { data => ignore()} }
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = { id_role => 1 };

    my $c = FakeContext->new( req => FakeRequest->new( params => $params) , username => 'root' );

    $controller->infodetail($c);

    cmp_deeply $c->stash, { json => { data => ignore()} }
};

sub _setup {
    Baseliner::Core::Registry->clear();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test');
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::User->new( application => '' );
}

done_testing;

package FakeRequest;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{params} = $params{params};

    return $self;
}

sub parameters { &params }
sub params     { shift->{params} }

package FakeResponse;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub status { }

package FakeContext;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{stash} = $params{stash} || {};
    $self->{req} = $params{req};
    $self->{username} = $params{username};

    return $self;
}

sub stash {
    my $self = shift;

    return $self->{stash} unless @_;

    if ( @_ == 1 ) {
        return $self->{stash}->{ $_[0] };
    }

    return $self->{stash}->{ $_[0] } = $_[1];
}

sub model {
    Baseliner::Model::Permissions->new();
}

sub username {
    shift->{username};
}

sub request { &req }
sub req     { shift->{req} }
sub res     { FakeResponse->new }
sub forward { 'FORWARD' }
