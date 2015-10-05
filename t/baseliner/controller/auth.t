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
use BaselinerX::Type::Event;
use BaselinerX::CI;
use Baseliner::Controller::Auth;

subtest 'login: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

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

subtest 'login: returns an error when ci not found' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => 'root', realm => 'local' },
        req => { params => { login => 'local/root', password => 'admin' } },
        model =>
          { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \0,
        msg     => "Login error: User not found: root\n",
        errors  => { login => "Login error: User not found: root\n" }
      };
};

subtest 'login: logs in local user' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => 'root', realm => 'local' },
        req => { params => { login => 'local/root', password => 'admin' } },
        model =>
          { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: reduces logins after failed ones' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        req => { params => { login => 'local/root', password => 'wrong' } },
        model =>
          { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success        => \0,
        msg            => 'Invalid User or Password',
        attempts_login => 5,
        block_datetime => 0,
        errors         => {
            login => 'Invalid User or Password'
        }
      };
};

subtest 'login: blocks user after failed attempts' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $controller = _build_controller();

    for ( 1 .. 6 ) {
        my $c = _build_c(
            req => { params => { login => 'local/wrong', password => 'wrong' } },
            model =>
              { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
        );

        $controller->login($c);
    }

    my $c = _build_c(
        req => { params => { login => 'local/wrong', password => 'wrong' } },
        model =>
          { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success           => \0,
        msg               => 'Attempts exhausted, please wait',
        attempts_duration => 5,
        attempts_login    => 0,
        block_datetime    => re('\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d'),
        errors            => {
            'login' => 'Attempts exhausted, please wait'
        }
      };
};

subtest 'login: logges in after block is expired' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $controller = _build_controller();

    for ( 1 .. 7 ) {
        my $c = _build_c(
            req => { params => { login => 'local/wrong', password => 'wrong' } },
            model =>
              { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
        );

        $controller->login($c);
    }

    mdb->user_login_attempts->update( { id_login => '127.0.0.1', id_browser => 'Mozilla/1.0' },
        { attempts_datetime => '2012-12-12 12:12:12' } );

    my $c = _build_c(
        authenticate => { id => 'root', realm => 'local' },
        req => { params => { login => 'local/wrong', password => 'wrong' } },
        model =>
          { ConfigStore => FakeConfigStore->new( 'config.login' => { delay_attempts => 5, delay_duration => 5 } ) }
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

sub _build_c {
    mock_catalyst_c(@_);
}

sub _setup {
    TestUtils->cleanup_cis;
    mdb->user_login_attempts->drop;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::Auth' );

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Auth->new( application => '' );
}

done_testing;

package FakeConfigStore;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{params} = \%params;

    return $self;
}

sub get {
    my $self = shift;
    my ($key) = @_;

    return $self->{params}->{$key};
}
