use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup }

use_ok 'Baseliner::Auth::CAS';

subtest 'returns undef when no ticket' => sub {
    ok !defined _build_auth_cas( config => {} )->authenticate();
};

subtest 'returns undef when invalid ticket' => sub {
    my $r = _mock_response();
    $r->mock( is_success => sub { 0 } );

    my $cas = _mock_cas();
    $cas->mock( service_validate => sub { $r } );

    ok !defined _build_auth_cas( cas => $cas, config => {} )->authenticate('invalid');
};

subtest 'returns undef when valid ticket but no username' => sub {
    my $r = _mock_response();
    $r->mock( is_success => sub { 1 } );
    $r->mock( user       => sub { } );

    my $cas = _mock_cas();
    $cas->mock( service_validate => sub { $r } );

    ok !defined _build_auth_cas( cas => $cas, config => {} )->authenticate('valid');
};

subtest 'returns undef when cas throws' => sub {
    my $r = _mock_response();
    $r->mock( is_success => sub { die 'error' } );

    my $cas = _mock_cas();
    $cas->mock( service_validate => sub { $r } );

    ok !defined _build_auth_cas( cas => $cas, config => {} )->authenticate('valid');
};

subtest 'returns username' => sub {
    my $r = _mock_response();
    $r->mock( is_success => sub { 1 } );
    $r->mock( user       => sub { 'username' } );

    my $cas = _mock_cas();
    $cas->mock( service_validate => sub { $r } );

    is _build_auth_cas( cas => $cas, config => {} )->authenticate('valid'), 'username';
};

subtest 'passes correct arguments' => sub {
    my $r = _mock_response();
    $r->mock( is_success => sub { 1 } );
    $r->mock( user       => sub { 'username' } );

    my $cas = _mock_cas();
    $cas->mock( service_validate => sub { $r } );

    _build_auth_cas( cas => $cas, config => { service => 'http://service.local' } )->authenticate('valid');

    is_deeply [ $cas->mocked_call_args('service_validate') ], [ 'http://service.local', 'valid' ];
};

sub _mock_response {
    my $mock = Test::MonkeyMock->new;
    return $mock;
}

sub _mock_cas {
    my $mock = Test::MonkeyMock->new;
    return $mock;
}

sub _build_auth_cas {
    return Baseliner::Auth::CAS->new(@_);
}

done_testing;
