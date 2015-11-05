use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::generic_server;
use BaselinerX::CI::balix_agent;
use BaselinerX::Type::Model::ConfigStore;

subtest 'balix from connect' => sub {
    my $os_port_key = BaselinerX::Type::Model::ConfigStore->set(key=>'balix_port', value=> 1234 );
    my $server = BaselinerX::CI::generic_server->new( hostname => 'bar', connect_worker=>0, connect_clax=>0, connect_ssh=>0, connect_balix=>1 );
    my $agent = $server->connect();
    is $agent->port, 1234;
};

subtest 'balix port default' => sub {
    my $os_port_key = BaselinerX::Type::Model::ConfigStore->set(key=>'balix_port', value=> 1234 );
    my $agent = BaselinerX::CI::balix_agent->new(
        user   => 'foo',
        server => BaselinerX::CI::generic_server->new( hostname => 'bar', os=>'win' ),
        @_
    );
    is $agent->port, 1234;
};

subtest 'balix port by os' => sub {
    my $os_port_key = BaselinerX::Type::Model::ConfigStore->set(key=>'balix_port_win', value=> 1234 );
    my $agent = BaselinerX::CI::balix_agent->new(
        user   => 'foo',
        server => BaselinerX::CI::generic_server->new( hostname => 'bar', os=>'win' ),
        @_
    );
    is $agent->port, 1234;
};

done_testing;
