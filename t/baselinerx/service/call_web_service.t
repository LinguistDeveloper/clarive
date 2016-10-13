use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'BaselinerX::Service::CallWebService';

subtest 'web_request: creates correct request' => sub {
    _setup();

    my $stash = {};
    my $c = _mock_c( stash => $stash );

    my $ua = _mock_ua();

    my $service = _build_service( ua => $ua );

    my $rv = $service->web_request(
        $c,
        {
            url => 'http://google.com'
        }
    );

    my ($request) = $ua->mocked_call_args('request');

    is $request->url,    'http://google.com';
    is $request->method, 'GET';

    is $rv->{content}, 'content';

    is $stash->{_ws_code}, '200';
    is $stash->{_ws_body}, 'content';
};

subtest 'web_request: creates correct request with body' => sub {
    _setup();

    my $stash = {};
    my $c = _mock_c( stash => $stash );

    my $ua = _mock_ua();

    my $service = _build_service( ua => $ua );

    my $rv = $service->web_request(
        $c,
        {
            method => 'POST',
            url    => 'http://google.com',
            body   => 'привет'
        }
    );

    my ($request) = $ua->mocked_call_args('request');

    is $request->method, 'POST';
    is $request->content, Encode::encode( 'UTF-8', 'привет' );
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

sub _mock_response {
    my (%params) = @_;

    my $response = Test::MonkeyMock->new;
    $response->mock( is_success      => sub { 1 } );
    $response->mock( code            => sub { 200 } );
    $response->mock( decoded_content => sub { 'content' } );

    return $response;
}

sub _mock_ua {
    my (%params) = @_;

    my $response = $params{response} || _mock_response();

    my $ua = Test::MonkeyMock->new;

    $ua->mock( env_proxy => sub { } );
    $ua->mock( request   => sub { $response } );

    return $ua;
}

sub _build_service {
    my (%params) = @_;

    my $ua = $params{ua} || _mock_ua();

    my $service = BaselinerX::Service::CallWebService->new(@_);
    $service = Test::MonkeyMock->new($service);
    $service->mock( _build_ua => sub { $ua } );

    return $service;
}
