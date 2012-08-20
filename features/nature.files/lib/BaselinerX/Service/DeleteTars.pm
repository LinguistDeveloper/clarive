package BaselinerX::Service::DeleteTars;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.delete.tars' => {name    => 'Delete tars',
                                   handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};

  $log->info("Borrando elementos .tar.");

  for my $ref (@{$tar_list}) {
    my $balix = balix($ref->{host}, $ref->{os});
    my $from  = $ref->{path_from};
    my $to    = $ref->{path_to};
    if ($ref->{os} eq 'win') {
      my $command = "cd /D $ref->{staging}\\N.TESTERIC\\ & del /Q /F *.tar";
      $balix->execute($command);
    }
    elsif ($ref->{os} eq 'unix') {
      my $command = "cd $ref->{path_to} ; rm -rf *.tar";
      $balix->executeas($ref->{user}, $command);
    }
  }

  $log->info("Elementos .tar borrados.");
  return;
}

1;
