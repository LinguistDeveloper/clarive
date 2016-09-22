use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use BaselinerX::CI::status;

use_ok 'BaselinerX::Service::CIServices';

subtest 'ci_create: creates ci with parameters' => sub {
    _setup();

    my $service = _build_service();

    my $ci = $service->ci_create( undef, { classname => 'status', attributes => { name => 'New' } } );

    isa_ok $ci, 'BaselinerX::CI::status';
    is $ci->name, 'New';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI'
    );

    TestUtils->cleanup_cis;
}

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::CIServices->new(%params);
}
