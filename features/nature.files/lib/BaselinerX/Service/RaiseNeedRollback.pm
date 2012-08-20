package BaselinerX::Service::RaiseNeedRollback;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.raise.flag.need_rollback' => {name    => 'Raise need_rollback',
                                                handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job = $c->stash->{job};
  my $log = $job->logger;
  $log->debug("Raising flag: need_rollback");
  $job->stash->{need_rollback} = 1;
  return;
}

1;
