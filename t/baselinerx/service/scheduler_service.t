use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup; }

use Baseliner::Model::Scheduler;

use_ok 'BaselinerX::Service::SchedulerService';

subtest 'run_once: runs every task' => sub {
    my @tasks = ( { id => 1, _id => '123' } );

    my $scheduler = _mock_scheduler();
    $scheduler->mock( tasks_list => sub { @tasks } );
    $scheduler->mock( run_task   => sub { } );

    my $service = _build_service( scheduler => $scheduler );

    $service->run_once;

    ok $scheduler->mocked_called('tasks_list');
};

subtest 'road_kill: calls correct method on model' => sub {
    my $scheduler = _mock_scheduler();
    $scheduler->mock( road_kill => sub { } );

    my $service = _build_service( scheduler => $scheduler );

    $service->road_kill;

    ok $scheduler->mocked_called('road_kill');
};

done_testing;

sub _mock_scheduler {
    my (%params) = @_;

    my $scheduler = Baseliner::Model::Scheduler->new;
    $scheduler = Test::MonkeyMock->new($scheduler);

    return $scheduler;
}

sub _build_service {
    my (%params) = @_;

    my $scheduler = $params{scheduler};

    my $service = BaselinerX::Service::SchedulerService->new(@_);
    $service = Test::MonkeyMock->new($service);

    $service->mock( _build_scheduler => sub { $scheduler } );

    return $service;
}
