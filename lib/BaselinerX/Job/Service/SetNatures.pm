package BaselinerX::Job::Service::SetNatures;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.job.set.natures' => {
  name    => 'Job Set Natures',
  handler => \&run,
};

sub run {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $elements = $job->job_stash->{elements}->{elements};
  $job->job_stash->{natures} =
    [keys %{{map { $_->{path} =~ /\/\w+\/(.\w+)/ => 1 } @{$elements}}}];
  $log->debug("Naturalezas del pase: " . join ', ', @{$job->job_stash->{natures}});
  return;
}

1;
