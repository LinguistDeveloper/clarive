use strict;
use warnings;
use v5.10;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use_ok 'BaselinerX::Type::Service';

use Baseliner::Core::Registry;
use BaselinerX::Type::Service::Container;

subtest 'run service' => sub {
    {

        package Clarive::TestService;
        use Moose;
        with 'Baseliner::Role::Service';
    }

    my $serv = _build( 'Clarive::TestService', 'foo', handler => sub { 123 } );

    my $stash = {};
    my $c = BaselinerX::Type::Service::Container->new( stash => $stash );

    my $ret = $serv->run($c);
    is $ret->{rc}, 123;
};

subtest 'run CI service with MID' => sub {
    _setup();

    {

        package BaselinerX::CI::TestServiceCI;
        use Baseliner::Moose;
        with 'Baseliner::Role::CI';
        with 'Baseliner::Role::Service';
        sub icon { }
    }

    my $ci = BaselinerX::CI::TestServiceCI->new;
    $ci->mid('11');
    $ci->save;

    my $serv = _build( 'BaselinerX::CI::TestServiceCI', 'foo', handler => sub { shift->mid() . "456" } );

    my $stash = {};
    my $c = BaselinerX::Type::Service::Container->new( stash => $stash );

    my $ret = $serv->run( $c, { mid => '11' } );
    is $ret->{rc}, '11456';
};

subtest 'run CI service with MID defined within' => sub {
    _setup();

    {

        package BaselinerX::CI::TestServiceCI2;
        use Baseliner::Moose;
        with 'Baseliner::Role::CI';
        with 'Baseliner::Role::Service';
        sub icon { }

        service 'footest.baz' => {
            name    => 'footest',
            handler => sub { 999 },
          }
    }

    my $ci = BaselinerX::CI::TestServiceCI2->new;
    $ci->mid('11');
    $ci->save;

    my $serv = Baseliner::Core::Registry->get('service.footest.baz');

    my $stash = {};
    my $c     = BaselinerX::Type::Service::Container->new( stash => $stash );
    my $ret   = $serv->run( $c, { mid => '11' } );
    is $ret->{rc}, '999';
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::Type::Service', );

    TestUtils->cleanup_cis;
    TestUtils->register_ci_events;
}

sub _build {
    my ( $module, $key, @args ) = @_;

    # XXX due to a weaken() on registry_nodes, unfortunately
    # we need something "global" to survive ref destruction
    state $node = Baseliner::Core::RegistryNode->new(
        module => $module,
        id     => $key,
        key    => $key
    );

    BaselinerX::Type::Service->new(
        registry_node => $node,
        module        => $module,
        @args
    );
}
