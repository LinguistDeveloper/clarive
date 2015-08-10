use strict;
use warnings;
no warnings 'redefine';
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
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

subtest 'run: throws when not initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();

    like exception { $cmd->run }, qr/not initialized/;
};

subtest 'run_init: creates db entry' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();

    $cmd->run_init;

    my $clarive = mdb->clarive->find_one;

    ok $clarive->{migration}->{version};
};

subtest 'run: throws when there is an error' => sub {
    _setup();

    my $cmd = _build_cmd();

    my $clarive = mdb->clarive->find_one();
    mdb->clarive->update( { _id => $clarive->{_id} },
        { '$set' => { migration => { version => 100, error => 'Some error' } } } );

    like exception { $cmd->run }, qr/last migration did not succeed/;
};

subtest 'run-fix: fixes error' => sub {
    _setup();

    my $cmd = _build_cmd();

    my $clarive = mdb->clarive->find_one();
    mdb->clarive->update( { _id => $clarive->{_id} },
        { '$set' => { migration => { version => 100, error => 'Some error' } } } );

    $cmd->run_fix;

    $clarive = mdb->clarive->find_one();

    ok !$clarive->{migration}->{error};
};

subtest 'run: runs migrations' => sub {
    _setup();

    my $cmd = _build_cmd();
    $cmd->run( '--path' => 't/data/migrations/all_ok' );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration},
      {
        version => '0102',
        patches => [ { version => '0101', name => 'foo' }, { version => '0102', name => 'bar' } ]
      };
};

subtest 'run: runs migrations when init and not initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();
    ok $cmd->run( '--path' => 't/data/migrations/all_ok', '--init' => 1);
};

subtest 'run: runs migrations when forced and system not initialized' => sub {
    _setup( no_system_init => 1 );

    my $cmd = _build_cmd();
    ok $cmd->run( '--path' => 't/data/migrations/all_ok', '--force' => 1);
};

subtest 'run: runs migrations when forced and migrations not initialized' => sub {
    _setup( no_init => 1 );

    my $cmd = _build_cmd();
    ok $cmd->run( '--path' => 't/data/migrations/all_ok', '--force' => 1);
};

subtest 'run: stops on first syntax error' => sub {
    _setup();

    my $cmd = _build_cmd();
    $cmd->run( '--path' => 't/data/migrations/syntax_errors' );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration}, { version => '0101', error => re(qr/syntax error/), patches => ignore() };
};

subtest 'run: stops on first runtime error' => sub {
    _setup();

    my $cmd = _build_cmd();
    $cmd->run( '--path' => 't/data/migrations/runtime_errors' );

    my $clarive = mdb->clarive->find_one();

    cmp_deeply $clarive->{migration}, { version => '0101', error => re(qr/runtime error/), patches => ignore() };
};

sub _setup {
    my (%params) = @_;

    mdb->clarive->drop;

    mdb->clarive->insert( { initialized => true } ) unless $params{no_system_init};
    _build_cmd()->run_init unless $params{no_system_init} || $params{no_init};
}

sub _build_cmd {
    return Clarive::Cmd::migra->new( app => $Clarive::app, opts => {} );
}

done_testing;
