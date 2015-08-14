use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::MonkeyMock;
use TestEnv;

TestEnv->setup;

use Clarive::App;
use Clarive::mdb;
use Clarive::Cmd::init;

subtest 'throws when system already initialized' => sub {
    _setup();

    my $cmd = _build_cmd();

    $cmd->run;

    like exception { $cmd->run }, qr/System is already initialized/;
};

subtest 'creates entry' => sub {
    _setup();

    my $cmd = _build_cmd();

    $cmd->run;

    my $entry = mdb->clarive->find_one;

    ok $entry && %$entry;
};

subtest 'does not create entry when exists' => sub {
    _setup();

    mdb->clarive->insert({foo => 'bar'});

    my $cmd = _build_cmd();

    $cmd->run;

    my @entries = mdb->clarive->find->all;

    is scalar @entries, 1;
};

subtest 'creates root user' => sub {
    _setup();

    my $cmd = _build_cmd();

    $cmd->run;

    my $user = ci->user->search_ci(username => 'root');

    ok $user;
};

subtest 'does nothing if root user exists' => sub {
    _setup();

    my $cmd = _build_cmd();

    $cmd->run;

    my @user = ci->user->search_cis;

    is scalar @user, 1;
};

subtest 'check: returns true if initialized' => sub {
    _setup();

    _build_cmd()->run;

    my $cmd = _build_cmd();

    ok $cmd->check;
};

subtest 'check: returns false if not initialized' => sub {
    _setup();

    my $cmd = _build_cmd();

    ok !$cmd->check;
};

subtest 'does nothing if reset flag but user says no' => sub {
    _setup();

    my $cmd = _build_cmd(ask_me => 0);

    $cmd->run(args => {reset => 1});

    my @user = ci->user->search_cis;

    is scalar @user, 0;
};

subtest 'does not ask user when yes flag is passed' => sub {
    _setup();

    my $cmd = _build_cmd(ask_me => 0);

    $cmd->run(args => {reset => 1, yes => 1});

    my @user = ci->user->search_cis;

    is scalar @user, 1;
};

subtest 'resets everything if reset flag and user says yes' => sub {
    _setup();

    mdb->activity->insert({});

    my $cmd = _build_cmd(ask_me => 1);

    $cmd->run(args => {reset => 1});

    is(mdb->activity->count, 0);
};

sub _setup {
    mdb->clarive->drop;

    mdb->master->drop;
    mdb->master_doc->drop;
}

sub _build_cmd {
    my (%params) = @_;

    my $cmd = Clarive::Cmd::init->new(app => $Clarive::app, opts => {}, @_);
    $cmd = Test::MonkeyMock->new($cmd);
    $cmd->mock( _ask_me => sub { $params{ask_me} } );

    return $cmd;
}

done_testing;
