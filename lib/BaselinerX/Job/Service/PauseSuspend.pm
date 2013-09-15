package BaselinerX::Job::Service::PauseSuspend;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.pause' => { 
    name => 'Pause a Job', 
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

1;
