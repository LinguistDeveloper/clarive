use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }

use File::Temp qw(tempfile);
use JSON ();
use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::generic_server;
use BaselinerX::CI::clax_agent;

subtest 'ping: returns ok when pingable' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        get => sub {
            shift;

            { success => 1, content => JSON::encode_json( { message => 'Hello, world!' } ) };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->ping;

    is $ret->{rc}, 0;
    like $ret->{output}, qr/Hello, world/;
};

subtest 'ping: fails when cannot connect' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        get => sub {
            shift;

            { success => 0 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    like exception {  $clax_agent->ping }, qr/Ping failed/;
};

subtest 'ping: fails when unknown response' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        get => sub {
            shift;

            { success => 1, content => 'Unexpected' };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    like exception {  $clax_agent->ping }, qr/Unknown response/;
};

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

    my $ret = $clax_agent->execute( 'echo bar' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'http://bar:8888/command';
    is_deeply $data, { chdir => '', command => q{echo bar}, user => 'foo' };

    is_deeply $ret, {rc => 0, ret => 'bar', output => 'bar'};
};

subtest 'execute: sends correct request with args' => sub {
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

    my $ret = $clax_agent->execute( 'echo', 'bar' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'http://bar:8888/command';
    is_deeply $data, { chdir => '', command => q{echo 'bar'}, user => 'foo' };

    is_deeply $ret, {rc => 0, ret => 'bar', output => 'bar'};
};

subtest 'execute: sends correct request with environment' => sub {
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

    my $ret = $clax_agent->execute( { env => [ 'FOO=bar', 'BAR=baz' ] }, 'echo', 'bar' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'http://bar:8888/command';
    is_deeply $data, { chdir => '', env => "FOO=bar\nBAR=baz", command => q{echo 'bar'}, user => 'foo' };

    is_deeply $ret, {rc => 0, ret => 'bar', output => 'bar'};
};

subtest 'execute: sends correct request with basic auth' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        post_form => sub {
            shift;
            my ( $url, $data, $options ) = @_;

            $options->{data_callback}->('bar');

            { success => 1, headers => { 'x-clax-exit' => 0 } };
        }
    );

    my $clax_agent = _build_clax_agent(
        ua                  => $ua,
        basic_auth_enabled  => 1,
        basic_auth_username => 'clax',
        basic_auth_password => 'password'
    );

    my $ret = $clax_agent->execute( 'echo bar' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'http://clax:password@bar:8888/command';
};

subtest 'execute: sends correct request with ssl' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        post_form => sub {
            shift;
            my ( $url, $data, $options ) = @_;

            $options->{data_callback}->('bar');

            { success => 1, headers => { 'x-clax-exit' => 0 } };
        }
    );

    my $clax_agent = _build_clax_agent(
        ua          => $ua,
        ssl_enabled => 1,
    );

    my $ret = $clax_agent->execute( 'echo bar' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'https://bar:8888/command';
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
      qr/crc32 check failed/i;

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
        'Content-Length' => '160',
        'Content-Type'   => re(qr{multipart/form-data; boundary=------------clax[0-9a-zA-Z]+})
      };
    like $sent, qr/hello/;
};

subtest 'put_file: sends correct crc when file is empty' => sub {
    my $ua = _mock_ua();

    $ua->mock( post => sub { { success => 1 } } );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ( $local_fh, $local_file ) = tempfile();
    print $local_fh '';
    close $local_fh;

    my $ret = $clax_agent->put_file( local => $local_file, remote => 'remote-file', user => 'user' );

    my ($url) = $ua->mocked_call_args('post');

    is $url, 'http://bar:8888/tree/?crc=00000000';
};

subtest 'put_file: sends correct padded crc' => sub {
    my $ua = _mock_ua();

    $ua->mock( post => sub { { success => 1 } } );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ( $local_fh, $local_file ) = tempfile();
    print $local_fh 'RLXK0tyT';
    close $local_fh;

    my $ret = $clax_agent->put_file( local => $local_file, remote => 'remote-file', user => 'user' );

    my ($url) = $ua->mocked_call_args('post');

    is $url, 'http://bar:8888/tree/?crc=0f5cb862';
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
    is $url, "http://bar:8888/tree/?crc=3610a686&time=$stat[9]";
};

subtest 'put_file: sends request with directory' => sub {
    my $ua = _mock_ua();

    $ua->mock( post => sub { { success => 1 } } );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my ($local_fh, $local_file) = tempfile();
    print $local_fh 'hello';
    close $local_fh;

    my $ret = $clax_agent->put_file( local => $local_file, remote => 'some/where/remote-file', user => 'user' );

    my ( $url ) = $ua->mocked_call_args('post');

    like $url, qr{http://bar:8888/tree/some/where};
};

subtest 'put_file: sends request with directory on win' => sub {
    my $ua = _mock_ua();

    $ua->mock( post => sub { { success => 1 } } );

    my $clax_agent = _build_clax_agent( ua => $ua, server => {os => 'win'} );

    my ($local_fh, $local_file) = tempfile();
    print $local_fh 'hello';
    close $local_fh;

    my $ret = $clax_agent->put_file( local => $local_file, remote => 'C:\Users\clarive\remote-file', user => 'user' );

    my ( $url ) = $ua->mocked_call_args('post');

    like $url, qr{http://bar:8888/tree/C:/Users/clarive};
};

subtest 'delete_file: sends correct request with absolute path' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        delete => sub {
            shift;
            my ( $url, $options ) = @_;

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->delete_file( remote => '/foo/bar');

    my ( $url ) = $ua->mocked_call_args('delete');

    is $url, 'http://bar:8888/tree//foo/bar';
};

subtest 'delete_file: sends correct request with relative path' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        delete => sub {
            shift;
            my ( $url, $options ) = @_;

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->delete_file( remote => 'foo/bar');

    my ( $url ) = $ua->mocked_call_args('delete');

    is $url, 'http://bar:8888/tree/foo/bar';
};

subtest 'rmpath: sends correct request' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        delete => sub {
            shift;
            my ( $url, $options ) = @_;

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->rmpath( '/foo/bar');

    my ( $url ) = $ua->mocked_call_args('delete');

    is $url, 'http://bar:8888/tree//foo/bar?recursive=1';
};

subtest 'mkpath: sends correct request' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        post_form => sub {
            shift;
            my ( $url, $data, $options ) = @_;

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->mkpath( 'foo/bar/baz' );

    my ( $url, $data ) = $ua->mocked_call_args('post_form');

    is $url, 'http://bar:8888/tree/';
    is_deeply $data, { dirname => 'foo/bar/baz'};

    is_deeply $ret, {rc => 0, ret => '', output => ''};
};

subtest 'file_exists: returns true when file does not exist' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        head => sub {
            shift;
            my ( $url, $data, $options ) = @_;

            { success => 1 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->file_exists( 'foo/bar/baz' );

    my ( $url ) = $ua->mocked_call_args('head');

    is $url, 'http://bar:8888/tree/foo/bar/baz';

    ok $ret;
};

subtest 'file_exists: returns false when file does not exist' => sub {
    my $ua = _mock_ua();

    $ua->mock(
        head => sub {
            shift;
            my ( $url, $data, $options ) = @_;

            { success => 0 };
        }
    );

    my $clax_agent = _build_clax_agent( ua => $ua );

    my $ret = $clax_agent->file_exists( 'foo/bar/baz' );

    my ( $url ) = $ua->mocked_call_args('head');

    is $url, 'http://bar:8888/tree/foo/bar/baz';

    ok !$ret;
};

done_testing;

sub _mock_ua {
    my $mock = Test::MonkeyMock->new;

    return $mock;
}

sub _build_clax_agent {
    my (%params) = @_;

    my $server_args = delete $params{server} || { };
    my $ua = delete $params{ua} || _mock_ua();

    my $agent = BaselinerX::CI::clax_agent->new(
        user   => 'foo',
        port   => '8888',
        server => BaselinerX::CI::generic_server->new( hostname => 'bar', %$server_args ),
        %params
    );

    $agent = Test::MonkeyMock->new($agent);
    $agent->mock( _build_ua => sub { $ua } );

    return $agent;
}
