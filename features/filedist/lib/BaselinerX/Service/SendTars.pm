package BaselinerX::Service::SendTars;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;

with 'Baseliner::Role::Service'; 

register 'service.send.tars' => {name    => 'Generate tars',
                                 handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job = $c->stash->{job};
  my $log = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};

  for my $ref (@{$tar_list}) {
    my $balix = balix($ref->{host}, $ref->{os});
    my $from  = $ref->{path_from};
    my $to    = $ref->{path_to};
    my $st    = $ref->{staging};

    if ($ref->{os} eq 'win') {
      $log->debug("Enviando desde ${from} hasta ${st}");
      my ($rc, $ret) = $balix->sendFile("${from}/elements.tar"
                                       ,"$st\\N.TESTERIC\\elements.tar") if $ref->{os} eq 'win';
      _throw ("error al enviar .tar") if $rc != 0; }

    if ($ref->{os} eq 'unix') {
      $log->debug("Enviando ${from}/elements.tar a $to");
      my ($rc, $ret) = $balix->sendFile("${from}/elements.tar", "${to}/elements.tar") if $ref->{os} eq 'unix';
      _throw ("error al enviar .tar") if $rc != 0; } }

  return }

1
