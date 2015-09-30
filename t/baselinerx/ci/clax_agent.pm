use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

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
