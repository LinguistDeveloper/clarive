package BaselinerX::Service::ProcessElements;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.process.elements' => {name    => 'Process Elements',
                                        handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job   = $c->stash->{job};
  my $log   = $job->logger;
  my $type  = $job->job_data->{type};
  my $jobid = $job->{jobid};
  my $m     = Baseliner->model('Distribution');

  $log->debug("Job type is $type");

  $log->debug("Generando listado de nuevos elementos Windows...");
  my $win_tar_elements = $m->win_tar_elements($jobid, $type) || {};

  $log->debug("Generando listado de nuevos elementos UNIX...");
  my $unix_tar_elements = $m->unix_tar_elements($jobid, $type) || {};

  $log->debug("Generando listado de elementos Windows a borrar...");
  my $win_del_elements = $m->win_del_elements($jobid, $type) || {};

  $log->debug("Generando listado de elementos UNIX a borrar...");
  my $unix_del_elements = $m->unix_del_elements($jobid, $type) || {};

  $log->debug("Appending datos de staging al mapeo de elementos Windows...");
  $win_tar_elements = $self->add_staging($win_tar_elements)
    if keys %$win_tar_elements;
  $win_del_elements = $self->add_staging($win_del_elements)
    if keys %$win_del_elements;

  $self->purge_elements([$win_tar_elements,  $win_del_elements,
                         $unix_tar_elements, $unix_del_elements]);

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

