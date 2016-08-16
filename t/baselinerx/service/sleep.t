use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use Time::HiRes qw(gettimeofday tv_interval);

use_ok 'BaselinerX::Service::Sleep';

subtest 'run_sleep: sleeps for a specified amount of seconds' => sub {
    _setup();

    my $t0 = [ gettimeofday() ];

    my $service = _build_service();

    $service->run_sleep( _mock_c(), { seconds => 0.1 } );

    ok tv_interval($t0) > 0.1;
};

done_testing;

sub _setup {
}

sub _mock_logger {
    my $logger = Test::MonkeyMock->new;
    $logger->mock( info => sub { } );

    return $logger;
}

sub _mock_job {
    my $job = Test::MonkeyMock->new;
    $job->mock( logger => sub { _mock_logger() } );

    return $job;
}

sub _mock_c {
    my $c = Test::MonkeyMock->new;
    $c->mock( stash => sub { { job => _mock_job() } } );

    return $c;
}

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::Sleep->new(@_);
}
