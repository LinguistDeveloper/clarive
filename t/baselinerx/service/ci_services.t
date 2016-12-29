use strict;
use warnings;

use Test::More;
use Test::Fatal;
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

subtest 'ci_related: returns related cis' => sub {
    _setup();

    my $child = TestUtils->create_ci('GitRepository');
    my $parent = TestUtils->create_ci( 'project', repositories => [ $child->mid ] );

    my $service = _build_service();

    my $children = $service->ci_related( undef, { mid => $parent->mid, query_type => 'children' } );
    is @$children, 1;
    is $children->[0]->{mid}, $child->mid;

    my $parents = $service->ci_related( undef, { mid => $child->mid, query_type => 'parents' } );
    is @$parents, 1;
    is $parents->[0]->{mid}, $parent->mid;

    my $related = $service->ci_related( undef, { mid => $child->mid, query_type => 'related' } );
    is @$related, 1;
    is $related->[0]->{mid}, $parent->mid;
};

subtest 'ci_related: returns one related ci in single mode' => sub {
    _setup();

    my $child = TestUtils->create_ci('GitRepository');
    my $parent = TestUtils->create_ci( 'project', repositories => [ $child->mid ] );

    my $service = _build_service();

    my $related = $service->ci_related( undef, { mid => $parent->mid, query_type => 'children', single => 'on' } );
    is $related->{mid}, $child->mid;
};

subtest 'ci_related: returns only mids whey requested' => sub {
    _setup();

    my $child = TestUtils->create_ci('GitRepository');
    my $parent = TestUtils->create_ci( 'project', repositories => [ $child->mid ] );

    my $service = _build_service();

    my $related = $service->ci_related( undef, { mid => $parent->mid, query_type => 'children', mids_only => 1 } );
    is $related->[0], $child->mid;
};

subtest 'ci_load: loads ci' => sub {
    _setup();

    my $ci = TestUtils->create_ci('status', name => 'New');

    my $service = _build_service();

    my $data = $service->ci_load( undef, { mid => $ci->mid } );

    is $data->{name}, 'New';
};

subtest 'ci_load: throws when ci not found' => sub {
    _setup();

    my $service = _build_service();

    like exception { $service->ci_load( undef, { mid => '123' } ) }, qr/CI 123 not found/;
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
