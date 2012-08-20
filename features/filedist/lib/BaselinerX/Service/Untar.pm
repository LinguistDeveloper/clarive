package BaselinerX::Service::Untar;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;

with 'Baseliner::Role::Service'; 

register 'service.untar' => {name    => 'Untar',
                             handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};

  for my $ref (@{$tar_list}) {
    my $balix = balix($ref->{host}, $ref->{os});
    my $from  = $ref->{path_from};
    my $to    = $ref->{path_to};

    if ($from =~ m/unix/i) {
      $log->debug("Untar in $to ($ref->{host})");
      my $owner = exists $ref->{group} ? "$ref->{user}:$ref->{group}" 
                :                        $ref->{user};
      my $command = "cd $ref->{path_to} ; tar -xvf ./elements.tar";
      $log->debug("Command is: $command");
      my ($rc, $ret) = $balix->executeas($ref->{user}, $command);
      $log->debug("OUTPUT: " . $ret); }

    if ($from =~ m/win/i) {
      my ($rc, $ret) = 
           $balix->execute("cd /D $ref->{staging}\\N.TESTERIC" 
                           . " & C:\\APS\\SCM\\Cliente\\tar -xvf elements.tar");
      $log->debug($ret);
      _throw ("Error while using tar on Windows") if $rc;

      $log->debug("Init xcopy");
      ($rc, $ret) = $balix->execute("xcopy /E /F /R /Y /I " 
                                    . "$ref->{staging}\\N.TESTERIC\\* $to");
      $log->debug($ret);
      $log->debug("End xcopy");
      _throw ("Error while copying from staging to host server") if $rc; } }

  return }

1
