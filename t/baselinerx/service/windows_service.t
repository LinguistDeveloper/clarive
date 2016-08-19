use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::JobLogger;

use_ok 'BaselinerX::Service::WindowsService';

subtest 'run_windows_service: starts service if not running' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 0 } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'start' };

    $service->run_windows_service( $c, $config );

    my ($cmd) = $agent->mocked_call_args( 'execute', 1 );

    like $cmd, qr/start service/;
};

subtest 'run_windows_service: does nothing when already running' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 1 } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'start' };

    $service->run_windows_service( $c, $config );

    is $agent->mocked_called('execute'), 1;
};

subtest 'run_windows_service: stops service if running' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 1 } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'stop' };

    $service->run_windows_service( $c, $config );

    my ($cmd) = $agent->mocked_call_args( 'execute', 1 );

    like $cmd, qr/stop service/;
};

subtest 'run_windows_service: does nothing when already stopped' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 0 } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'stop' };

    $service->run_windows_service( $c, $config );

    is $agent->mocked_called('execute'), 1;
};

subtest 'run_windows_service: restarts service' => sub {
    _setup();

    my $run    = 1;
    my $agent  = _mock_agent( is_running => sub { $run-- } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'restart' };

    $service->run_windows_service( $c, $config );

    my ($cmd1) = $agent->mocked_call_args( 'execute', 1 );
    like $cmd1, qr/stop service/;

    my ($cmd2) = $agent->mocked_call_args( 'execute', 3 );
    like $cmd2, qr/start service/;
};

subtest 'run_windows_service: start throws errors when exit code != 0' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 0 }, execute => sub { return { rc => 255, output => 'Some error' } } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'start' };

    like exception { $service->run_windows_service( $c, $config ) }, qr/starting failed/;
};

subtest 'run_windows_service: start does not throw error when exit_code != 0 but message is successful' => sub {
    _setup();

    my $agent = _mock_agent(
        is_running => sub { 0 },
        execute    => sub { return { rc => 255, output => 'was started successfully' } }
    );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'start' };

    ok $service->run_windows_service( $c, $config );
};

subtest 'run_windows_service: start does not throw an error when silent' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 0 }, execute => sub { return { rc => 255, output => 'Some error' } } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'start', errors => 'silent' };

    ok $service->run_windows_service( $c, $config );
};

subtest 'run_windows_service: stop throws errors when exit code != 0' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 1 }, execute => sub { return { rc => 255, output => 'Some error' } } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'stop' };

    like exception { $service->run_windows_service( $c, $config ) }, qr/stopping failed/;
};

subtest 'run_windows_service: stop does not throw error when exit_code != 0 but message is successful' => sub {
    _setup();

    my $agent = _mock_agent(
        is_running => sub { 1 },
        execute    => sub { return { rc => 255, output => 'was stopped successfully' } }
    );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'stop' };

    ok $service->run_windows_service( $c, $config );
};

subtest 'run_windows_service: stop does not throw an error when silent' => sub {
    _setup();

    my $agent = _mock_agent( is_running => sub { 1 }, execute => sub { return { rc => 255, output => 'Some error' } } );
    my $server = _mock_server( agent => $agent );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { server => [$server], service => 'service', user => 'user', action => 'stop', errors => 'silent' };

    ok $service->run_windows_service( $c, $config );
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
    TestUtils->cleanup_cis;
}

sub _mock_c {
    my (%params) = @_;

    my $c = Test::MonkeyMock->new;

    $c->mock( stash => sub { $params{stash} } );

    return $c;
}

sub _mock_agent {
    my (%params) = @_;

    my $agent = Test::MonkeyMock->new;

    $agent->mock( connect => sub { } );

    $agent->mock(
        execute => sub {
            shift;
            my ($cmd) = @_;

            if ( $cmd =~ m/findstr RUNNING/ ) {
                return { output => $params{is_running}->() ? 'RUNNING' : '' };
            }

            return $params{execute}->() if $params{execute};

            return {};
        }
    );

    return $agent;
}

sub _build_job_logger {
    my (%params) = @_;

    return Baseliner::JobLogger->new( job => $params{job}, jobid => 1, exec => 1, current_service => 'some.service' );
}

sub _mock_server {
    my (%params) = @_;

    my $agent = $params{agent} || _mock_agent();
    my $active = $params{active} // 1;

    my $server = Test::MonkeyMock->new;

    $server->mock( does    => sub { 1 } );
    $server->mock( connect => sub { $agent } );
    $server->mock( active  => sub { $active } );

    return $server;
}

sub _mock_job {
    my (%params) = @_;

    my $job = Test::MonkeyMock->new;

    $job->mock( mid => sub { 123 } );
    $job->mock( logger => sub { $params{logger} || _build_job_logger( job => $job ) } );

    return $job;
}

sub _build_service {
    BaselinerX::Service::WindowsService->new;
}
