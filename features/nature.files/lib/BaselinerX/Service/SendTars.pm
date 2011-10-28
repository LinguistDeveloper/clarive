package BaselinerX::Service::SendTars;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use Baseliner::Sugar;

with 'Baseliner::Role::Service';

register 'service.send.tars' => {
  name    => 'Generate tars',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};
  my $pass     = $job->job_data->{name};

  for my $ref (@{$tar_list}) {
    my $balix = balix($ref->{host}, $ref->{os});
    $ref->{staging} = "\\" . config_get('config.bde')->{stawin};  # Just in case...
    my $from  = $ref->{path_from}; $from =~ s/\/\//\//g;
    my $to    = $ref->{path_to};
    my $st    = $ref->{staging};

    my $from_dir    = "$from/elements.tar";
    my $staging_dir = "$st\\APSDAT\\SCM\\elements.tar";

    if ($ref->{os} eq 'win') {
      $log->debug("Enviando $from_dir hasta $staging_dir");
      my ($rc, $ret) = $balix->sendFile($from_dir, $staging_dir);
      $log->error($ret) if $rc;

      my $temp_dir = config_get('config.bde')->{stawindirtemp} . "\\$pass";
      my $cmd = "mkdir \"$temp_dir\"";
      $log->debug($cmd);
      ($rc, $ret) = $balix->execute($cmd);
      $log->error($ret) if $rc;

      $log->debug("Enviando $st\\APSDAT\\SCM\\$pass\\elements.tar hasta $temp_dir/elements.tar");
      ($rc, $ret) = $balix->sendFile("$st\\APSDAT\\SCM\\$pass\\elements.tar", "$temp_dir/elements.tar");
      _throw("Error sending tar file: $ret") if $rc != 0;
    }
    elsif ($ref->{os} eq 'unix') {
      $log->debug("Creando directorio $to");
      $balix->executeas($ref->{user}, qq| mkdir -p $to |);

      $log->debug("Enviando ${from}/elements.tar a $to");
      my ($rc, $ret) = $balix->sendFile("${from}/elements.tar",
                                        "${to}/elements.tar");

      _throw("Error sending tar file: $ret") if $rc != 0;
    }
    else {
      _throw "Unknow Operating System";
    }
  }
  return;
}

1;
