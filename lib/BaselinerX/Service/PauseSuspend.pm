package BaselinerX::Service::PauseSuspend;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;

with 'Baseliner::Role::Service';

register 'service.job.pause' => { 
    name => 'Pause a Job', 
    job_service  => 1,
    icon=>'/static/images/icons/job.png',
    #icon=>'/static/images/icons/pause.gif',
    form => '/forms/pause_job.js',
    handler => \&run_pause, };

sub run_pause {
    my ($self,$c, $config)=@_;

    my $stash = $c->stash;
    my $job = $stash->{job};
    my $log = $job->logger;
    $config ||= {};
    
    $job->pause( %$config ) ;
    
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
