package BaselinerX::Service::DeleteTars;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;

with 'Baseliner::Role::Service'; 

register 'service.delete.tars' => {name    => 'Delete tars',
                                   handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};

  for my $ref (@{$tar_list}) {
    my $balix = balix($ref->{host}, $ref->{os});
    my $from = $ref->{path_from};
    my $to   = $ref->{path_to};

    if ($ref->{os} eq 'win') {
      my $command = "cd /D $ref->{staging}\\N.TESTERIC\\ & del /Q /F *.tar";
      my ($rc, $ret) = $balix->execute($command);
      $log->debug($self->error_output($command, $ret)); }
    elsif ($ref->{os} eq 'unix') {
      my $command = "cd $ref->{path_to} ; rm -rf *.tar";
      my ($rc, $ret) = $balix->executeas($ref->{user}, $command);
      $log->debug($self->error_output($command, $ret)); } }

  return }

sub error_output {
  my ($self, $command, $output) = @_;
  "Error while performing command $command => \n $output" }

1
