use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'BaselinerX::Service::Dispatcher';

subtest 'check_daemon: starts daemon with correct env parameter' => sub {
    _setup();

    my $p = { daemon => { _id => 123, service => 'service.event.daemon', active => 1 } };
    my $config = { argv => [ '--env' => 'test' ] };

    my $daemons = Baseliner::Model::Daemons->new();
    $daemons = Test::MonkeyMock->new($daemons);
    $daemons->mock( service_start => sub { } );

    my $dispatcher = BaselinerX::Service::Dispatcher->new( disp_id => 'myhost' );
    $dispatcher = Test::MonkeyMock->new($dispatcher);
    $dispatcher->mock( _build_daemons => sub { $daemons } );

    $dispatcher->check_daemon( $p, $config );

    my %params = $daemons->mocked_call_args('service_start');

    cmp_deeply $params{params}, [ '--env' => 'test' ];
};

subtest 'check_daemon: remembers start mode' => sub {
    _setup();

    mdb->daemon->insert( { _id => 123 } );

    my $p = { daemon => { _id => 123, service => 'service.event.daemon', active => 1 } };
    my $config = { argv => [ '--env' => 'test' ] };

    my $daemons = Baseliner::Model::Daemons->new();
    $daemons = Test::MonkeyMock->new($daemons);
    $daemons->mock( service_start => sub { } );

    my $dispatcher = BaselinerX::Service::Dispatcher->new( disp_id => 'myhost' );
    $dispatcher = Test::MonkeyMock->new($dispatcher);
    $dispatcher->mock( _build_daemons => sub { $daemons } );

    $dispatcher->check_daemon( $p, $config );

    my $doc = mdb->daemon->find_one();

    is $doc->{active_instances}->[0]->{start_mode}, 'background';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Events',         'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',   'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',  'BaselinerX::Type::Event',
        'Baseliner::Model::Registry', 'Baseliner::Model::Events',
    );

    mdb->daemon->drop;
}
