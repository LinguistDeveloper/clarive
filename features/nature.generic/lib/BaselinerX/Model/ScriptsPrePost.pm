package BaselinerX::Model::ScriptsPrePost;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use Try::Tiny;

has 'log',      is => 'rw', isa => 'Object', required => 1;
has 'pass',     is => 'ro', isa => 'Str',    required => 1;
has 'step',     is => 'ro', isa => 'Str',    required => 1;  # 'PRE' / 'POST'
has 'suffix',   is => 'ro', isa => 'Str',    required => 1;
has 'env',      is => 'ro', isa => 'Str',    required => 1;
has 'env_name', is => 'ro', isa => 'Str',    required => 1;

sub initialize {
  my $self     = shift;
  my $log      = $self->log;
  my $prepost  = $self->prepost;
  my $pass     = $self->pass;
  my $suffix   = $self->suffix;
  my $env      = $self->env;
  my $env_name = $self->env_name;
  my $rc  = "";
  my $ret = "";

  my $prepost_timeout = config_get('config.bde')->{prepost_timeout} || 3600;
  my $staunixport     = config_get('config.bde')->{staunixport};
  my $controlmaq      = config_get('config.bde')->{controlmaq};

  my ($cam, $CAM) = get_cam_uc($env_name);
  my %scripts = $self->_script_list($CAM, $env, $suffix, $prepost);
  if (!%scripts) {
    $log->debug("No hay scripts $prepost para esta aplicación ($CAM) definidos en el formulario de paquete.");
    return;
  }
  my $cnt = 0;
  foreach my $key (sort keys %scripts) {
    $cnt++;
    my ($exec, $maq, $usu, $block, $os, $errcode) = @{$scripts{$key}};
    if ($maq eq "") {
      if ($block =~ /^s/i) {
        $log->error("nombre de servidor '$maq' inválido (bloqueo=$block)");
        _throw("Error durante la ejecución de scripts $prepost.");
      }
      else {
        $log->warn("nombre de servidor '$maq' inválido (bloqueo=$block - script descartado)");
        next;
      }
    }

    ##   MODIFICACION PARA ACTIVACION DE SCRIPT PRE-POST PARA WINDOWS POR CONTROL-M
    my $balix = "";
    my ($puerto) = ();

    if ($os !~ /CTRM/i) {
      if ($usu !~ /$CAM/i) {
        if ($block =~ /^s/i) {
          $log->error("Script $prepost $cnt: Nombre de usuario '$usu' no contiene el cam $CAM. Posible brecha de seguridad (bloqueo=$block)");
          _throw("Error durante la ejecución de scripts $prepost.");
        }
        else {
          $log->warn("Script $prepost $cnt: Nombre de usuario '$usu' no contiene el cam $CAM. Posible brecha de seguridad (bloqueo=$block)");
          next;
        }
      }

      $log->debug("maq: $maq");
      my $inf = BaselinerX::Model::InfUtil->new(cam => $CAM);
      ($puerto) = $inf->get_unix_server_info({server => $maq, env => $env, subapl => 'dodo'}, 'balix_PORT');
      $log->debug("port: $puerto");

      if ($puerto eq "") {
        if ($block =~ /^s/i) {
          $log->error("nombre de servidor '$maq' inválido o puerto no encontrado en la lista de servidores de infraestructura (bloqueo=$block)");
          _throw("Error durante la ejecución de scripts $prepost.");
        }
        else {
          $log->warn("nombre de servidor '$maq' inválido o puerto no encontrado en la lista de servidores de infraestructura (bloqueo=$block)");
          next;
        }
      }

      my $resolver = BaselinerX::Ktecho::Inf::Resolver->new({cam     => $CAM,
                                                             entorno => $env,
                                                             sub_apl => 'bleh'});
      $exec = $resolver->get_solved_value($exec);                                                             
      $exec =~ s/\$\{pase\}/$pass/;
      $exec =~ s/\$\{naturaleza\}/$suffix/;
      $exec =~ s/\$\{orden\}/$cnt/;
      $exec =~ s/\$\{block\}/$block/;
      $log->info("Script $prepost $cnt: inicio ejecución $maq:$exec...");

      my $balix_err_msg = sub { _throw "Error al abrir la conexión con agente en $maq:$puerto" };

      #- block Si > 0, Sí > 1
      #- block Sí > 1 gives warning
      #x parsear variables $[]
      #- utilizar los nombres de servidores $[aixsss]
      #- validar en el perl que el servidor y usuario son correctos.
      # $balix = balix->open($maq, $puerto) or $balix_err_msg->();
      $balix = BaselinerX::Comm::Balix->new(host => $maq, port => $puerto, timeout => 10, key => key_from_port($puerto)) or $balix_err_msg->();
    }
    else {
      # Ponemos el puerto de unix , porque nos conectamos a la maquina de control-m que es unix
      $puerto = $staunixport; 
      $maq    = $controlmaq;
      $balix  = balix->open($maq, $puerto) or _throw("Error al abrir la conexión con agente en $maq:$puerto");
    }

    local $SIG{ALRM} = sub { die "Timeout0\n" };

    if ($block =~ /^s/i) {
      local $SIG{ALRM} = sub { die "Timeout0\n" };
      try {
        my ($rc, $ret) = ();
        print "Tiempo máximo de ejecución de script: $prepost_timeout segundos. \n";
        $log->debug("Tiempo máximo de ejecución de script: $prepost_timeout segundos.");

        local $SIG{ALRM} = sub { die "Timeout1\n" };

        eval {
          local $SIG{ALRM} = sub { die "Timeout2\n" };
          alarm $prepost_timeout;
        }
      };

      ################################################################################
      ##############    EJECUCION DEL SCRIPT en WINDOWS o en UNIX    #################
      ################################################################################

      if ($os eq "CTRM") {
        $log->debug("Se invoca a ctmorder con estos parametros: $exec, $balix, $CAM, $env, $block  ");
        $self->ctmorder($exec, $balix, $CAM, $env, $block);

      }
      else {
        my ($rc, $ret) = $balix->executeas($usu, $exec);
        $rc = $rc >> 8;
      }

      alarm 0;

      ## este es el catch
      if ($@) {
        if ($@ =~ m/Timeout/i) {
          print "Se ha producido un error durante la ejecución del script $maq:$exec (RC=$rc, Err>=$errcode): $@\n";
          $log->error("Se ha producido un error durante la ejecución del script $maq:$exec (RC=$rc, Err>=$errcode): $@ ", $ret);
          die;
        }
        else {
          print "2 Se ha producido un error durante la ejecución del script $maq:$exec (RC=$rc, Err>=$errcode): $@\n";
          $log->error("2 Se ha producido un error durante la ejecución del script $maq:$exec (RC=$rc, Err>=$errcode): $@ ", $ret);
          die;
        }
      }
      else {
        alarm 0;
        print "NO Se ha producido un error durante la ejecución del script $maq:$exec (RC=$rc, Err>=$errcode): $@\n";
        $log->debug("NO Se ha producido un error durante la ejecución del script $maq:$exec (RC=$rc, Err>=$errcode): $@ ", $ret);
      }

      if ($rc >= $errcode) {
        if ($block =~ /^s/i) {
          $log->error("Script $prepost $cnt (bloqueo=$block): Error durante la ejecución de $maq:$exec (RC=$rc, Err>=$errcode) ", $ret);
          _throw("Error durante la ejecución de scripts $prepost.");
        }
        else {
          $log->warn("Script $prepost $cnt (bloqueo=$block): Error durante la ejecución de $maq:$exec (RC=$rc, Err>=$errcode)", $ret);
        }
      }
      else {
        if ($errcode > 1) {    ## warning, si es el caso: 1 <= $rc < $errcode
          $log->warn("Script $prepost $cnt $maq:$exec: terminado con warning (RC=$rc, Warn<$errcode).", $ret);
        }
        else {
          $log->info("Script $prepost $cnt $maq:$exec: OK.", $ret);
        }
      }

    }
    catch {
      alarm 0;
      $balix->end();
      _throw("Error durante la ejecución de los scripts: " . shift());
    };
  }
}

sub _script_list {
  my ($self, $cam, $env, $nat, $prepost) = @_;
  my $sql = qq{
    SELECT   TRIM (pp_orden), TRIM (pp_exec), TRIM (pp_maq), TRIM (pp_usu),
             TRIM (pp_block), TRIM (pp_os), TRIM (pp_errcode)
        FROM bde_paquete_prepost
       WHERE TRIM (pp_cam) = TRIM ('$cam')
         AND UPPER (TRIM (pp_env)) = UPPER (TRIM ('$env'))
         AND UPPER (TRIM (pp_prepost)) = '$prepost'
         AND UPPER (TRIM (pp_naturaleza)) = '$nat'
         AND UPPER (pp_activo) = 'S'
    ORDER BY pp_orden    
  };
  my $har = BaselinerX::CA::Harvest::DB->new;
  my @ls = $har->db->array($sql);
  wantarray ? @ls : \@ls;
}

sub _map {
  my ($self, $raw) = @_;
  my %MAP = ();
  my @MAP = split /\|/, $raw;
  my %CNT = ();
  foreach my $map (@MAP) {
    my ($orden, $nat, $exec, $maq, $usu, $block) = split /; */, $map;
    if ($exec) {
      $maq =~ s/^(.*?)\(.*/$1/g;
      my $key = $orden;
      if ($CNT{$orden}) {
        $key = sprintf("%d-%02d", $orden, $CNT{$orden});
      }
      $CNT{$orden} += 1;
      push @{$MAP{$key}}, ($orden, $nat, $exec, $maq, $usu, $block);
    }
  }
  return %MAP;
}

sub ctmorder {
  my ($self, $jobname, $balix, $CAM, $env, $block) = @_;
  my $log = $self->log;
  my $usu = $ENV{STAUNIXUSER};
  if ($env eq 'TEST') { $usu = 'vpscm' }
  $log->debug("El ususario que se va a utilizar es -->$usu<--");
  my $orderidjob = "";
  my $hoy = substr(ahoralog(), 0, 8);
  my ($rc, $ret) = ();
  # Comprobamos de que el job a ejecutar pertenezca al cam del pase y al entorno correcto...
  my $APL = substr($jobname, 0, 3);
  if ($CAM ne uc($APL)) {
    $log->error(" ¡Error el job no pertenece al CAM del pase (</b>$CAM</b>) , corrija el error en el formulario de packages y vuelva a intentarlo! ");
    _throw("Error durante la ejecución de scripts pre-post $jobname");
  }
  if (uc(substr($env, 0, 1)) ne uc(substr($jobname, 3, 1))) {
    $log->error(" ¡Error el job no pertenece al ENTORNO del pase (</b>$env</b>) , corrija el error en el formulario de packages y vuelva a intentarlo! ");
    _throw("Error durante la ejecución de scripts pre-post $jobname");
  }

  # Forzamos el job que nos pasan desde el formulario de packages
  $log->debug("forzando job en controlm $jobname ");
  ($rc, $ret) = $balix->executeas($usu, "ctmorder  -schedtab $env-$CAM  -jobname '$jobname'   \ -odate $hoy  -force y ");
  if ($rc eq 0) {
    my @dirs = split(/\n/, $ret);
    foreach my $linea (@dirs) {
      if ($linea =~ m/orderno/) {
        my $clave = 'orderno';
        my $pos = index($linea, $clave);
        $pos = $pos + 9;
        $orderidjob = substr($linea, $pos, 6);
      }
    }
    $log->debug("El orderID del job FORZADO es ====> $orderidjob <====");
  }
  else {
    if ($block =~ /^s/i) {
      $log->error(" ¡Error al FORZAR el script PRE-POST en CONTROL-M  (bloqueo=$block)", $ret);
      _throw("Error durante la ejecución de scripts pre-post $jobname");
    }
    else {
      $log->warn("¡Error al FORZAR el script PRE-POST en CONTROL-M  (bloqueo=$block) , Continuo con el siguiente ..... o con el pase ", $ret);
      next;
    }
  }

  my $vivo = 1;
  while ($vivo) {    ## mientras el job es vivo sigo preguntando

    ## Con este comando listariamos la situacion  del job en cuestion
    ($rc, $ret) = $balix->executeas($usu, "ctmpsm -LISTJOB EXECUTING");

    if ($rc eq 0) {
      if (($ret =~ /$jobname/)) {
        $log->debug("El job   $jobname   sigue  en  ejecucion ,  espero 30 segundos ............  ");
        sleep 10;    ## lo he encontrado , por lo que sigo en  ejecucion
      }
      else {         ## ya no esta en ejecucion , miramo si esta en not-ok por que hay menos jobs que mirar .
        ($rc, $ret) = $balix->executeas($usu, "ctmpsm -LISTJOB NOTOK ");
        if (($ret =~ /$jobname/)) {    ## ESTA EN NOTOK , POR LO QUE HA CANCELADO  ME PIRO
          sysout_ctm($usu, $orderidjob, $jobname, 'NOT-OK', $balix);
          $vivo = 0;
        }
        else {
          sysout_ctm($usu, $orderidjob, $jobname, 'OK', $balix);
          $vivo = 0;
        }
      }
    }
    else {
      if ($block =~ /^s/i) {
        $log->error("ERROR , no he podido comprobar si el job $jobname esta en ejecucion ... (bloqueo=$block)", $ret);
        _throw("Error durante la ejecución de scripts pre-post $jobname");
        $vivo = 0;
      }
      else {
        $log->warn("ERROR , no he podido comprobar si el job $jobname esta en ejecucion ... (bloqueo=$block) , Continuo con el siguiente ..... o con el pase ", $ret);
        $vivo = 0;
        next;
      }
    }
  }
}

sub sysout_ctm {
  my ($self, $usu, $orderidjob, $jobname, $terminacion, $balix) = @_;
  my $log = $self->log;
  $log->debug(" Recuperando la salida del script PRE-POST");
  my ($rc, $ret) = $balix->executeas($usu, "ctmpsm -LISTSYSOUT  $orderidjob");
  if ($rc eq 0) {
    $log->debug(" El script PRE-POST $jobname ha terminado $terminacion ", $ret);
  }
  else {
    $log->debug("No se ha podido recuperar la salida del job ejecutado en control-m ", $ret);
  }
}

1;
