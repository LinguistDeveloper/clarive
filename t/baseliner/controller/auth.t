use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use_ok 'Baseliner::Controller::Auth';

subtest 'authenticate: creates correct event event.auth.attempt' => sub {
    _setup();

    my $ci = ci->user->new( username => 'foo', name => 'foo', password => 'admin' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => 'foo', password => 'admin' },
        stash        => {
            login    => 'foo',
            password => 'admin',
        }
    );

    $controller->authenticate($c);

    my $events = _build_events_model();

    my $rv = $events->find_by_key('event.auth.attempt');

    cmp_deeply $rv->[0],
      {
        'event_key'  => 'event.auth.attempt',
        'event_data' => ignore(),
        'ts'         => ignore(),
        'realm'      => '',
        'username'   => 'foo',
        'mid'        => undef,
        'rules_exec' => {
            'event.auth.attempt' => {
                'post-online' => 0,
                'pre-online'  => 0
            }
        },
        'id'           => ignore(),
        'module'       => ignore(),
        'event_status' => 'new',
        'login'        => 'foo',
        'login_data'   => { 'login_ok' => undef },
        't'            => ignore(),
        '_id'          => ignore(),
      };
};

subtest 'authenticate: creates correct event event.auth.attempt when user not found' => sub {
    _setup();

    my $c = _build_c(
        authenticate => { id => 'foo', password => 'admin' },
        stash        => {
            login    => 'foo',
            password => 'admin',
        }
    );

    my $controller = _build_controller();
    $controller->authenticate($c);

    my $events = _build_events_model();

    my $rv = $events->find_by_key('event.auth.attempt');

    is $rv->[0]->{login}, 'foo (user not exists)';
};

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
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \0,
        msg     => "Login error: User not found: root\n",
        errors  => { login => "Login error: User not found: root\n" }
      };
};

subtest 'login: reduces logins after failed ones' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $controller = _build_controller();

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_attempts', value => 5 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_duration', value => 5 );

    my $c = _build_c( req => { params => { login => 'local/root', password => 'wrong' } } );

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

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_attempts', value => 5 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_duration', value => 5 );

    for ( 1 .. 5 ) {
        my $c = _build_c( req => { params => { login => 'local/wrong', password => 'wrong' } }, );

        $controller->login($c);

        cmp_deeply $c->stash->{json},
          {
            success        => \0,
            msg            => ignore(),
            attempts_login => ignore(),
            block_datetime => ignore(),
            errors         => {
                login => ignore(),
            }
          };
    }

    my $c = _build_c( req => { params => { login => 'local/wrong', password => 'wrong' } }, );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success           => \0,
        msg               => ignore(),
        attempts_login    => ignore(),
        attempts_duration => 5,
        block_datetime    => ignore(),
        errors            => {
            login => ignore(),
        }
      };

    $c = _build_c( req => { params => { login => 'local/wrong', password => 'wrong' } }, );

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

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_attempts', value => 5 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_duration', value => 5 );

    for ( 1 .. 7 ) {
        my $c = _build_c( req => { params => { login => 'local/wrong', password => 'wrong' } }, );

        $controller->login($c);
    }

    mdb->user_login_attempts->update( { id_login => '127.0.0.1', id_browser => 'Mozilla/1.0' },
        { attempts_datetime => '2012-12-12 12:12:12' } );

    my $c = _build_c(
        authenticate => { id => 'root', realm => 'local' },
        req => { params => { login => 'local/wrong', password => 'wrong' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: denies logins when in maintenance mode' => sub {
    _setup();

    my $controller = _build_controller();

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_attempts', value => 5 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.login.delay_duration', value => 5 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.maintenance.enabled',  value => 1 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.maintenance.message',  value => 'Maintenance mode' );

    my $c = _build_c( req => { params => { login => 'remote/users', password => 'password' } }, );

    $controller->login($c);

    is ${ $c->stash->{json}->{success} }, 0;
    is $c->stash->{json}->{msg}, 'Maintenance mode';
};

subtest 'login: allows local logins when in maintenance mode' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $controller = _build_controller();

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.maintenance.enabled', value => 1 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.maintenance.message', value => 'Maintenance mode' );

    my $c = _build_c(
        authenticate => { id => 'root', realm => 'local' },
        req => { params => { login => 'local/root', password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: logges in with user_case as uc' => sub {
    _setup();

    my $ci = ci->user->new( username => 'FOO', name => 'FOO', password => 'admin' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        config       => { user_case => 'uc' },
        authenticate => { id        => 'FOO', password => 'admin' },
        req          => { params    => { login => 'foo', password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: log in with lowercase user with user_case as uc' => sub {
    _setup();

    my $ci = ci->user->new( username => 'FOO', name => 'FOO', password => 'admin' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        config       => { user_case => 'uc' },
        authenticate => { id        => 'FOO', password => 'admin' },
        req          => { params    => { login => 'foo', password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: cannot log in with uppercase user without user_case as uc' => sub {
    _setup();

    my $ci = ci->user->new( username => 'FOO', name => 'FOO', password => 'admin' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => 'foo', password => 'admin' },
        req => { params => { login => 'foo', password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \0,
        msg     => "Login error: User not found: foo\n",
        errors  => ignore()
      };
};

subtest 'login: logges in with lowercase user with user_case as lc' => sub {
    _setup();

    my $ci = ci->user->new( username => 'foo', name => 'foo', password => 'admin' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        config       => { user_case => 'lc' },
        authenticate => { id        => 'foo', password => 'admin' },
        req          => { params    => { login => 'FOO', password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: cannot log in with uppercase user without user_case as lc' => sub {
    _setup();

    my $ci = ci->user->new( username => 'foo', name => 'foo', password => 'admin' );
    $ci->save;

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => 'FOO', password => 'admin' },
        req => { params => { login => 'FOO', password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \0,
        msg     => "Login error: User not found: FOO\n",
        errors  => ignore()
      };
};

subtest 'login: cannot log in with LOCAL/ROOT user' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $realm = 'LOCAL';
    my $id    = "ROOT";
    my $login = "$realm/$id";

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => $id, realm => $realm },
        req => { params => { login => $login, password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \0,
        msg     => "Login error: User not found: $id\n",
        errors  => ignore(),
      };
};

subtest 'login: cannot log in with local/ROOT user' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $realm = 'local';
    my $id    = 'ROOT';
    my $login = "$realm/$id";

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => $id, realm => $realm },
        req => { params => { login => $login, password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \0,
        msg     => "Login error: User not found: $id\n",
        errors  => ignore(),
      };
};

subtest 'login: logges in clarive with local/root user' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $realm = 'local';
    my $id    = 'root';
    my $login = "$realm/$id";

    my $controller = _build_controller();

    my $c = _build_c(
        authenticate => { id => $id, realm => $realm },
        req => { params => { login => $login, password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

subtest 'login: cannot log in with local/root user and user_case uc' => sub {
    _setup();

    my $ci = ci->user->new( username => 'root' );
    $ci->save;

    my $realm = 'local';
    my $id    = 'root';
    my $login = "$realm/$id";

    my $controller = _build_controller();

    my $c = _build_c(
        config       => { user_case => 'uc' },
        authenticate => { id        => $id, realm => $realm },
        req          => { params    => { login => $login, password => 'admin' } },
    );

    $controller->login($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        msg     => 'OK',
      };
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::Type::Service', 'BaselinerX::CI',
        'BaselinerX::Auth' );

    TestUtils->cleanup_cis;
    mdb->user_login_attempts->drop;

    mdb->config->drop;
    mdb->event->drop;
    mdb->event_log->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Auth->new( application => '' );
}

sub _build_events_model {
    return Baseliner::Model::Events->new();
}

sub _build_c {
    mock_catalyst_c(@_);
}
