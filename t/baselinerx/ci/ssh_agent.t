use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::generic_server;
use BaselinerX::CI::ssh_agent;

subtest 'builds openssh with correct params' => sub {
    my $ssh_agent =
      _build_ssh_agent( user => 'foo', server => BaselinerX::CI::generic_server->new( hostname => 'bar' ) );

    my $rv = $ssh_agent->ssh;

    ok $rv;

    my ( $uri, %options ) = $ssh_agent->mocked_call_args('_build_openssh');

    is $uri, 'foo@bar';
    is_deeply \%options,
      {
        master_opts => [
            -F => '/dev/null',
            -o => 'StrictHostKeyChecking=no',
            -o => 'PasswordAuthentication=no',
            -o => 'UserKnownHostsFile=/dev/null'
        ],
        default_ssh_opts => [
            -F => '/dev/null',
        ]
      };
};

subtest 'builds openssh with correct params when private_key' => sub {
    my $ssh_agent = _build_ssh_agent(
        user        => 'foo',
        server      => BaselinerX::CI::generic_server->new( hostname => 'bar' ),
        private_key => '/foo/bar'
    );

    my $rv = $ssh_agent->ssh;

    ok $rv;

    my ( $uri, %options ) = $ssh_agent->mocked_call_args('_build_openssh');

    is $uri, 'foo@bar';
    is_deeply \%options,
      {
        master_opts => [
            -F => '/dev/null',
            -o => 'StrictHostKeyChecking=no',
            -o => 'PasswordAuthentication=no',
            -o => 'UserKnownHostsFile=/dev/null',
            -i => '/foo/bar'
        ],
        default_ssh_opts => [
            -F => '/dev/null',
        ]
      };
};

sub _mock_openssh {
    my $mock = Test::MonkeyMock->new;

    # TODO: move to Test::MonkeyMock
    no strict 'refs';
    my $mock_class = ref $mock;
    unshift @{"$mock_class\::ISA"}, 'Net::OpenSSH';

    $mock->mock( error => sub { '' } );

    return $mock;
}

sub _build_ssh_agent {
    my (%params) = @_;

    my $agent = BaselinerX::CI::ssh_agent->new(@_);

    my $openssh = $params{openssh} || _mock_openssh();

    $agent = Test::MonkeyMock->new($agent);
    $agent->mock( _build_openssh => sub { $openssh } );

    return $agent;
}

done_testing;
