package BaselinerX::Service::Sleep;
use Moose;

use Time::HiRes qw(usleep);
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_loc _locl);

with 'Baseliner::Role::Service';

register 'service.job.sleep' => {
    name        => _locl('Sleep for a number of seconds'),
    job_service => 1,
    form        => '/forms/sleep_job.js',
    icon        => '/static/images/icons/service-job-sleep.svg',
    handler     => \&run_sleep,
};

sub run_sleep {
    my ( $self, $c, $config ) = @_;

    $config ||= {};

    my $stash = $c->stash;
    my $job   = $stash->{job};
    my $log   = $job->logger;

    my $secs = $config->{seconds} || 5;

    $log->info( _loc( "Job sleeping for %1 seconds", $secs ) );

    usleep $secs * 1_000_000;

    $log->info( _loc( "Job awaking after %1 seconds", $secs ) );

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
