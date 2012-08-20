package BaselinerX::Job::Service::SetNatures;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.job.set.natures' => {name    => 'Job Set Natures',
                                       handler => \&run};

sub run {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $elements = $job->job_stash->{elements}->{elements};
  my $jobid    = $job->{jobid};

  my @natures = grep $_->can_i_haz_nature($elements), 
                     map { Baseliner::Core::Registry->get($_) } 
                         $c->registry->starts_with('nature');

  $log->debug("Naturalezas del pase: " . join ', ', map { $_->name } @natures);

  my @natures_to_insert = map { $_->ns } @natures;

  my @existing_natures = do {
    my $m = Baseliner->model('Baseliner::BaliJobItems');
    my $rs = $m->search({id_job               => $jobid,
                         'substr(item, 0, 6)' => 'nature'},
                        {select => {distinct => 'item'},
                         as     => 'nature'});
    rs_hashref($rs);
    map { $_->{nature} } $rs->all;
  };

  my $row = $job->row;
  for my $nature (@natures_to_insert) {
    unless ($nature ~~ @existing_natures) {
      $row->bali_job_items->create({item => $nature});
      _log "Inserting $nature into BALI_JOB_ITEMS...";
    }
  }
  return;
}

1;
