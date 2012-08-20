package BaselinerX::Service::J2EE::Init;
use 5.010;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.j2ee.init' => {
  name    => 'J2EE Init',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $bl       = $job->job_data->{bl};
  my $log      = $job->logger;
  return 1;
}

1;
