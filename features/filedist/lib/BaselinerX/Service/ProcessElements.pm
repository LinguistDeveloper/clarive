package BaselinerX::Service::ProcessElements;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service'; 

register 'service.process.elements' => { name    => 'Process Elements'
                                       , handler => \&main };

sub main {
  my ($self, $c, $config) = @_;
  my $job   = $c->stash->{job};
  my $log   = $job->logger;
  $job->job_stash->{win_tar_elements}  
    = Baseliner->model('Distribution')->win_tar_elements($job->{jobid});
  $job->job_stash->{unix_tar_elements}
    = Baseliner->model('Distribution')->unix_tar_elements($job->{jobid});
}

1
