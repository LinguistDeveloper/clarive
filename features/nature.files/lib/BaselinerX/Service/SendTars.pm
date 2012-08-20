package BaselinerX::Service::SendTars;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.send.tars' => {name    => 'Generate tars',
                                 handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};
  my $pass     = $job->job_data->{name};

  for my $ref (@{$tar_list}) {
    my $balix = balix($ref->{host}, $ref->{os});
    $ref->{staging} = config_get('config.bde')->{stawin};
    my $from = $ref->{path_from};
    $from =~ s/\/\//\//g;
    my $to = $ref->{path_to};
    my $st = $ref->{staging};

    my $from_dir    = "$from/elements.tar";

    if ($ref->{os} eq 'win') {
      my $stawindir = _bde_conf('stawindir') . "\\$pass";
      _log "stawindir: $stawindir";

      _log "Iniciando conexión balix a $st...";
      my $balix_st = balix_win($st);
      _log "Conexión balix resuelta.";

      do {
        _log "Creando directorio temporal por si no existe...";
        my $cmd = "mkdir \"$stawindir\"";
        _log "cmd: $cmd";
        my ($rc, $ret) = $balix_st->execute($cmd);
        unless ($rc == 0 || $rc == 1) {  # What if it returns 1.5? :D
          $log->error($ret);
          _throw $ret;
        }
      };
      do {
        _log "Enviando fichero de $from_dir a $stawindir";
        my ($rc, $ret) = $balix_st->sendFile($from_dir, "$stawindir\\$pass.tar");
        unless ($rc == 0 || $rc == 1) {
          $log->error($ret);
          _throw $ret;
        }
      };

      _log "Fichero .tar enviado.";
    }
    elsif ($ref->{os} eq 'unix') {
      $log->debug("Creando directorio $to");
      $balix->executeas($ref->{user}, qq| mkdir -p $to |);

      $log->debug("Enviando ${from}/elements.tar a $to");
      my ($rc, $ret) = $balix->sendFile("${from}/elements.tar", "${to}/elements.tar");

      _throw("Error sending tar file: $ret") if $rc != 0;
    }
    else {
      _throw "Unknow Operating System";
    }
  }
  return;
}

1;
