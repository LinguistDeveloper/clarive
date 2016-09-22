use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Clarive::ci;

use_ok 'BaselinerX::CI::ftp_agent';

subtest 'new: throws when cannot connect' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'unreachable' );

    my $agent = _build_ftp_agent( server => $server->mid );

    like exception { $agent->ping }, qr/FTP: Could not connect to host unreachable/;
};

subtest 'new: throws when no username/password provided and cannot be discovered' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'no_login' );

    my $agent = _build_ftp_agent( server => $server->mid );

    like exception { $agent->ping }, qr/FTP: No username\/password were provided or could not be discovered/;
};

subtest 'new: throws when cannot login' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'no_login' );

    my $agent = _build_ftp_agent( user => 'foo', password => 'bar', server => $server->mid );

    like exception { $agent->ping }, qr/FTP: Could not login: some message/;
};

subtest 'new: logins with username/password provided' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp = _mock_ftp('localhost');
    my $agent = _build_ftp_agent( user => 'foo', password => 'bar', server => $server->mid, ftp => $ftp );

    $agent->ping;

    my ( $username, $password ) = $ftp->mocked_call_args('login');

    is $username, 'foo';
    is $password, 'bar';
};

subtest 'new: logins as anonymous' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp = _mock_ftp('localhost');
    my $agent = _build_ftp_agent( user => 'anonymous', server => $server->mid, ftp => $ftp );

    $agent->ping;

    my ( $username, $password ) = $ftp->mocked_call_args('login');

    is $username, 'anonymous';
    is $password, undef;
};

subtest 'new: tries netrc lookup when no username or password were provided' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'no_machine_in_netrc' );

    my $agent = _build_ftp_agent( server => $server->mid, netrc => sub { shift; _mock_netrc(@_) } );

    like exception { $agent->ping }, qr/FTP: No username\/password were provided or could not be discovered/;
};

subtest 'new: discovers username/password via netrc' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp = _mock_ftp('localhost');
    my $agent = _build_ftp_agent( server => $server->mid, ftp => $ftp, netrc => sub { shift; _mock_netrc(@_) } );

    $agent->ping;

    my ( $username, $password ) = $ftp->mocked_call_args('login');

    is $username, 'user';
    is $password, 'password';
};

subtest 'new: discovers password via netrc' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp   = _mock_ftp('localhost');
    my $agent = _build_ftp_agent(
        user   => 'myuser',
        server => $server->mid,
        ftp    => $ftp,
        netrc  => sub { shift; _mock_netrc(@_) }
    );

    $agent->ping;

    my ( $username, $password ) = $ftp->mocked_call_args('login');

    is $username, 'myuser';
    is $password, 'password';
};

subtest 'file_exists: returns true when file/dir exists' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp   = _mock_ftp('localhost');
    my $agent = _build_ftp_agent(
        user   => 'myuser',
        server => $server->mid,
        ftp    => $ftp,
        netrc  => sub { shift; _mock_netrc(@_) }
    );

    ok $agent->file_exists('foo');
};

subtest 'file_exists: returns false when file/dir does no exist' => sub {
    _setup();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp   = _mock_ftp('localhost', message => 'No such file or directory');
    my $agent = _build_ftp_agent(
        user   => 'myuser',
        server => $server->mid,
        ftp    => $ftp,
        netrc  => sub { shift; _mock_netrc(@_) }
    );

    ok !$agent->file_exists('foo');
};

subtest 'put_file: ships file to remote side' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file("hello", "$tempdir/file.txt");

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );

    my $ftp   = _mock_ftp('localhost');
    my $agent = _build_ftp_agent(
        user   => 'myuser',
        server => $server->mid,
        ftp    => $ftp,
        netrc  => sub { shift; _mock_netrc(@_) }
    );

    ok $agent->put_file(local => "$tempdir/file.txt", remote => '/foo');

    my ($cwd) = $ftp->mocked_call_args('cwd');
    is $cwd, '/';

    my ($file) = $ftp->mocked_call_args('put');
    is $file, "$tempdir/file.txt";
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'Baseliner::CI',
        'BaselinerX::CI' );

    TestUtils->cleanup_cis;
}

sub _mock_netrc {
    my ( $hostname, $user ) = @_;

    return if $hostname eq 'no_machine_in_netrc';
    return if $user && $user eq 'netrc_unknown_user';

    my $machine = Test::MonkeyMock->new;
    $machine->mock( login => sub { $user || 'user' } );
    $machine->mock( password => sub { 'password' } );
    return $machine;
}

sub _mock_ftp {
    my ($hostname, %params) = @_;

    return if $hostname =~ m/unreachable/;

    my $ftp = Test::MonkeyMock->new;

    $ftp->mock(
        login => sub {
            return 0 if $hostname =~ m/no_login/;
            return 1;
        }
    );
    $ftp->mock( message => sub { $params{message} || 'some message' } );
    $ftp->mock( binary  => sub { } );
    $ftp->mock( ls      => sub { ('.') } );
    $ftp->mock( cwd     => sub { 1 } );
    $ftp->mock( put     => sub { 1 } );

    return $ftp;
}

sub _build_ftp_agent {
    my (%params) = @_;

    my $ftp = delete $params{ftp};

    my $agent = BaselinerX::CI::ftp_agent->new(%params);

    $agent = Test::MonkeyMock->new($agent);
    $agent->mock( _build_ftp => sub { shift; $ftp || _mock_ftp(@_) } );
    $agent->mock( _netrc_lookup => $params{netrc} || sub { } );

    return $agent;
}
