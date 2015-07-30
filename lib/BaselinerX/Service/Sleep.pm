package BaselinerX::Service::Sleep;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;

with 'Baseliner::Role::Service';

register 'service.job.sleep' => { 
    name => 'Sleep for a number of seconds', 
    job_service  => 1,
    form => '/forms/sleep_job.js',
    icon => '/static/images/silk/clock_stop.png',
    handler => \&run_sleep, };

sub run_sleep {
    my ($self,$c, $config)=@_;

    my $stash = $c->stash;
    my $job = $stash->{job};
    my $log = $job->logger;
    $config ||= {};
    
    my $secs = $config->{seconds} || 5;
    $log->info(_loc("Job sleeping %1 seconds", $secs));
    sleep $secs;
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
