package BaselinerX::Service::Purga;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use BaselinerX::Comm::Balix;
use Try::Tiny;

### NOTA: Si no se quiere tocar nada, comentar todas las líneas en las que
### aparezca el comentario COTTON.

with 'Baseliner::Role::Service';

register 'service.baseliner.bde.purga' => {
  name    => 'Purges jobs and files as they become unneeded.',
  handler => \&run
};

sub mylog { _log "Purga :: ", @_ }

sub run {
  my ($self, $c, $config) = @_;
  ## Inicializamos las variables con las que jugar. Todas sacadas de BALI_CONFIG.
  my $purga_dias    = _bde_conf 'purga_dias';
  my $cerrado_dias  = _bde_conf 'cerrado_dias';
  my $log_dias      = _bde_conf 'purga_log';
  my $dir_pase_dias = _bde_conf 'dir_pase_dias';
  unless ($log_dias) {
  	my $default = 7;
  	mylog "log_dias vacío, inicializando a $default.";
  	$log_dias = $default;
  }
  unless ($dir_pase_dias) {
  	mylog "dir_pase_dias vacío, inicializando a 0.";
  	$dir_pase_dias = 0;
  }
  mylog "\nDump de parámetros:\n"
      . "-------------------\n"
      . "purga_dias:    $purga_dias\n"
      . "cerrado_dias:  $cerrado_dias\n"
      . "log_dias:      $log_dias\n"
      . "dir_pase_dias: $dir_pase_dias\n"
      . "\n"
      ;
  if ($purga_dias >= 0) {
  	mylog "Iniciando purga.";
    purge_closed_packages($cerrado_dias);
  }
  else {
    mylog "No se realizará la purga de datos de pase de BBDD y cerrados (purga_dias = $purga_dias). "
        . "Probablemente se trata de una purga realizada a petición.";
  }
  ## Comento la gran mayoría de ellos. El distribuidor ya tiene su purga.
  ## purge_dist_log_data();
  ## delete_dirs($dir_pase_dias);
  ## delete_pases_tar();
  ## staging_unix($log_dias);
  ## staging_windows();
  ## staging_biztalk();
  ## delete_log_files($log_dias);
  delete_poll_log($log_dias);
  delete_bali_logs();
  delete_bali_tmp();
  delete_bali_pases();
  delete_chm_logs();
  ## purge_baseliner_jobs();
  mylog "Fin de purga.";
  return;
}

### Deletes entries from BALI_JOB and BALI_JOB_ITEMS
sub purge_baseliner_jobs {
  my $days = 30;                       #TODO
  mylog "Purgando datos en Baseliner de jobs con fecha superior a $days días.";
  my @ids_to_delete = get_older_than_n_days($days);
  ## Delete from BALI_JOB.
  my $bali_job_del = Baseliner->model('Baseliner::BaliJob')->search({id => [@ids_to_delete]});
  $bali_job_del->delete;               # COTTON
  my $bali_job_items_del = Baseliner->model('Baseliner::BaliJobItems')->search({id_job => [@ids_to_delete]});
  $bali_job_items_del->delete;         # COTTON
  mylog "Datos en Baseliner purgados.";
  return;
}

### get_older_than_n_days : Int -> Array[Int]
### Gets the ids from all the jobs that started more than N days ago.
sub get_older_than_n_days {
  my ( $n_days) = @_;
  use Time::Interval;
  ## Get all the jobs from the database.
  my $rs = Baseliner->model('Baseliner::BaliJob')->search(undef, {select => [qw/id starttime/]});
  rs_hashref($rs);
  my $now = DateTime->now;
  map { $_->{id} } grep {
    my $interval = int convertInterval %{getInterval $_->{starttime}, $now}, ConvertTo => 'days';
    $interval > $n_days;
  } $rs->all;
}

sub delete_bali_pases {
  mylog "Purgando datos de los pases de Baseliner en disco.";
  my $log_dias_baseliner_pases = _bde_conf 'log_dias_baseliner_pase';
  my $log_home = car map { chomp $_; $_ } qx|echo \$BASELINER_LOGHOME|;
  my $fn = sub {
    mylog $_[0];
    qx|$_[0]|;                         # COTTON
  };
  $fn->($_) for (qq{find -L $log_home -type f \\( -name 'N.TEST*' -o -name 'N.ANTE*' -o -name 'N.CURS*' -o -name 'N.PROD*' \\) -mtime +$log_dias_baseliner_pases -exec rm -f {} \\; 2>&1},
                 qq{find -L $log_home -type f \\( -name 'B.TEST*' -o -name 'B.ANTE*' -o -name 'B.CURS*' -o -name 'B.PROD*' \\) -mtime +$log_dias_baseliner_pases -exec rm -f {} \\; 2>&1}
                 );
  mylog "Datos de pases de Baseliner en disco purgados.";
}

sub delete_bali_tmp {
  mylog "Purgando directorios de trabajo de los pases de Baseliner en disco.";
  my $log_dias_baseliner_pases = _bde_conf 'log_dias_baseliner_pase';
  my $tmp_home = car map { chomp $_; $_ } qx|echo \$BASELINER_TMPHOME|;
  my $fn = sub {
    mylog $_[0];
    qx|$_[0]|;                         # COTTON
  };
  $fn->($_) for (qq{find -L $tmp_home -type d \\( -name 'N.TEST*' -o -name 'N.ANTE*' -o -name 'N.CURS*' -o -name 'N.PROD*' -o -name 'harvest*' \\) -mtime +$log_dias_baseliner_pases -exec rm -rf {} + 2>&1},
                 qq{find -L $tmp_home -type d \\( -name 'B.TEST*' -o -name 'B.ANTE*' -o -name 'B.CURS*' -o -name 'B.PROD*' \\) -mtime +$log_dias_baseliner_pases -exec rm -rf {} + 2>&1},
                 qq{find -L $tmp_home -type f \\( -name 'harvest*' -o -name 'job-export*'\\) -mtime +$log_dias_baseliner_pases -exec rm -f {} \\; 2>&1}
                 );
  mylog "Datos de directorios de trabajo de los pases de Baseliner en disco purgados.";
}

sub delete_bali_logs {
  mylog "Purgando logs de Baseliner.";
  my $log_dias_baseliner = _bde_conf 'log_dias_baseliner';
  my $log_home = car map { chomp $_; $_ } qx|echo \$BASELINER_LOGHOME|;
  my $fn = sub {
    mylog $_[0];
    qx|$_[0]|;                         # COTTON
  };
  $fn->($_) for (qq{find -L $log_home -type f -name "bali_web*" -mtime +${log_dias_baseliner} -exec rm -f {} \\; 2>&1},
                 qq{find -L $log_home -type f -name "balid*" -mtime +${log_dias_baseliner} -exec rm -f {} \\; 2>&1});
  mylog "Logs de Baseliner purgados.";
}

sub delete_chm_logs {
  mylog "Purgando logs de Changeman.";

  my $cfg_chm=config_get('config.changeman.log_connection');
  my $balix = BaselinerX::Comm::Balix->new(os=>"unix", host=>$cfg_chm->{host}, port=>$cfg_chm->{port}, key=>$cfg_chm->{key});

  my $log_dias_baseliner = _bde_conf 'log_dias_baseliner';
  my $pattern=$cfg_chm->{pattern};
  $pattern=~s{\.P\.}{\.T\.};
  my $cmd = "find -L $cfg_chm->{logPath} -type f -name $pattern -mtime +${log_dias_baseliner} -exec rm -f {} \\; 2>&1";
  mylog "cmd: $cmd";

  my ($rc, $ret) = $balix->execute($cmd);
  if ($rc != 0) {
    mylog "Purga Warning: no se ha podido limpiar los ficheros de Chengeman en '$cfg_chm->{host}' ('$cfg_chm->{logPath}/$cfg_chm->{pattern}'):\n$ret";
  }
  mylog "Logs de Changeman purgados.";
}

sub delete_poll_log {
  my ($log_dias) = @_;
  mylog "Purgando logs del script poll...";
  my $poll_log_name = _bde_conf 'poll_log_name';
  my $poll_log_dir  = _bde_conf 'poll_log_dir';
  my ($filename, $extension) = ($1, $2) if $poll_log_name =~ m/(.+)\.(.+)/x;
  my $cmd = "find -L $poll_log_dir -type f -name *.${extension}.gz -time +${log_dias} -exec rm -f {} \\; 2>&1";
  mylog "cmd: $cmd";
  qx|$cmd|;                            # COTTON
  mylog "Logs del scripts poll purgados.";
}

sub delete_log_files {
  my ($log_dias) = @_;
  if ($log_dias >= 0) {
  	mylog "Purga: Limpieza de ficheros de log con más de $log_dias días.";
  	my $temp            = _bde_conf 'temp';
  	my $loghome         = _bde_conf 'loghome';
  	my $harvesthome_log = _bde_conf 'harvesthome';
  	mylog "temp:            $temp";
  	mylog "loghome:         $loghome";
  	mylog "harvesthome_log: $harvesthome_log";
  	my $fn = sub {
      my ($str) = @_;
      mylog $str;
      `$str`;                          # COTTON
    };
  	$fn->($_) for ("find -L \"$temp\" -type f -name \"*.log\" -mtime +$log_dias | grep -v \"Dispatcher.log\" | xargs rm -f; 2>&1",
  	               "find -L \"$temp\" -type d -name \"*.tmp\" -mtime +$log_dias -exec rm -Rf {} \\; 2>&1",
  	               "find -L \"$temp\" -type f -name \"carga*\" -mtime +$log_dias -exec rm -f {} \\; 2>&1",
  	               "find -L \"$temp\" -type f -name \"*.tar\" -mtime +$log_dias -exec rm -f {} \\; 2>&1",
  	               "find -L \"$temp\" -type f -name \"*.in\" -mtime +$log_dias -exec rm -f {} \\; 2>&1",
  	               "find -L \"$loghome\" -type f -name \"*.log\" -mtime +$log_dias | grep -v \"Dispatcher.log\" | grep -v \"DispatcherInf.log\" | grep -v \"baseliner\" | xargs rm -f; 2>&1",
  	               "find -L \"$harvesthome_log/log\" -type f -name \"*.log\" -mtime +$log_dias -exec rm -f {} \\; 2>&1",
  	               );
  }
  mylog "Purga de ficheros de log completada.";
}

sub staging_biztalk {
  my @deleted_dirs;
  try {
  	my $stawin     = _bde_conf 'stawinbizserver';
  	my $stawinport = _bde_conf 'stawinbizport';
  	my $stawindir  = _bde_conf 'stawinbizdir';
  	my $balix      = _balix(host => $stawin, port => $stawinport);
  	if ($stawindir && length($stawindir) > 1) {
  	  mylog 'Purga de Staging BizTalk - dirs pase.';
  	  my @dirs = do {
  	    my $cmd = qq|dir /B "$stawindir"|;
  	    mylog "cmd: $cmd";
  	    my ($rc, $ret) = $balix->execute($cmd);
  	    $ret =~ s/\r//g;
  	    split '\n', $ret;  	  	
  	  };
  	  ## Listado de pases a mantener en Staging.
  	  my @stapases = do {
  	    my $har_db = _har_db();
  	  	my $sql = qq{
          SELECT DISTINCT pas_codigo
                     FROM distpase
                    WHERE pas_desde > SYSDATE - 1
  	  	};
  	  	$har_db->db->array($sql);
  	  };
  	  mylog "Inicio purga de Staging Biztalk ($stawin).\n\n"
  	      . "Listado de pases a mantener:\n" . join('\n - ', @stapases) . '\n\n'
  	      . "Listado de directorios a eliminar:\n" . join('\n - ', @dirs);
  	  for my $pasedir (@dirs) {
  	  	$pasedir =~ s/\r//g;
  	  	if ($pasedir && length($pasedir) > 8 && ($pasedir =~ /^[A-Z]\./i) && !grep(/$pasedir/, @stapases)) {
  	  	  my $cmd = qq|rd /S /Q "$stawindir\\$pasedir|;
  	  	  mylog "cmd: $cmd";
  	  	  my ($rc, $ret) = $balix->execute($cmd);
  	  	  if ($rc != 0) {
  	  	  	mylog "Purga Warning: no se ha podido eliminar el directorio de pase de staging en '$stawin' ('$stawindir\\$pasedir'):\n$ret";
  	  	  }
  	  	  else {
  	  	    my $deleted_dir = "$stawin:$stawindir\\$pasedir";
            push @deleted_dirs, $deleted_dir;
            mylog "Directorio de pase de staging BizTalk eliminado en $deleted_dir.";
  	  	  }
  	  	}
  	  }
  	}
  	$balix->end;
  }
  catch {
  	mylog '***** Error durante la purga Staging BIZTALK: ' . shift;
  }; 
}

sub staging_windows {
  try {
  	my $stawin     = _bde_conf 'stawin';
  	my $stawinport = _bde_conf 'stawinport';
  	my $stawindir  = _bde_conf 'stawindir';
  	mylog "\nParámetros staging windows:\n"
  	    . "stawin: $stawin\n"
  	    . "stawinport: $stawinport\n"
  	    . "stawindir: $stawindir"
  	    ;
  	my $balix = _balix(host => $stawin, port => $stawinport);
  	if ($stawin && length($stawindir) > 1) {
  	  ## Borrar directorios de pase.
  	  do {
  	  	my @dirs = do {
  	  	  mylog "Purga de Staging Windows, directorios de pase.";
  	  	  my $cmd = qq|dir /B "$stawindir"|;
  	  	  mylog "cmd: $cmd";
  	  	  my ($rc, $ret) = $balix->execute($cmd);
  	  	  $ret =~ s/\r//sg;
  	  	  split('\n', $ret);  	  		
  	  	};
  	  	my @sta_pases = _staging_pases();
  	  	mylog "Inicio purga de Staging Windows ($stawin).";
  	  	mylog "Listado de pases a mantener:\n" . join('\n', @sta_pases);
  	  	mylog "listado de directorios a eliminar:\n" . join('\n', @dirs);
  	  	for my $pasedir (@dirs) {
  	  	  $pasedir =~ s/\r//g;
  	  	  ## Si el directorio no está en el listado de pases a mantener, lo borramos.
  	  	  if ($pasedir && length($pasedir) > 8 && ($pasedir =~ /^[A-Z]\./i) && !grep(/$pasedir/, @sta_pases)) {
  	  	  	my $cmd = qq|rd /S /Q "$stawindir\\$pasedir"|;
  	  	  	mylog "cmd: $cmd";
  	  	  	my ($rc, $ret) = $balix->execute($cmd);
  	  	  	if ($rc != 0) {
  	  	  	  mylog "Purga Warning: no se ha podido eliminar el directorio de pase de staging en '$stawin' ('$stawindir\\$pasedir'):\n$ret\n";
  	  	  	}
  	  	  	else {
  	  	  	  my $deleted_dir = "$stawin:$stawindir\\$pasedir";
              mylog "Ok. Directorio de pase de staging windows eliminado en '$stawin:$stawindir\\$pasedir'\n";
  	  	  	}
  	  	  }
  	  	}
  	  };
  	}
  	## Borrar directorios de release borrados.
  	do {
      my @sta_releases;
      if (_bde_conf 'purga_releases_borradas' eq '1') {  
        ## Mejor no hacer esto en test.
        mylog "Purga de Staging Windows, directorios de release.";
        my $stawindirpub = _stawindirpub();
        my @dirs = do {
          my $cmd = qq|dir /A:D /B /S "$stawindirpub"|;
          mylog "cmd: $cmd";
          my ($rc, $ret) = $balix->execute($cmd);
          split('\n', $ret);
        };
        my @sta_releases = _staging_releases_win();
        mylog "Iniciando purga de releases Windows.";
        mylog "Listado de releases a mantener:\n" . join('\n', @sta_releases);
        mylog "Listado de directorios a eliminar:\n" . join('\n', @dirs);
        foreach (@dirs) {
          s/\r//g;
          if (/^.*\\(.*?)\\(.*?)$/) {
          	my $cam    = $1;
          	my $reldir = $2;
          	## Sólo releases que vienen del cam. Hay cosillas en PUBLICO de 
          	## Windows que no son de Harvest.
          	next if $cam ne substr($reldir, 0, 3);
          	if ($reldir && length($reldir) >= 5 && !grep(/$reldir/, @sta_releases)) {
          	  my $cmd = qq|rd /S /Q "$stawindirpub\\$cam\\$reldir"|;
          	  mylog "cmd: $cmd";
          	  my ($rc, $ret) = $balix->execute($cmd);
          	  mylog $rc != 0
          	    ? "Purga Windows('$stawin') - WARNING :No se ha podido eliminar el directorio de release en ('$stawindirpub\\$cam\\$reldir'):\n$ret\n"
          	    : "Purga Windows('$stawin'):Ok.Release eliminada '$stawindirpub\\$cam\\$reldir'\n";
          	}
          	else {
              mylog "Purga Windows('$stawin'): Descartado directorio de release '$reldir'";
          	}
          }
        }
      }
  	};
  	## Borrado directorios de releases borrados Eclipse.
  	do {
      my $sta_win_dir_pub_eclip = _bde_conf 'sta_eclipse_staging';
      $sta_win_dir_pub_eclip =~ s/\\\\/\\/g;
      my $cmd = "dir /A:D /B \"$sta_win_dir_pub_eclip\"";
      mylog "cmd: $cmd";
      my ($rc, $ret) = $balix->execute($cmd);
      my @dirs_app = split ' ', $ret;
      my @sta_releases = _staging_releases_win();
      for my $app (@dirs_app) {
      	my @dirs_eclipse = do {
      	  $cmd = qq|dir /A:D /B "$sta_win_dir_pub_eclip\\$app"|;
      	  mylog $cmd;
      	  ($rc, $ret) = $balix->execute($cmd);
      	  split ' ', $ret;       		
      	};
      	for my $dir_eclipse (@dirs_eclipse) {
      	  my $dir_eclipse_backup = $dir_eclipse;
      	  $dir_eclipse =~ s/_/-/g;
      	  unless (grep(/$dir_eclipse/, @sta_releases)) {
      	  	$cmd = qq|rd /S /Q "$sta_win_dir_pub_eclip\\$app\\$dir_eclipse_backup"|;
      	  	mylog "cmd: $cmd";
      	  	($rc, $ret) = $balix->execute($cmd);
      	  	if ($rc != 0) {
      	  	  my $msg = "Purga Windows('$stawin') - WARNING:No se ha podido eliminar el directorio :'$sta_win_dir_pub_eclip\\$app\\$dir_eclipse_backup'):\n$ret\n";
      	  	  mylog $msg;
      	  	}
      	  	else {
      	  	  mylog "Purga Windows('$stawin'):Directorio de release PURGADO: $sta_win_dir_pub_eclip\\$app\\$dir_eclipse_backup'\n";
      	  	}
      	  }
      	  else {
      	  	mylog "Purga de Windows ('$stawin'): Descartado directorio '$dir_eclipse_backup'";
      	  }
      	}
      }
  	};
  }
  catch {
  	mylog "Error durante la purga staging Windows. " . shift();
  };
}

sub _staging_releases_win {
  ## Listado de pases a mantener en staging.
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my $sql    = qq{
    SELECT DISTINCT TRIM (packagename)
               FROM harpackage p, harenvironment e, harstate s
              WHERE p.stateobjid = s.stateobjid
                AND s.envobjid = e.envobjid
                AND TRIM (environmentname) = 'PUBLICO'
                AND TRIM (statename) <> 'Borrado'
  };
  mylog "sql: $sql";
  $har_db->db->array($sql);
}

sub _staging_pases {
  ## Listado de pases a mantener en staging.
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my $sql    = qq{
  	SELECT DISTINCT pas_codigo
               FROM distpase
              WHERE pas_desde > SYSDATE - 1
  };
  mylog "sql: $sql";
  $har_db->db->array($sql);
}

sub staging_unix {
  my ($log_dias) = @_;
  try {
    my $staunix_port = _bde_conf 'staunixport';
    my $staunix_dir  = _bde_conf 'staunixdir';
    for my $staunix (split(',', _bde_conf 'staunix')) {
      try {
        my $balix = _balix(host => $staunix, port => $staunix_port);
        if ($staunix_dir) {
          ## Borro tar del directorio temporal de harax que se hayan podido
          ## quedar en pases fallidos.
          do {
          	mylog "Purga de staging UNIX - Borrado de tar en directorio temporal de harax.";
          	my $temp_harax = _bde_conf 'temp_harax';
          	my $cmd        = "cd $temp_harax; find *.tar -mtime +$log_dias ";
          	mylog "cmd: $cmd";
          	my ($rc, $ret) = $balix->execute($cmd);
          	if ($rc == 0) {
          	  for my $tars (split(/\n/, $ret)) {
          	  	$cmd = "cd $temp_harax; rm $tars";
          	  	mylog "cmd: $cmd";
          	  	($rc, $ret) = $balix->execute($cmd);  # COTTON
          	  	mylog $rc == 0
          	  	  ? "Borrado fichero $temp_harax$tars con más de $log_dias"
          	  	  : "No se ha podido borrar el fichero -> $temp_harax$tars\n$ret\n";
          	  }
          	}
          	elsif ($ret =~ /0652-019/) {
          	  mylog "No hay nada que borrar.";
          	}
          	else {
          	  mylog "No he podido realizar la búsqueda\n$ret\n";
          	}
          };
          ## Borro directorios de pase.
          do {
          	mylog "Purga de directorios de pase.";
          	my $cmd = "ls '$staunix_dir/pase'";
          	mylog "cmd: $cmd";
          	my ($rc, $ret) = $balix->execute($cmd);
          	my @dirs = split('\n', $ret);
          	my @sta_pases = do {
          	  my $har_db = BaselinerX::CA::Harvest::DB->new;
          	  my $sql    = qq{
          	  	SELECT DISTINCT pas_codigo
                           FROM distpase
                     WHERE pas_desde > SYSDATE - 1
          	  };
          	  $har_db->db->array($sql);
          	};
          	mylog "Inicio purga de staging UNIX $staunix.";
          	mylog "\nListado de pases a mantener (no han sido purgados del monitor): " . join('\n', @sta_pases);
          	mylog "\nListado de directorios a eliminar:" . join('\n', @dirs);
          	for my $pasedir (@dirs) {
          	  if ($pasedir && length $pasedir > 8 && !grep(/$pasedir/, @sta_pases)) {
          	  	## Si el directorio no está en el listado de pases a mantener. Lo borramos.
          	  	$cmd = "rm -Rf '$staunix_dir/pase/$pasedir";
          	  	mylog $cmd;
          	  	($rc, $ret) = $balix->execute($cmd);  # COTTON
          	  	if ($rc != 0) {
          	  	  mylog "No se ha podido eliminar el directorio de pase de staging en '$staunix' "
          	  	      . "($staunix_dir/pase/$pasedir): $ret\n";          	  		
          	  	}
          	  	else {
          	  	  my $deleted_dir = "$staunix:$staunix_dir/pase/$pasedir";
          	  	  mylog "OK. Directorio de pase de staging unix eliminado en '$deleted_dir'";
          	  	}
          	  }
          	}
          };
        }
        ## Borro dirs de releases borradas.
        do {
	      if (_bde_conf 'purga_releases_borradas' eq '1') {
	        mylog "Purga de staging UNIX, release de directorios";
	        my $pubname = _bde_conf 'pubname';
	        my $cmd = "ls '$staunix_dir/$pubname";
	        my ($rc, $ret) = $balix->execute($cmd);
	        my @dirs         = split('\n', $ret);
	        ## Listado de pases a mantener en staging.
	        my @sta_releases = do {
	      	  my $har_db = BaselinerX::CA::Harvest::DB->new;
	       	  my $sql = qq{
	            SELECT DISTINCT TRIM (packagename)
	                       FROM harpackage p, harenvironment e, harstate s
	                      WHERE p.stateobjid = s.stateobjid
	                        AND s.envobjid = e.envobjid
	                        AND TRIM (environmentname) = 'PUBLICO'
	                        AND TRIM (statename) <> 'Borrado'
	      	  };
	       	  mylog "sql: $sql";
	       	  $har_db->db->array($sql);
	        };
	        mylog "Inicio purga de Releases UNIX ($staunix).";
	        mylog "Listado de releases a mantener (no han sido purgados del monitor):\n"
	            . join('\n', @sta_releases);
	        mylog "Listado de directorios a eliminar:\n" . join('\n', @dirs);
	        for my $reldir (@dirs) {
	          ## Si el directorio no está en el listado de releases a mantener, lo borramos.
	          if ($reldir && length $reldir > 5 && !grep(/$reldir/, @sta_releases)) {
	          	$cmd = "rm -Rf '$staunix_dir/$pubname/$reldir'";
	          	mylog "cmd: $cmd";
	          	($rc, $ret) = $balix->execute($cmd);  # COTTON
	          	if ($rc == 0) {
	          	  my $deleted_dir = "$staunix:$staunix_dir/$pubname/$reldir";
	          	  mylog "Ok. Directorio de pase '$pubname' de staging UNIX eliminado en '$deleted_dir'.";
	          	}
	          	else {
                  mylog "Warning: No se ha podido eliminar el directorio de release de staging en '$staunix' "
                      . "('$staunix_dir/$pubname/$reldir): $ret\n";
	          	}
	          }
	          else {
	          	mylog "Descartado directorio de release '$reldir'.";
	          }
	        }
	      }        	
        };
        $balix->end;
        mylog "Fin de purga staging";
      }
      catch {
      	mylog "No he podido purgar staging $staunix:$staunix_port. Compruebe si el servidor está levantado.";
      };
    }
  }
  catch {
    mylog ahora() . " - *** Error durante la purga Staging UNIX: " . shift;;
  };
}

sub delete_pases_tar {
  my $backup_home   = _bde_conf 'backuphome';
  my $purga_dirpase = _bde_conf 'purga_dirpase';
  my $cmd = "find \"$backup_home\" -type f -name \"*\" -mtime +$purga_dirpase -exec rm {} \\;";
  mylog $cmd;
  `$cmd`;                              # COTTON
}

sub delete_dirs {
  my ($dir_pase_dias) = @_;
  my $pasehome = _bde_conf 'pasehome';
  my @dirs     = glob("$pasehome/*");
  unless (@dirs) {
  	mylog "No se han hayado directorios.";
  	return;
  }
  my @pases = do {
  	my $har_db = BaselinerX::CA::Harvest::DB->new;
  	my $sql    = qq{
      SELECT DISTINCT pas_codigo
                 FROM distpase
                WHERE pas_estado = 'P' AND pas_desde < SYSDATE - $dir_pase_dias  		
  	};
  	$har_db->db->array($sql);
  };
  foreach (@dirs) {
    s/\/.*\/(.*)$/$1/g;
    my $pasedir = $_;
    if ($pasedir && grep (/$pasedir/, @pases)) {
      my $dirborra = "$pasehome/$pasedir";
      if (length($dirborra) > 5) {
        mylog "------->  rm $dirborra\n";
        `chmod -R 750 $dirborra`;      # Readonly.
        system("rm -Rf $dirborra");    # COTTON
      }
    }
  }
}

sub purge_closed_packages {
  my ($cerrado_dias) = @_;
  if ($cerrado_dias >= 0) {
    mylog "Purga de paquetes a cerrado...";
    my %apls = _build_apls(_build_cerrados($cerrado_dias));
    unless (%apls) {
      mylog "No se han detectado paquetes a cerrar.";
      return;
    }
    mylog "Lista de paquetes a cerrar en producción\n" . Data::Dumper::Dumper \%apls;

    # Close packages.
    my $haruser = _har_conf 'user';
    my $harpass = _har_conf 'harpwd';
    my $broker  = _har_conf 'broker';
    my $loghome = _bde_conf 'loghome';
    for my $env (keys %apls) {
      my @packages     = _unique @{$apls{$env}};
      my $package_list = join ' ', @packages;
      my $logfile      = "$loghome/hppcerrado$$-" . ahora() . ".log";
      my $farg         = write_arg_file qq{-b $broker $haruser $harpass -en $env -st "Producción" -o "$logfile" $package_list};   
      mylog "Listado de paquetes -> $package_list";
      mylog "logfile -> $logfile";
      mylog "argumentos write_arg_file -> $farg";
=begin TODO -- Descomentar para cuando la query pueda devolver algo.
      my @ret = `hpp "$farg"`;
      my $rc  = $?;
      mylog $rc != 0
        ? "ERROR -- Error al intentar cerrar paquetes $env:\n$package_list"
        : "Cerrado paquetes de $env OK.\n$package_list";
      unlink $farg;  # ¿Qué demonios hace esto?
=cut
    }
  }
  else {
  	mylog "No se realizará la purga de cerrados.";
  }
}

sub purge_dist_log_data {
  mylog "Purgando datos de log y consola...";
  my $query = qq{
    DELETE FROM distlogdata
          WHERE dat_ts < (SYSDATE - 250)
  };
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  $har_db->db->do($query);             # COTTON
  return;
}

sub _build_cerrados {
  my ($cerrado_dias) = @_;
  mylog "Obteniendo listado de paquetes cerrados...";
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my $sql = qq{
    SELECT *
      FROM (SELECT TRIM (d.pas_codigo) codigo, TRIM (packagename) pkg,
                   TRIM (environmentname) env, TRIM (d.pas_subapl) subapl,
                   (SELECT MAX (d2.pas_codigo)
                      FROM distpase d2,
                           harstate s2,
                           harpackage p2,
                           dist_paquete_pase pp2
                     WHERE d2.pas_tipo = 'PROD'
                       AND SUBSTR (d2.pas_aplicacion, 1, 3) =
                                                    SUBSTR (environmentname, 1, 3)
                       AND pp2.pase = d2.pas_codigo
                       AND pp2.packageobjid = p2.packageobjid
                       AND p2.stateobjid = s2.stateobjid
                       AND UPPER (TRIM (s2.statename)) = 'PRODUCCIÓN') maxcod
              FROM harpackage p,
                   dist_paquete_pase pp,
                   distpase d,
                   harstate s,
                   harenvironment e
             WHERE p.packageobjid = pp.packageobjid
               AND pp.pase = d.pas_codigo(+)
               AND d.pas_estado(+) IN ('F')
               AND d.pas_tipo(+) = 'PROD'
               AND d.pas_codigo(+) LIKE 'N%'
               AND s.stateobjid = p.stateobjid
               AND TRIM (s.statename) = 'Producción'
               AND p.modifiedtime < (SYSDATE - ?)
               AND p.envobjid = e.envobjid)
     WHERE (   (codigo IS NULL AND maxcod IS NOT NULL)
            OR (TRIM (codigo) <> TRIM (maxcod))
           )
  };
  my @result = $har_db->db->array($sql, $cerrado_dias);
  mylog "cerrado => " . join(', ', @result) if @result;
  @result;
}

sub _build_apls {
  my @cerrados = @_;
  my %apls;                            # {env => [packages]}
  while (@cerrados) {
  	my $pase   = shift @cerrados;
  	my $pkg    = shift @cerrados;
  	my $env    = shift @cerrados;
    my $subapl = shift @cerrados;
  	my $maxcod = shift @cerrados;
  	push @{$apls{$env}}, $pkg;
  }
  %apls;
}

sub _stawindirpub {
  my $mock = _bde_conf 'stawindirpublico';
  $mock =~ s/\\\\/\\/g;
  $mock;
}

1;
