package BaselinerX::Service::Untar;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use utf8;

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
    my $host  = $ref->{host};

    if ($from =~ m/unix/i) {
      $log->debug("Untar in $to ($ref->{host})");
      my $owner =
        exists $ref->{group}
        ? "$ref->{user}:$ref->{group}"
        : $ref->{user};
      my $command = "cd $ref->{path_to} ; tar -xvf ./elements.tar";
      $log->debug("Command is: $command");
      my ($rc, $ret) = $balix->executeas($ref->{user}, $command);
      $log->debug("OUTPUT: " . $ret);
    }
    if ($from =~ m/win/i) {
      my $pass      = $job->job_data->{name};
      my $stawindir = _bde_conf('stawindir') . "\\$pass";
      _log "stawindir: $stawindir";

      my $st       = _bde_conf 'stawin';
      my $balix_st = balix_win($st);

      do {
        _log "Hago untar en $stawindir";
        my ($rc, $ret) = $balix_st->execute("cd /D $stawindir & C:\\APS\\SCM\\Cliente\\tar -xvf $pass.tar");
        _log "rc: $rc";
        _log "ret: $ret";
        unless ($rc == 0 || $rc == 1) {
          $log->error($ret);
          _throw($ret);
        }
        else {
          $log->info("Descomprimiendo archivos...");
          ($rc, $ret) = $balix_st->execute("dir $stawindir\\");
          _log "Untar completado.\n$ret";
        }
      };

      do {
        _log "Borrando fichero .tar";
        my $cmd = "DEL /Q $stawindir\\$pass.tar";
        _log "cmd: $cmd";
        my ($rc, $ret) = $balix_st->execute($cmd);
        _log "rc: $rc";
        _log "ret: $ret";
      };

      do {
        $log->info("Aplicando permisos...");
        _log "Copio a la carpeta temporal para que se hereden los ficheros...";
        my $sta_win_dir_temp = _bde_conf('stawindirtemp') . "\\$pass";
        _log "directorio temporal: $sta_win_dir_temp";

        _log "Creo primero la carpeta de destino para evitar conflictos...";
        my ($rc, $ret) = $balix_st->execute("MKDIR \"$sta_win_dir_temp\"");
        _log "rc: $rc";
        _log "ret: $ret";

        _log "Copiando a la carpeta temporal...";
        my $cmd = "xcopy /E /F /R /Y /I $stawindir\\* $sta_win_dir_temp";
        _log "cmd: $cmd";
        ($rc, $ret) = $balix_st->execute($cmd);
        _log "rc: $rc";
        _log "ret: \n$ret";
        $log->info("Permisos aplicados");

        $log->info("Distribuyendo al host de destino...");
        _log "Copio del temporal al host...";
        $cmd = "xcopy /E /F /R /Y /I $sta_win_dir_temp\\* \\\\$host$to";
        _log "cmd: $cmd";
        ($rc, $ret) = $balix_st->execute($cmd);
        _log "rc: $rc";
        _log "ret: \n$ret";
        $log->info("Ficheros distribuidos", $ret);
      };
    }
  }
  return;
}

1;
