package BaselinerX::Job::Service::SetSubApps;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;

with 'Baseliner::Role::Service';

register 'service.job.set.subapps' => {name    => 'Job Set Subapplications',
                                       handler => \&run};

sub run {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $elements = $job->job_stash->{elements}->{elements};
  my $jobid    = $job->{jobid};
  my $natures_with_subapps = natures_with_subapps();
  my @subappls = map { "subappl/$_" } grep { $_ } _unique map { (_pathxs $_->{path}, 3) if (_pathxs $_->{path}, 2) ~~ @{$natures_with_subapps} } @{$elements}; # (Sorry)
  my $row = $job->row;
  for my $subapp (@subappls) {
    $row->bali_job_items->create({item => $subapp});
    _log "Inserting $subapp into BALI_JOB_ITEMS...";
  }
  return;
}

sub natures_with_subapps { [qw/J2EE .NET BIZTALK VIGNETTE/] }

1;
