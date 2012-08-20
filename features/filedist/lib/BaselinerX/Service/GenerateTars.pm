package BaselinerX::Service::GenerateTars;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service'; 

register 'service.generate.tars' => {name    => 'Generate tars',
                                     handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};
  for my $ref (@{$tar_list}) {
    unless (`ls $ref->{path_from}` =~ m/\.tar/) {
      `cd $ref->{path_from} ; tar -cv -f elements.tar --files-from='new_elements' 2>&1` } }
  return }

1
