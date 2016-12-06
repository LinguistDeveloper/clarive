use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use JSON   ();
use Encode ();

use_ok 'BaselinerX::Service::RestRequest';

subtest 'rest_request: creates correct request' => sub {
    _setup();

    my $stash = {};
    my $c = _mock_c( stash => $stash );

    my $ua = _mock_ua( response => { success => 1 } );

    my $service = _build_service( ua => $ua );

    my $rv = $service->rest_request(
        $c,
        {
            url => 'http://google.com'
        }
    );

    my ( $method, $url, $options ) = $ua->mocked_call_args('request');

    is $method, 'GET';
    is $url,    'http://google.com';
    is_deeply $options, { headers => {}, content => '' };
};

subtest 'rest_request: creates correct request with custom headers' => sub {
    _setup();

    my $stash = {};
    my $c = _mock_c( stash => $stash );

    my $ua = _mock_ua( response => { success => 1 } );

    my $service = _build_service( ua => $ua );

    my $rv = $service->rest_request(
        $c,
        {
            url     => 'http://google.com',
            headers => {
                'My-Header' => 'My-Value'
            }
        }
    );

    my ( $method, $url, $options ) = $ua->mocked_call_args('request');

    is_deeply $options->{headers}, { 'My-Header' => 'My-Value' };
};

subtest 'rest_request: creates correct request with form data' => sub {
    _setup();

    my $stash = {};
    my $c = _mock_c( stash => $stash );

    my $ua = _mock_ua( response => { success => 1 } );

    my $service = _build_service( ua => $ua );

    my $rv = $service->rest_request(
        $c,
        {
            method => 'POST',
            url    => 'http://google.com',
            args   => { foo => 'bar', привет => 'друзья' }
        }
    );

    my ( $method, $url, $options ) = $ua->mocked_call_args('request');

    is $method, 'POST';
    is $url,    'http://google.com';
    is_deeply $options,
      {
        headers => { 'content-type' => 'application/x-www-form-urlencoded' },
        content => 'foo=bar&%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82=%D0%B4%D1%80%D1%83%D0%B7%D1%8C%D1%8F'
      };
};

subtest 'rest_request: creates correct request with raw body' => sub {
    _setup();

    my $stash = {};
    my $c = _mock_c( stash => $stash );

    my $ua = _mock_ua( response => { success => 1 } );

    my $service = _build_service( ua => $ua );

    my $rv = $service->rest_request(
        $c,
        {
            method => 'POST',
            url    => 'http://google.com',
            body   => 'hello there'
        }
    );

    my ( $method, $url, $options ) = $ua->mocked_call_args('request');

    is $method, 'POST';
    is $url,    'http://google.com';
    is_deeply $options, { headers => {}, content => 'hello there' };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',          'BaselinerX::Type::Action',
        'BaselinerX::Type::Event', 'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
    );
}

sub _mock_c {
    my (%params) = @_;

    my $c = Test::MonkeyMock->new;
    $c->mock( stash => sub { $params{stash} || {} } );

    return $c;
}

sub _mock_ua {
    my (%params) = @_;

    my $response = $params{response};

    my $ua = Test::MonkeyMock->new;

    $ua->mock( request => sub { $response } );

    return $ua;
}

sub _build_service {
    my (%params) = @_;

    my $ua = $params{ua} || _mock_ua();

    my $service = BaselinerX::Service::RestRequest->new(@_);
    $service = Test::MonkeyMock->new($service);
    $service->mock( _build_ua => sub { $ua } );

    return $service;
}
