use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use_ok 'BaselinerX::Service::UserServices';

subtest 'user_load: throws if user parameter is not present' => sub {
    _setup();

    like exception { _build_service()->user_load() }, qr/Missing username/;
};

subtest 'user_load: throws if username does not exist' => sub {
    _setup();

    like exception { _build_service()->user_load( undef, { username => 'username' } ) },
      qr/User with username username not found/;
};

subtest 'user_load: returns user document' => sub {
    _setup();

    TestSetup->create_user( username => 'foo', password => 'admin', account_type => 'system' );

    my $service = _build_service();

    my $user = _build_service()->user_load( undef, { username => 'foo' } );
    my $user_doc = ci->user->find_one( { username => 'foo' } );

    cmp_deeply $user, $user_doc;
};

subtest 'user_load: returns user mid' => sub {
    _setup();

    TestSetup->create_user( username => 'foo', password => 'admin', account_type => 'system' );

    my $service = _build_service();

    my $user = _build_service()->user_load( undef, { username => 'foo', mid_only => 1 } );
    my $user_mid = ci->user->find_one( { username => 'foo' } )->{mid};

    cmp_deeply $user, $user_mid;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',  'BaselinerX::Type::Event',
        'BaselinerX::Type::Service', 'BaselinerX::Type::Statement',
        'BaselinerX::CI'
    );

    TestUtils->cleanup_cis;
}

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::UserServices->new(%params);
}
