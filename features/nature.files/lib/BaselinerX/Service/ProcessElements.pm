package BaselinerX::Service::ProcessElements;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use Data::Dumper;

with 'Baseliner::Role::Service';

register 'service.process.elements' => {
  name    => 'Process Elements',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job  = $c->stash->{job};
  my $log  = $job->logger;
  my $type = $job->job_data->{type};

  $log->debug("Job type is $type");

  # my $new_type = $job->job_stash->{need_rollback} == 1 ? 'demote'
  #              : $job->type =~ m/demote/i              ? 'demote'
  #              : $job->type =~ m/promote/i             ? 'promote'
  #              :                                         'promote'    
  #              ;

  # $log->debug("Changed job type to $type") if $type ne $new_type;

  $log->debug("Generating win_tar_elements...");
  my $win_tar_elements  = Baseliner->model('Distribution')
                           ->win_tar_elements($job->{jobid}, $type) || {};

  $log->debug("Generating unix_tar_elements...");
  my $unix_tar_elements = Baseliner->model('Distribution')
                           ->unix_tar_elements($job->{jobid}, $type) || {};

  $log->debug("Generating win_del_elements...");
  my $win_del_elements  = Baseliner->model('Distribution')
                           ->win_del_elements($job->{jobid}, $type) || {};

  $log->debug("Generating unix_del_elements...");
  my $unix_del_elements = Baseliner->model('Distribution')
                           ->unix_del_elements($job->{jobid}, $type) || {};

  # Adding staging to win mappings...
  $win_tar_elements = $self->add_staging($win_tar_elements) 
    if keys %$win_tar_elements;
  $win_del_elements = $self->add_staging($win_del_elements)
    if keys %$win_del_elements;

  $self->purge_elements([$win_tar_elements,
                         $win_del_elements,
                         $unix_tar_elements,
                         $unix_del_elements]);
  
  $job->job_stash->{win_tar_elements} = $win_tar_elements
    if keys %{$win_tar_elements};
  $job->job_stash->{unix_tar_elements} = $unix_tar_elements
    if keys %{$unix_tar_elements};
  $job->job_stash->{win_del_elements} = $win_del_elements
    if keys %{$win_del_elements};
  $job->job_stash->{unix_del_elements} = $unix_del_elements
    if keys %{$unix_del_elements};

  return;
}

sub add_staging {
  my ($self, $xs) = @_;
  for my $arrayref (values %$xs) {
    for my $href (@$arrayref) {
      $href->{st} = config_get('config.bde')->{stawin};
    }
  }
  return $xs;
}

sub purge_elements {
  my ($self, $hash_vector) = @_;
  for my $hashref (@$hash_vector) {
    for my $key (keys %$hashref) {
      delete $hashref->{$key} unless $hashref->{$key};
    }
  }
  return;
}

1;
