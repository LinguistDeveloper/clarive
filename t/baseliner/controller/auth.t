use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
use TestUtils ':catalyst';

BEGIN {
    TestEnv->setup;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::CI;
use Baseliner::Controller::Auth;

subtest 'login: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { } } );

    $controller->login($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Missing User',
            errors  => {
                login => 'Missing User',
            }
        }
      };
};

sub _build_c {
    mock_catalyst_c( @_ );
}

sub _setup {
    TestUtils->cleanup_cis;
    mdb->user_login_attempts->drop;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::Auth' );

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    my $controller = Baseliner::Controller::Auth->new( application => '' );
    $controller = Test::MonkeyMock->new($controller);

    return $controller;
}

done_testing;
