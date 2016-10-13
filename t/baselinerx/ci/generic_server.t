use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'BaselinerX::CI::generic_server';

subtest 'connect: throws an error when no connectors were selected' => sub {
    my $server = _build_server( connect_ssh => 0, connect_clax => 0, hostname => 'localhost' );

    like exception { $server->connect }, qr/ERROR: no connections configured for this server/;
};

subtest 'connect: returns agent on successful connect' => sub {
    my $server = _build_server( connect_ssh => 1, hostname => 'localhost' );

    my $agent = $server->connect;

    ok $agent;
};

subtest 'connect: tries failing agents one by one' => sub {
    my $server = _build_server( connect_ssh => 1, connect_clax => 1, hostname => 'fail_on_ssh,fail_on_clax' );

    like exception { $server->connect },
      qr/ERROR: could not find agent for this server \(methods attempted: ssh, clax\):/;
};

subtest 'connect: tries agents one by one and returns first successful' => sub {
    my $server = _build_server( connect_ssh => 1, connect_clax => 1, hostname => 'fail_on_ssh' );

    my $agent = $server->connect;

    ok $agent;
};

subtest 'ping: pings server' => sub {
    my $server = _build_server( hostname => 'reachable' );

    my ($status, $output) = $server->ping;

    is $status, 'OK';
    like $output, qr/64 bytes/;
};

subtest 'ping: returns error on failed ping' => sub {
    my $server = _build_server( hostname => 'not reachable' );

    my ($status, $output) = $server->ping;

    is $status, 'KO';
    like $output, qr/No address associated/;
};

subtest 'service: fails when server not pingable' => sub {
    _setup();

    my $server = _build_server( hostname => 'unreachable' );

    my $ret = $server->run_service( 'service.generic_server.connect' );

    like $ret->{output}, qr/ERROR: Server is not reachable/;
};

subtest 'service: returns ok when server is pingable' => sub {
    _setup();

    my $server = _build_server( hostname => 'reachable' );

    my $ret = $server->run_service( 'service.generic_server.connect' );

    ok $ret->{return};
};

subtest 'service: fails when server is pingable but agent not' => sub {
    _setup();

    my $agent = _mock_agent('ssh');
    $agent->mock(ping => sub { die 'not reachable' });

    my $server = _build_server( hostname => 'reachable', _build_agent => sub {$agent} );

    my $ret = $server->run_service( 'service.generic_server.connect' );

    like $ret->{output}, qr/Could not connect: not reachable/;
};

subtest 'service: returns ok when server is pingable and agent too' => sub {
    _setup();

    my $agent = _mock_agent('ssh');
    $agent->mock( ping => sub { 1 } );

    my $server = _build_server( hostname => 'reachable', _build_agent => sub { $agent } );

    my $ret = $server->run_service('service.generic_server.connect');

    ok $ret->{return};
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI::generic_server',
    );

    TestUtils->cleanup_cis();
}

sub _mock_agent {
    my ( $agent_name, %params ) = @_;

    if ( $agent_name eq 'ssh' ) {
        die if $params{server} && $params{server}->hostname =~ m/fail_on_ssh/;
        return Test::MonkeyMock->new;
    }
    elsif ( $agent_name eq 'clax' ) {
        die if $params{server} && $params{server}->hostname =~ m/fail_on_clax/;
        return Test::MonkeyMock->new;
    }
    else {
        die "Unknown agent '$agent_name'";
    }
}

sub _build_server {
    my (%params) = @_;

    my $server = BaselinerX::CI::generic_server->new(@_);

    $server = Test::MonkeyMock->new($server);
    $server->mock( _build_agent => $params{_build_agent} || sub { shift; _mock_agent(@_) } );
    $server->mock(
        _ping => sub {
            my $server = shift;
            if ( $server->hostname eq 'reachable' ) {
                $? = 0;
                return <<'EOF';
PING localhost(localhost (::1)) 56 data bytes
64 bytes from localhost (::1): icmp_seq=1 ttl=64 time=0.020 ms
EOF
            }
            else {
                $? = 255 * 255;
                return 'ping: localhosta: No address associated with hostname';
            }
        }
    );

    return $server;
}
