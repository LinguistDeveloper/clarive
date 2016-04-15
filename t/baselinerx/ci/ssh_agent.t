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
use File::Temp qw(tempfile);

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

subtest 'builds correct uri without a user' => sub {
    my $ssh_agent =
      _build_ssh_agent( server => BaselinerX::CI::generic_server->new( hostname => 'bar' ) );

    my $rv = $ssh_agent->ssh;

    my ( $uri, %options ) = $ssh_agent->mocked_call_args('_build_openssh');

    is $uri, 'bar';
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

subtest 'returns error exit_code when put_file fails' => sub {
    my $ssh = _mock_openssh();
    $ssh->mock( scp_put => sub { undef } );

    my $ssh_agent = _build_ssh_agent(
        user        => 'foo',
        server      => BaselinerX::CI::generic_server->new( hostname => 'bar' ),
        private_key => '/foo/bar',
        openssh     => $ssh
    );

    my ($fh, $filename) = tempfile();

    ok $ssh_agent->put_file(local => $filename, remote => 'bar') != 0;
};

subtest 'sync_dir: creates correct rsync command' => sub {
    my $command_runner = _mock_command_runner();

    my $ssh_agent = _build_ssh_agent(
        user        => 'foo',
        server      => BaselinerX::CI::generic_server->new( hostname => 'bar' ),
        private_key => '/foo/bar',
    );
    $ssh_agent->mock( _build_command_runner => sub { $command_runner } );

    $ssh_agent->sync_dir( remote => '/foo/bar', local => '/foo/bar' );

    my (@cmd) = $command_runner->mocked_call_args('run');

    is_deeply \@cmd, [ 'rsync', '-avz', '/foo/bar', 'foo@bar:/foo/bar' ];
};

subtest 'sync_dir: creates correct rsync command in opposite direction' => sub {
    my $command_runner = _mock_command_runner();

    my $ssh_agent = _build_ssh_agent(
        user        => 'foo',
        server      => BaselinerX::CI::generic_server->new( hostname => 'bar' ),
        private_key => '/foo/bar',
    );
    $ssh_agent->mock( _build_command_runner => sub { $command_runner } );

    $ssh_agent->sync_dir( remote => '/foo/bar', local => '/foo/bar', direction => 'remote-to-local' );

    my (@cmd) = $command_runner->mocked_call_args('run');

    is_deeply \@cmd, [ 'rsync', '-avz', 'foo@bar:/foo/bar', '/foo/bar' ];
};

subtest 'sync_dir: creates correct rsync command with delete extraneous' => sub {
    my $command_runner = _mock_command_runner();

    my $ssh_agent = _build_ssh_agent(
        user        => 'foo',
        server      => BaselinerX::CI::generic_server->new( hostname => 'bar' ),
        private_key => '/foo/bar',
    );
    $ssh_agent->mock( _build_command_runner => sub { $command_runner } );

    $ssh_agent->sync_dir( remote => '/foo/bar', local => '/foo/bar', delete_extraneous => 1 );

    my (@cmd) = $command_runner->mocked_call_args('run');

    is_deeply \@cmd, [ 'rsync', '-avz', '--delete', '/foo/bar', 'foo@bar:/foo/bar' ];
};

sub _mock_command_runner {
    my $mock = Test::MonkeyMock->new;

    $mock->mock(
        'run' => sub {
            {
                exit_code => 0,
                output    => '123'
            };
        }
    );

    return $mock;
}

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
