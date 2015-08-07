use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
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

sub _setup {
    mdb->clarive->drop;
}

sub _build_cmd {
    return Clarive::Cmd::init->new(app => $Clarive::app, opts => {}, @_);
}

done_testing;
