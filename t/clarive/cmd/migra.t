use strict;
use warnings;
no warnings 'redefine';
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;

TestEnv->setup;

use boolean;
use Clarive::mdb;
use Clarive::Cmd::migra;

subtest 'run_init: throws when system not initialized' => sub {
    _setup( no_system_init => 1 );

    my $cmd = _build_cmd();

    like exception { $cmd->run_init }, qr/System not initialized/;
};

subtest 'run_init: does nothing when user says no' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd( _ask_me => 0 );

    $cmd->run_init;

    my $clarive = mdb->clarive->find_one;

    ok !exists $clarive->{migration}->{version};
};

subtest 'run_init: creates db entry' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();

    $cmd->run_init( args => { yes => 1 } );

    my $clarive = mdb->clarive->find_one;

    ok $clarive->{migration}->{version};
};

subtest 'run_init: throws when already initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();

    $cmd->run_init( args => { yes => 1 } );

    like exception { $cmd->run_init( args => { yes => 1 } ) }, qr/already initialized/;
};

subtest 'run_init: does not throw when already initialized but forced' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();

    $cmd->run_init( args => { yes => 1 } );

    ok $cmd->run_init( args => { yes => 1, force => 1 } );
};

subtest 'run: throws when not initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();

    like exception { $cmd->run }, qr/not initialized/;
};

subtest 'run: throws when there is an error' => sub {
    _setup();

    my $cmd = _build_cmd();

    my $clarive = mdb->clarive->find_one();
    mdb->clarive->update( { _id => $clarive->{_id} },
        { '$set' => { migration => { version => 100, error => 'Some error' } } } );

    like exception { $cmd->run }, qr/last migration did not succeed/;
};

subtest 'run_fix: fixes error' => sub {
    _setup();

    my $cmd = _build_cmd();

    my $clarive = mdb->clarive->find_one();
    mdb->clarive->update( { _id => $clarive->{_id} },
        { '$set' => { migration => { version => 100, error => 'Some error' } } } );

    $cmd->run_fix( args => { yes => 1 } );

    $clarive = mdb->clarive->find_one();

    ok !$clarive->{migration}->{error};
};

subtest 'run_fix: does nothing when user says no' => sub {
    _setup();

    my $cmd = _build_cmd( _ask_me => 0 );

    my $clarive = mdb->clarive->find_one();
    mdb->clarive->update( { _id => $clarive->{_id} },
        { '$set' => { migration => { version => 100, error => 'Some error' } } } );

    $cmd->run_fix;

    $clarive = mdb->clarive->find_one();

    ok $clarive->{migration}->{error};
};

subtest 'run: runs migrations' => sub {
    _setup();

    my $cmd = _build_cmd();
    $cmd->run( args => { path => 't/data/migrations/all_ok', yes => 1 } );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration},
      {
        version => '0102',
        patches => [ { version => '0101', name => 'foo' }, { version => '0102', name => 'bar' } ]
      };
};

subtest 'run: does nothing when user says no' => sub {
    _setup();

    my $cmd = _build_cmd( _ask_me => 0 );
    $cmd->run( args => { path => 't/data/migrations/all_ok' } );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration}, { version => '0100' };
};

subtest 'run: runs migrations when init and not initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();
    ok $cmd->run( args => { path => 't/data/migrations/all_ok', init => 1, yes => 1 } );
};

subtest 'run: runs migrations when forced and system not initialized' => sub {
    _setup( no_system_init => 1 );

    my $cmd = _build_cmd();
    ok $cmd->run( args => { path => 't/data/migrations/all_ok', force => 1, yes => 1 } );
};

subtest 'run: runs migrations when forced and migrations not initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();
    ok $cmd->run( args => { path => 't/data/migrations/all_ok', force => 1, yes => 1 } );
};

subtest 'run: stops on first syntax error' => sub {
    _setup();

    my $cmd = _build_cmd();
    $cmd->run( args => { path => 't/data/migrations/syntax_errors', yes => 1 } );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration}, { version => '0101', error => re(qr/syntax error/), patches => ignore() };
};

subtest 'run: stops on first runtime error' => sub {
    _setup();

    my $cmd = _build_cmd();
    $cmd->run( args => { path => 't/data/migrations/runtime_errors', yes => 1 } );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration}, { version => '0101', error => re(qr/runtime error/), patches => ignore() };
};

sub _setup {
    my (%params) = @_;

    mdb->clarive->drop;

    mdb->clarive->insert( { initialized => true } ) unless $params{no_system_init};
    _build_cmd()->run_init( args => { yes => 1 } ) unless $params{no_system_init} || $params{no_init};
}

sub _build_cmd {
    my (%params) = @_;

    my $cmd = Clarive::Cmd::migra->new( app => $Clarive::app, opts => {} );
    $cmd = Test::MonkeyMock->new($cmd);

    if ( exists $params{_ask_me} ) {
        $cmd->mock( _ask_me => sub { $params{_ask_me} } );
    }

    return $cmd;
}

done_testing;
