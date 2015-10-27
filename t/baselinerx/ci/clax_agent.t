use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Deep;
use Test::Fatal;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use File::Temp qw(tempfile);
use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::generic_server;
use BaselinerX::CI::clax_agent;

subtest 'execute: sends correct request' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        post_form => sub {
            shift;
            my ( $url, $data, $options ) = @_;

            $options->{data_callback}->('bar');

            { success => 1, headers => { 'x-clax-exit' => 0 } };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->execute( {}, 'echo', 'bar' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'http://bar:8888/command';
    is_deeply $data, { chdir => undef, command => q{echo 'bar'}, user => 'foo' };

    is_deeply $ret, {rc => 0, ret => 'bar', output => 'bar'};
};

subtest 'get_file: sends correct request' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        get => sub {
            shift;
            my ( $url, $options ) = @_;

            $options->{data_callback}->('bar');

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ($local_fh, $local_file) = tempfile();
    print $local_fh 'hello';
    close $local_fh;

    my $ret = $clax_agent->get_file( local => $local_file, remote => 'remote-file', user => 'user' );

    my ( $url ) = $ua->mocked_call_args('get');

    is $url, 'http://bar:8888/tree/remote-file';

    open my $fh, '<', $local_file or die $!;
    my $data = join '', <$fh>;
    close $fh;

    is $data, 'bar';
    is_deeply $ret, {rc => 0, ret => '', output => ''};
};

subtest 'get_file: accepts correct crc32' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        get => sub {
            shift;
            my ( $url, $options ) = @_;

            $options->{data_callback}->('bar');

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ($local_fh, $local_file) = tempfile();
    print $local_fh 'hello';
    close $local_fh;

    my $ret = $clax_agent->get_file( local => $local_file, remote => 'remote-file', user => 'user' );

    my ( $url ) = $ua->mocked_call_args('get');

    is $url, 'http://bar:8888/tree/remote-file';

    open my $fh, '<', $local_file or die $!;
    my $data = join '', <$fh>;
    close $fh;

    is $data, 'bar';
    is_deeply $ret, {rc => 0, ret => '', output => ''};
};

subtest 'get_file: removes file when invalid crc32' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        get => sub {
            shift;
            my ( $url, $options ) = @_;

            $options->{data_callback}->('bar');

            { success => 1, headers => {'x-clax-crc32' => 'invalid'} };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ($local_fh, $local_file) = tempfile();
    close $local_fh;

    like exception { $clax_agent->get_file( local => $local_file, remote => 'remote-file', user => 'user' ) },
      qr/crc32 check failed/;

    ok !-f $local_file;
};

subtest 'put_file: sends correct request' => sub {
    my $ua = _mock_ua();

    my $sent = '';
    my $headers = {};
    $ua->mock(
        post => sub {
            shift;
            my ( $url, $options ) = @_;

            $headers = $options->{headers};

            while (defined(my $buffer = $options->{content}->())) {
                $sent .= $buffer;
            }

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ($local_fh, $local_file) = tempfile();
    print $local_fh 'hello';
    close $local_fh;

    my $ret = $clax_agent->put_file( local => $local_file, remote => 'remote-file', user => 'user' );

    my ( $url ) = $ua->mocked_call_args('post');

    is $url, 'http://bar:8888/tree/?crc=3610a686';
    cmp_deeply $headers,
      {
        'Content-Length' => '159',
        'Content-Type'   => re(qr{multipart/form-data; boundary=------------clax[0-9a-zA-Z]+})
      };
    like $sent, qr/hello/;
};

subtest 'put_file: sends request with attributes' => sub {
    my $ua = _mock_ua();

    $ua->mock( post => sub { { success => 1 } } );

    my $clax_agent = _build_clax_agent( copy_attrs => 1, ua => $ua );

    my ($local_fh, $local_file) = tempfile();
    print $local_fh 'hello';
    close $local_fh;

    my $ret = $clax_agent->put_file( local => $local_file, remote => 'remote-file', user => 'user' );

    my ( $url ) = $ua->mocked_call_args('post');

    my @stat = stat $local_file;
    is $url, "http://bar:8888/tree/?time=$stat[9]&crc=3610a686";
};

sub _mock_ua {
    my $mock = Test::MonkeyMock->new;

    return $mock;
}

sub _build_clax_agent {
    my (%params) = @_;

    my $ua = delete $params{ua} || _mock_ua();

    my $agent = BaselinerX::CI::clax_agent->new(
        user   => 'foo',
        port   => '8888',
        server => BaselinerX::CI::generic_server->new( hostname => 'bar' ),
        @_
    );

    $agent = Test::MonkeyMock->new($agent);
    $agent->mock( _build_ua => sub { $ua } );

    return $agent;
}

done_testing;
