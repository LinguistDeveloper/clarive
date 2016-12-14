use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }

use JSON ();

use_ok 'BaselinerX::UA';

subtest 'request: throws on errors' => sub {
    my $ua = _build_user_agent( errors => 'fail', response => { success => 0, status => 404, reason => 'Not Found' } );

    like exception { $ua->request( 'GET' => 'http://localhost' ) }, qr/HTTP request failed/;
};

subtest 'request: ignores errors' => sub {
    my $ua =
      _build_user_agent( errors => 'silent', response => { success => 0, status => 404, reason => 'Not Found' } );

    ok !exception { $ua->request( 'GET' => 'http://localhost' ) };
};

subtest 'request: retries on timeout' => sub {
    my $try = 0;
    my $ua  = _build_user_agent(
        timeout_attempts => 3,
        response         => sub {
            $try++;

            return { success => 0, status => 599, reason => 'Internal Exception', content => 'timeout' }
              unless $try >= 3;
            return { success => 1, status => 200, content => 'OK' };
        }
    );

    my $response = $ua->request( 'GET' => 'http://localhost' );

    is $response->{status},  200;
    is $response->{content}, 'OK';
};

subtest 'request: does not retry when not timeout errors' => sub {
    my $try = 0;
    my $ua  = _build_user_agent(
        errors           => 'silent',
        timeout_attempts => 3,
        response         => sub {
            return { success => 0, status => 599, reason => 'Internal Exception' };
        }
    );

    my $response = $ua->request( 'GET' => 'http://localhost' );

    is $response->{status}, 599;
};

subtest 'retries on connect errors' => sub {
    my $try = 0;
    my $ua  = _build_user_agent(
        connection_attempts => 3,
        response            => sub {
            $try++;

            return { success => 0, status => 599, reason => 'Internal Exception', content => 'Could not connect to' }
              unless $try >= 3;
            return { success => 1, status => 200, content => 'OK' };
        }
    );

    my $response = $ua->request( 'GET' => 'http://localhost' );

    is $response->{status},  200;
    is $response->{content}, 'OK';
};

subtest 'request: creates correct request with basic auth' => sub {
    my $ua = _build_user_agent(
        username => 'foo',
        password => 'bar',
        response => { success => 1, status => '200' }
    );

    my $rv = $ua->request( 'GET', 'http://localhost' );

    my ( $method, $url, $options ) = $ua->mocked_call_args('_request');

    is $url, 'http://foo:bar@localhost';
};

subtest 'request: returns empty content when auto parse' => sub {
    my $ua = _build_user_agent(
        response => {
            success => 1,
            status  => '200',
            headers => { 'content-type' => 'application/json' },
            content => ''
        }
    );

    my $rv = $ua->request( 'POST', 'http://localhost', { content => 'hello there' } );

    is $rv->{content}, '';
};

subtest 'request: automatically parses json response' => sub {
    my $ua = _build_user_agent(
        response => {
            success => 1,
            status  => '200',
            headers => { 'content-type' => 'application/json' },
            content => JSON::encode_json( { foo => 'bar' } )
        }
    );

    my $rv = $ua->request( 'POST', 'http://localhost', { content => 'hello there' } );

    is_deeply $rv->{content}, { foo => 'bar' };
};

subtest 'request: automatically parses xml response' => sub {
    my $ua = _build_user_agent(
        response => {
            success => 1,
            status  => '200',
            headers => { 'content-type' => 'text/xml' },
            content => '<xml><foo>bar</foo></xml>'
        }
    );

    my $rv = $ua->request( 'POST', 'http://localhost', { content => 'hello there' } );

    is_deeply $rv->{content}, { foo => 'bar' };
};

done_testing;

sub _build_user_agent {
    my (%params) = @_;

    my $response = delete $params{response};

    my $agent = BaselinerX::UA->new(%params);

    $agent = Test::MonkeyMock->new($agent);
    $agent->mock( _request => $response && ref $response eq 'CODE' ? $response : sub { $response } );
    return $agent;
}
