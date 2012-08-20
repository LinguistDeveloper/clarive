package BaselinerX::J2EE::IAS;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Data::Dumper;
use Try::Tiny;
use feature "switch";

sub ias_batch_build {
  my $self = shift;
  my $log  = shift;
  my %p    = %{shift()};

  my $elements = $p{elements};
  my $dist     = $p{dist};
  my $CAM      = $dist->{CAM};
  my $Entorno  = $dist->{entorno};
  my @proyectos;

  $log->debug('Iniciando IAS-BATCH...');

  my %subapl;

  $log->info("Procesando elementos IAS-BATCH");

  foreach my $vid (keys %{$elements || {}}) {
    my $e = $elements->{$vid};
    if ($e->{ElementPath} =~ m/_BATCH\//i) {
      # my $sa = $1 if $e->{subapl} =~ /(\w+)_BATCH/;
      my $sa = $e->{subapl}; # chapu...
      $subapl{$sa} = $e->{project};

      # Guardo estos datos en el 'stash', para luego...
      $dist->{ias_batch}->{subapls}->{$sa} = $e->{project};
    }
  }
  
  _log "DIST001 :: " . Data::Dumper::Dumper $dist;

  $log->debug("No hay elementos IAS-BATCH") unless scalar keys %subapl;

  my $opt_classpath = classpath_publicas($dist);

  my $exclusiones = ias_batch_exclusiones();
  $log->debug("IAS-BATCH: directorios que ANT excluirá del Jar: $exclusiones");

  foreach my $sa (keys %subapl) {
    my $project = $subapl{$sa};
    $log->info("IAS-BATCH: procesando subapl $sa (proyecto $project)...");

    my $jdk = get_jdk_version_ias_batch($log, $CAM, $Entorno, $sa);
    my $opt_javac = "source=\"$jdk->{version}\"";

    $log->debug("IAS-BATCH parseando workspace $dist->{buildhome}...");

    # Crea el workspace object.
    _log "buildhome: $dist->{buildhome}";
    my $w = BaselinerX::Eclipse::Java->parse(workspace => $dist->{buildhome});

    my $bx = $w->getBuildXML(
      projects   => [$project],
      classpath  => $opt_classpath,
      javac_opts => $opt_javac,
      exclude    => qq{
            <exclude name="**/hardist.xml" />
            <exclude name="**/harvest.sig" />
            <exclude name="**/.*" />
            $exclusiones
      }
    );
    my $buildxml_file = $dist->{buildhome} . "/" . "build_$project.xml";
    _log "buildxml_file: $buildxml_file";

    $log->info("IAS-BATCH build_$project.xml ($buildxml_file)", $bx->data);
    $bx->save($buildxml_file);

    # quita el /config
    my $config = config_package($log,
                                dist    => $dist,
                                project => $project);

    # copia el /lib - no se borra pq tiene que ir a staging
    my $barra_lib = prepara_lib($log,
                                dist    => $dist,
                                project => $project);

    _log "CONFIG001 :: " . Data::Dumper::Dumper $config;
    _log "BARRAL001 :: " . Data::Dumper::Dumper $barra_lib;
    _log "OUTPUT001 :: " . Data::Dumper::Dumper $w->output();

    # build
    my @OUTPUT = $w->output();

    # unless (scalar @OUTPUT % 2 == 0) {
    unless (@OUTPUT) {
      $log->info("No se ha podido detectar la estructura IAS-Batch para la subaplicación $sa (no output)");
      next;
    }

    #logdebug "IAS-BATCH salida esperada para $sa: ", join ',', map { $_->{file} } @OUTPUT;
    $log->debug("IAS-BATCH salida esperada para $sa: ", YAML::Dump(\@OUTPUT));
    buildme($log,
            dist      => $dist,
            subapl    => $sa,
            buildxml  => "build_$project.xml",
            buildfile => $buildxml_file,
            output    => \@OUTPUT);

    push @proyectos, $project;
    $dist->{ias_batch}->{$sa} = {project => $project,
                                 output  => \@OUTPUT,
                                 config  => $config,
                                 lib     => $barra_lib};

    # generar build.xml
    # genBuild( subapl=>$sa, project=>$subapl{$sa}, dist=>$dist );
  }
  _log "IBBZ01 parámetros de salida ias_batch_build :: " . Data::Dumper::Dumper \@proyectos;
  return @proyectos;
}

sub config_package {
  my $log = shift;
  my %p   = @_;
  my $dist    = $p{dist};
  my $project = $p{project};
  my $subapl  = $p{subapl};
  my $dir     = "$dist->{buildhome}/$project/Config";
  my $destdir = File::Spec->canonpath($dist->{buildhome} . "/../" . $project . "Config");
  if (-e $dir) {
    $log->debug("IAS-BATCH: Quitando y empaquetando Directorio de config $dir");
    $log->debug("Move $dir a $destdir", `mv $dir $destdir`);
  }
  else {
    $log->debug("IAS-BATCH: Directorio de config $dir no existe");
  }
  return $destdir;
}

sub ias_batch_exclusiones {
  join "\n", 
       map {qq{    <exclude name="$_" /> }}
           grep {$_} 
                map { s{\n|\r|\t}{}g; s{^ +}{}g; s{ +$}{}g; $_ }
                    split ',', config_get('config.bde')->{ias_batch_exclusiones}
}

sub classpath_publicas {
  my $dist    = shift;
  my $cam     = $dist->{CAM};
  my $pubname = config_get('config.bde')->{pubname};
  my $inf     = BaselinerX::Model::InfUtil->new(cam => $cam);

  # PUBLICAS CON CLASSPATH (NO IAS)
  # version de apl publicas en J2EE_APL_PUB
  my $pubver = $inf->get_inf(undef, [{column_name => 'J2EE_APL_PUB'}]);

#  my @vers      = split /\|/, $pubver;
  my $classpath = '';
  my $staging   = staging_data($dist);
  foreach my $pubv (@{$pubver}) {
    next if ($pubv =~ /^IAS/);    # Ignore publics of IAS.
    $classpath .= "$staging->{home}/$pubname/$pubv;";
  }
  $classpath;
}

sub get_jdk_version_ias_batch {
  my ($log, $cam, $env, $subapl) = @_;
  my $inf = BaselinerX::Model::InfUtil->new(cam => $cam);
  my $jdk_version = $inf->_get_inf_subapl_hash('IASBATCH_JDK', $subapl);

  my $jdk_var  = "\$\{aix_jdk_$jdk_version\}";
  my $resolver =
   BaselinerX::Ktecho::Inf::Resolver->new({entorno => $env,
                                           sub_apl => $subapl,
                                           cam     => $cam});
  my $jdk_path = $resolver->get_solved_value($jdk_var);
  $log->debug("Versión de JDK IAS Batch detectada (CAM $cam, pestaña IAS Batch, subapl: $subapl): $jdk_version (path: $jdk_path)");
  {version => $jdk_version, path => $jdk_path};
}

sub staging_data {
  my $dist = shift;
  my %STA;

  my $inf = BaselinerX::Model::InfUtil->new(cam => $dist->{CAM});
  ($STA{maq}, $STA{puerto}, $STA{home}, $STA{user}) = $inf->get_staging_unix_active();

  _throw "Error de transferencia a Staging. No he encontrado datos de staging en la configuración SCM."
    if (!$STA{maq} or !$STA{puerto} or !$STA{home} or !$STA{user});

  $STA{buildhome} = join '/', $STA{home}, 'pase', $dist->{pase}, $dist->{CAM}, $dist->{sufijo};

  \%STA;
}

sub prepara_lib {
  my $log     = shift;
  my %p       = @_;
  my $dist    = $p{dist};
  my $project = $p{project};
  my $dir     = $dist->{buildhome} . "/" . $project . "/lib";
  my $destdir = File::Spec->canonpath($dist->{buildhome} . "/../" . $project . "lib");
  if (-e $dir) {
    $log->debug("IAS-BATCH: Copiando y empaquetando directorio /lib '$dir'");
    $log->debug("Move $dir => $destdir", `cp -R $dir $destdir`);
  }
  else {
    $log->debug("IAS-BATCH: Directorio /lib '$dir' no existe");
  }
  return $destdir;
}

sub buildme {
  my $log       = shift;
  my %p         = @_;
  my $dist      = $p{dist};
  my $subapl    = $p{subapl};
  my $buildfile = $p{buildfile};
  my $buildxml  = $p{buildxml};
  my $output    = $p{output};

  unless ($output) {
    $log->error("No se ha encontrado output.");
    _throw "No se ha encontrado output.";
  }

  my $Pase            = $dist->{pase};
  my $Entorno         = $dist->{entorno};
  my $CAM             = $dist->{CAM};
  my $buildhome       = $dist->{buildhome};
  my $EnvironmentName = $dist->{envname};
  my $staging         = staging_data($dist);
  my %STA             = %{$staging};

  $buildxml = "$staging->{buildhome}/${buildxml}";
  my $param = "clean build package";

  send_dir($log,
           maq        => $STA{maq},
           puerto     => $STA{puerto},
           user       => $STA{user},
           local_dir  => $buildhome,
           remote_dir => $STA{buildhome},
           prefix     => 'IAS-BATCH',
           tarname    => "${Pase}-$EnvironmentName-IASBATCH");

  my $balix;

  try {
    my $balix = _balix(host => $STA{maq}, port => $STA{puerto});
    my ($RC, $RET);

    ## IAS version from ias-batch.jar
    my $ias_ver = ias_version_publico($log,
                                      pase      => $Pase,
                                      buildhome => $buildhome,
                                      subapl    => $subapl,
                                      fichero   => 'ias-batch.jar',
                                      filter    => qr/_BATCH/,
                                      prefix    => 'IASBatch');

    $log->info("IAS-BATCH: version detectada de IAS en ias-batch.jar: $ias_ver");

    # Reemplaza por la version de PUBLICO
    copy_publico($log,
                 harax     => $balix,
                 pubver    => $ias_ver,
                 home      => $STA{home},
                 buildhome => $STA{buildhome},
                 user      => $STA{user},
                 subapl    => $subapl,
                 folders   => [qw/BATCH/]);

    # ANT
    my $jdk        = get_jdk_version_ias_batch($log, $CAM, $Entorno, $subapl);
    my $jdkPath    = $jdk->{path};
    my $jdkVersion = $jdk->{version};
    $jdkVersion = "1.5" if $jdkVersion =~ m/1\.4/;

    if ((index $jdkPath, "java") > -1) {
      $log->debug("Versión de JDK usada para compilar $subapl: $jdkVersion. Path: $jdkPath");
    }
    else {
      $log->warn("No se pudo resolver el path para la versión de JDK especificada en el formulario: $jdkVersion, o bien su valor no es correcto. Se usará el JDK por defecto en esa máquina.");
      $jdkPath = "";
    }

    my $executeString = qq{ls "$jdkPath"};
    ($RC, $RET) = $balix->executeas($STA{user}, $executeString);

    my $pathChange = "";

    if ($RC eq 0) {
      $pathChange = "PATH=$jdkPath:\\\$PATH ;";
    }
    else {
      $log->warn("El path especificado para buscar el JDK no se encuentra en la máquina de Staging de WAS. Se compila usando el JDK por defecto en esa máquina.");
    }

    # PRECOMP
    $log->info("Esperando semaforo precompilacion IAS...");
    my $sem = Baseliner->model('Semaphores')->request(sem => 'bde.j2ee.ias.precomp', bl => $Entorno, who => $Pase);
    $log->info("ANT compilando y empaquetando $buildxml (espere)...", "ant $param $buildxml");
    $executeString = qq[cd "$STA{buildhome}" ; $pathChange ant $param -buildfile $buildxml 2>&1];
    $sem->release;
    
    _log "\ncmd: $executeString\nhost: $STA{maq}";

    ($RC, $RET) = $balix->executeas($STA{user}, $executeString);
    if ($RC ne 0) {
      $log->error("Ant terminado con error (RC=$RC)" . $RET);
      _throw "Error en la construcción ANT (RC=$RC)" . $RET;
    }
    else { 
      $log->info("Fin de la ejecución ANT (RC=$RC).", $RET); 
    }

    # A recuperar...
    for my $salida (@{$output || []}) {
      my $fichero_remoto = join('/', $STA{buildhome}, $salida->{file});
      my $fichero_local  = join('/', $buildhome,      $salida->{file});
      $log->info("Recupero la salida '$fichero_remoto' a '$fichero_local'. Espere...");
      ($RC, $RET) = $balix->getFile($fichero_remoto, $fichero_local);
      if ($RC ne 0) {
        $log->error("Error al recuperar fichero de staging '$fichero_remoto' ($STA{maq}) a local '$fichero_local' (RC=$RC)", $RET);
        _throw "Error en la recuperación de ficheros de Staging (RC=$RC)";
      }
      else {
        $log->debug(
          "Fin de transferencia: fichero EAR de staging '$fichero_remoto' ($STA{maq}) a local '$fichero_local' (RC=$RC).",
          $RET
        );
      }
    }
    # SQA
#    if (config_get('config.bde')->{sqa_activo}) {
#      sqa_tar(
#        $balix,
#        { rem_dir  => $STA{buildhome},
#          pase_dir => $buildhome . "/../..",
#          subapl   => $subapl,
#          entorno  => $Entorno,
#          cam      => $CAM,
#          pase     => $Pase,
#          nature   => 'JAVABATCH',
#        }
#      );    # if $Dist{tipopase} eq 'N';
#    }
  }
  catch {
    my $err = shift;
    $log->error("IAS-BATCH error durante la compilación", $err);
    _log "Error: $err";
    _throw "Error durante la compilación IAS-BATCH";
  };
  $balix->end if $balix;
}

sub send_dir {
  my $log   = shift;
  my %param = @_;
  my $balix;

  # Load some stuff...
  my $config         = config_get('config.bde');
  my $stawin         = $config->{stawin};
  my $stawinport     = $config->{stawinport};
  my $stawindir      = $config->{stawindir};
  my $stawintarexe   = $config->{stawintarexe};
  my $broker         = $config->{broker};
  my $tardestinosaix = $config->{tardestinosaix};

  my $gnu_tar = config_get('config.bde')->{gnutar};
  my $tarname = $param{tarname} . ".tar";

  if ($param{remote_dir} =~ /^\\\\/) {    # Windows
    # Local TAR (no gzip)
    my $local = File::Spec::Unix->catfile($param{local_dir}, '..', $tarname);
    $log->debug("$param{prefix}: creando el tar $local...");

    $log->debug("me cago en todo");
    my $cmd = qq|cd $param{local_dir} ; $gnu_tar -cvf "$local" *|;
    $log->debug("cmd: $cmd");

    my $RET2 = `$cmd`;
    if ($? eq 0) {
      $log->debug("$param{prefix}: Fichero tar creado con éxito.", $RET2);
    }
    else {
      $log->error("$param{prefix}: Error al crear fichero TAR $local para enviarlo al servidor de staging (RC=$?). Verifique el espacio en disco de $broker:$param{local_dir}", $RET2);
      _throw "Error en la preparación para compilación";
    }

    ## abre conexion
    my ($win_maq, $win_puerto, $win_dir) = ($stawin, $stawinport, $stawindir);
    my $temp_dir = File::Spec::Win32->catfile($win_dir, $param{temp_dir});
    my $remoto = File::Spec::Win32->catfile($temp_dir, $tarname);   # temporal
    $log->info("IAS-BATCH (win): enviando '$local' a $win_maq:$remoto...");

    # my $balix = Harax->open($win_maq, $win_puerto, 'win');
    my $balix = _balix(host => $win_maq, port => $win_puerto, os => 'win');

    ## creo dir de pase
    $log->debug("$param{prefix}: creo dir $win_maq:$temp_dir ...");
    my ($RC, $RET) = $balix->execute(qq{md \"$temp_dir\" });
    _throw "$param{prefix}: error al crear el directorio $win_maq:$temp_dir: $RET"
      if $RC && $RET !~ /exist/i;    # ignora errores de dir ya existe

    ## envío del tar
    $log->debug("$param{prefix}: envio $local a $win_maq:$remoto ...");
    ($RC, $RET) = $balix->sendFile($local, $remoto);
    _throw "$param{prefix}: error al copiar el fichero a $remoto: $RET"
      if $RC;

    ## untar
    $log->debug("$param{prefix}: cd $temp_dir, untar $remoto ...");
    ($RC, $RET) = $balix->execute("cd /D \"$temp_dir\" & $stawintarexe xvf \"$tarname\" & del /Q \"$remoto\"");
    _throw "$param{prefix}: error al expandir fichero $remoto: $RET"
      if $RC;
    _throw "$param{prefix}: error al expandir el fichero a $remoto (exit): $RET"
      if $RET =~ m/Error is not recoverable/s;
    $log->debug("$param{prefix}: resultado del untar (rc=$RC)", $RET);

    # creo el destino por si acaso
    $log->debug("$param{prefix}: mkdir $param{remote_dir} ...");
    ($RC, $RET) = $balix->execute(qq{md $param{remote_dir}});

    ## limpio destino
    ##   del /S /Q $param{remote_dir}
    $log->debug("$param{prefix}: del /S /Q $param{remote_dir} ...");
    ($RC, $RET) = $balix->execute("del /S /Q $param{remote_dir}");
    _throw "$param{prefix}: error al intentar limpiar carpeta $param{remote_dir}: $RET"
      if $RC;

    ## xcopy a destino
    $log->debug("$param{prefix}: xcopy $temp_dir => $param{remote_dir} ...");
    ($RC, $RET) = $balix->execute(
      qq{xcopy /E /Y /S /K /R "$temp_dir\\*.*" "$param{remote_dir}"});    #"
    _throw "$param{prefix}: error al copiar carpeta $temp_dir a $param{remote_dir}: $RET"
      if $RC;
    $log->debug("$param{prefix}: resultado del xcopy (rc=$RC)", $RET);

    unlink $local;
    $balix->end;
  }
  else {    ## es UNIX
    ## TAR LOCAL (con gzip)
    my $local = File::Spec::Unix->catfile($param{local_dir}, '..', $tarname);
    $log->debug("$param{prefix}: creando el tar $local...");
    my $cmd = "cd $param{local_dir} ; $gnu_tar -cvf \"$local\" * ; gzip -f \"$local\"";
    $log->debug("cmd: $cmd");
    my $RET = `$cmd`;
    if ($? eq 0) {
      $log->debug("$param{prefix}: Fichero tar creado con éxito.", $RET);
    }
    else {
      $log->error("$param{prefix}: Error al crear fichero TAR $local para enviarlo al servidor de staging (RC=$?). Verifique el espacio en disco de $broker:$param{local_dir}", $RET);
      _throw "Error en la preparación para compilación";
    }

    try {
      my $remote_tar = join '/', $param{remote_dir}, $tarname;
      # $balix = Harax->open($param{maq}, $param{puerto});
      $balix = _balix(host => $param{maq}, port => $param{puerto});
      my ($RC, $RET);

      # chequeo tar ejecutable
      my $tarExecutable;
      ($RC, $RET) =
        $balix->executeas($param{user}, qq{ ls '$tardestinosaix' });   #'
      if ($RC ne 0)
      {  # No tenemos tar especial en esta máquina, así que nos llevamos uno
        $log->debug("$param{prefix}: Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
        $tarExecutable = "tar";
      }
      else {
        $log->debug("$param{prefix}: Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
        $tarExecutable = $tardestinosaix;
      }

      ## CREO EL DIR remoto
      ($RC, $RET) =
        $balix->executeas($param{user}, "mkdir -p $param{remote_dir}");
      if ($RC ne 0) {
        _throw "Error al crear el directorio remoto $param{maq}:$param{remote_dir}: $RET";
      }
      else {
        $log->debug("$param{prefix}: Directorio de '$param{remote_dir}' creado: $RET");
      }

      ## ENVIO TAR.GZ
      $log->info("$param{prefix}: Enviando directorio al servidor $param{maq}. Espere...");
      ($RC, $RET) = $balix->sendFile("${local}.gz", "${remote_tar}.gz");
      if ($RC ne 0) {
        _throw "$param{prefix}: Error al enviar fichero tar ${remote_tar}: $RET";
      }
      else {
        $log->debug("$param{prefix}: Fichero '${remote_tar}' creado en $param{maq} : $RET");
      }

      ## CAMBIO DE PERMISOS Y OWNER
      ($RC, $RET) = $balix->execute(
        qq{chown $param{user} "${remote_tar}.gz" ; chmod 750 "${remote_tar}.gz"}
      );
      if ($RC ne 0) {
        _throw "$param{prefix}: Error al cambiar permisos del fichero ${remote_tar}.gz: $RET";
      }
      else {
        $log->debug("$param{prefix}: Fichero '${remote_tar}'.gz con permisos para '$param{user}': $RET");
      }

      ## DESCOMPRIME Y BORRA TEMPORAL
      ($RC, $RET) = $balix->executeas($param{user},
        qq{cd $param{remote_dir} ; rm -f "${remote_tar}"; gzip -f -d "${remote_tar}.gz" ; $tarExecutable xvf "${remote_tar}"; rm -f "${remote_tar}"}
      );
      if (($RC ne 0) or ($RET =~ m/unexpected/i) or ($RET =~ m/no space/i)) {
        _throw "$param{prefix}: Error al descomprimir ${remote_tar}.gz (¿Falta espacio  en el servidor destino  $param{maq}?): $RET";
      }
      else {
        $log->debug("$param{prefix}: Fichero '${remote_tar}'.gz descomprimido: $RET");
      }

      ## CAMBIA PERMISOS
      if ($param{mask} && $param{mask} !~ /hered/i) {
        $log->debug("$param{prefix}: cambio permisos a $param{mask}...");
        ($RC, $RET) = $balix->executeas($param{user}, qq{chmod -R $param{mask} $param{remote_dir} });
        _throw "$param{prefix}: error al cambiar permisos $param{mask} de la ruta $param{remote_dir}: $RET"
          if $RC;
      }
      unlink "${local}.gz";

    }
    catch {
      my $err = shift;
      $log->error("$param{prefix}: error durante el envio del directorio $param{local_dir}", $err);
      _throw "$param{prefix}: Error durante la preparación de $param{prefix}";
    };
    $balix->end if $balix;
  }
}

sub copy_publico {
  # A veces se le llama desde otro sitio y recibe self... hacemos trampa.
  my $log = _package eq $_[0] ? do {shift @_; shift @_} : shift @_; # It crashes without the '@_' ?!?!?!
  my %p = @_;
  _log "copy_publico params :: " . Data::Dumper::Dumper \%p; # XXX
  my $pubver = $p{pubver};
  $p{pubname} ||= config_get('config.bde')->{pubname};
  _log "pubname: $p{pubname}";
  $p{home}        or _throw "Missing parameter home";
  _log "home: $p{home}";
  $p{buildhome}   or _throw "Missing parameter buildhome";
  _log "buildhome: $p{buildhome}";
  ref $p{folders} or _throw "Missing parameter folders";
  my $subapl = $p{subapl} or _throw "Missing parameter subapl";
  $log->warn("No hay versión de elementos publicos disponible", return)
    unless $pubver;

  # Esto es donde está la parte publica de esta apl:
  $p{pubhome} ||= "$p{home}/$p{pubname}/$pubver";    

  my ($RETALL, $RCALL, $RC, $RET) = ();

  for my $dir (@{$p{folders}}) {
    ($RC, $RET) = $p{harax}->executeas($p{user},
      qq#for i in $p{buildhome}/${subapl}*$dir ; do cp -Rf $p{pubhome}/$dir/. \\\$i ; if [ \\\$? != 0 ] ; then exit 99 ; fi ; echo "Copiado $p{pubhome}/$dir/. a \\\$i "; done#
    );    ##'"
    $RCALL += $RC;
    $RETALL .= $RET . "\n";    ##'"
  }
  if ($RCALL ne 0) {
    if ($RC eq 256) {
      $log->warn("Directorio no encontrado durante la copia de elementos publicos de '$pubver'. Algún directorio de la aplicación pública de la $pubver no existe. (RC=$RCALL)", $RETALL);
    }
    else {
      $log->error("Error durante la copia de elementos publicos de '$pubver' (RC=$RCALL)", $RETALL);
      _throw "Error en la preparación de las aplicación Publica '$pubver' (RC=$RCALL)";
    }
  }
  else {
    $log->info("Subaplicación $subapl sobreescrita con elementos públicos de '$pubver' (RC=$RCALL).", $RETALL);
  }
}

sub ias_version_publico {
  # A veces se le llama desde otro sitio y recibe self... hacemos trampa.
  my $log = _package eq $_[0] ? do {shift @_; shift @_} : shift @_; # It crashes without the '@_' ?!?!?!
  my %p = @_;
  _log "ias_version_publico params :: " . Data::Dumper::Dumper \%p;  # XXX
  my $env_temp = _bde_conf 'temp';

  my ($Pase, $buildhome, $subapl, $jarfile) =
    ($p{pase}, $p{buildhome}, $p{subapl}, $p{fichero});

  $p{prefix} ||= 'IAS';
  my $iasversion = "";
  $jarfile ||= 'ias.jar';

  # Busca ias.jar: El sort asegura que las subapl más cortas vengan primero
  # que las largas, para evitar que se lea el ias.jar de otra subapl
  my $cmd = qq{find "$buildhome" -name "$jarfile" | sort -f | grep "/$subapl"};
  $log->debug("cmd: $cmd");
  my @RET = `$cmd`; 

  # Con "/$subapl\\(_*EAR\\)" también filtra, pero es más restrictivo; si hace
  # falta se utilizará.
  return "" unless @RET;

  # lo abre en temporal, sacando versionXXXX.xml
  my $tmpdir = $env_temp . "/${Pase}.tmp/";
  $log->debug("$jarfile encontrado: " . join(",", @RET));
  mkdir $tmpdir;
  chdir $tmpdir;
  @RET = grep { $_ =~ $p{filter} } @RET if $p{filter};

  for my $iasjar (@RET) {
    chomp $iasjar;
    my $cmd = qq{ jar tf "$iasjar" 2>/dev/null | grep VERSION-RUNTIME | grep xml };
    _log "cmd: $cmd";
    my ($VERXML) = `$cmd`;
    chomp $VERXML;
    _log ">> $VERXML";
    if ($VERXML) {
      $log->debug("IAS: inspeccionando '$iasjar':", `jar xvf "$iasjar" '$VERXML' 2>/dev/null`);
      open FXML, "<$VERXML"
        or die "Error al abrir fichero de versión de IAS: $VERXML";
      while (<FXML>) {
        if (/<version>(.*)<\/version>/) {
          $iasversion = $1;    # bingo!
          if ($iasversion) {
            $log->info("IAS: versión de arquitectura de ejecución IAS detectada en $jarfile: $iasversion");
            my $VERSIONIAS = $p{prefix} . "-$iasversion";
            $log->debug(" Comprobando version Publica $VERSIONIAS  Espere ..... ");
            my @EstadoVerPubIAS = BaselinerX::Model::InfUtil->obsolete_public_version($VERSIONIAS);
            my $ESTADO          = "";
            foreach $ESTADO (@EstadoVerPubIAS) {
              if ($ESTADO eq "Obsoleto") {
                $log->warn("La version publica  $VERSIONIAS que SE ESTA UTILIZANDO esta OBSOLETA, por favor, actualice la aplicación");
              }
              elsif ($ESTADO eq "Borrado") {
                $log->warn("La versión pública $VERSIONIAS ha sido borrada por los responsables de la aplicación, si su pase hace uso de esta versión fallará el pase");
                $log->warn("Si necesita utilizar la versión pública $VERSIONIAS, por favor pongase en contacto con los Responsables de la aplicación");
              }
            }
            return $p{prefix} . "-$iasversion";
          }
          else {
            $log->warn("IAS: fichero $VERXML no contiene la versión entre las etiquetas <version>...</version>");
          }
        }
      }
      $log->warn("No he encontrado la etiqueta <version>....</version> dentro del fichero $VERXML");
      close FXML;
    }
    else {
      $log->warn("Fichero $iasjar no contiene xml de versión de tipo VERSIONxxxxxx.xml.");
    }
  }
  if ((-d $tmpdir) && ($tmpdir ne "")) {
    chdir '..';
    `rm -Rf '$tmpdir'`;
  }
  $log->warn("IAS: no he localizado la versión de IAS en $jarfile. Uso de librerías públicas de IAS descartado")
    unless $iasversion;

  undef;
}

sub ias_batch_dist
{
    my $self = shift;
    _log "IAS-BATCH-DIST - Entrando en ias_batch_dist...";
    my ($log, $hashref) = @_;
    my %p = %{$hashref};

    # parametros recibidos
    my $dist      = $p{dist};
    my $proyectos = $p{proyectos};

    _log "IAS-BATCH-DIST - dist :: " . Data::Dumper::Dumper $dist;
    _log "IAS-BATCH-DIST - proyectos :: " . Data::Dumper::Dumper $proyectos;

    my $CAM             = $dist->{CAM};
    my $Pase            = $dist->{pase};
    my $EnvironmentName = $dist->{envname};
    my $env             = $dist->{entorno};
    my $TipoPase        = $dist->{tipopase};
    my $red             = $dist->{red} || 'LN';    #TODO es un campo en la pestaña SCM?

    my @subapls = keys %{$dist->{ias_batch}->{subapls} || {}};

    _log "IAS-BATCH-DIST - subapls :: " . Data::Dumper::Dumper \@subapls;

    # preparo la máquina intermedia para Windows
    my ($win_maq, $win_puerto, $win_dir) = (_bde_conf('stawin'), _bde_conf('stawinport'), _bde_conf('stawindir'));


    _log "IAS-BATCH-DIST - win_maq    :: $win_maq";
    _log "IAS-BATCH-DIST - win_puerto :: $win_puerto";
    _log "IAS-BATCH-DIST - win_dir    :: $win_dir";

    # para cada subaplicacion con generados
    foreach my $sa (@subapls)
    {
        # recuperar información de despliegue pestaña SCM
        my %dest = get_inf_ias_batch($log, $CAM, $env, $red, $sa);

        _log "IAS-BATCH-DIST - dest ($sa) :: " . Data::Dumper::Dumper \%dest;

        my $dat = $dist->{ias_batch}->{$sa};
        $log->info("IAS-BATCH: iniciando despliegue de <b>$sa</b>", YAML::Dump($dat));

        #my $project = $p{project}; # pej: zzz_BATCH

        $log->debug("IAS-BATCH: datos de infraestructura para $sa ($CAM,$env,$red)", YAML::Dump(\%dest));

        _log "IAS-BATCH-DIST - entrando en bucle salida...";

        # para cada salida de la subapl...
        for my $salida (@{$dat->{output} || []})
        {
            my $output = $salida->{file};
            _log "IAS-BATCH-DIST - output (dentro del bucle) :: $output";
            my $local = File::Spec::Unix->catfile($dist->{buildhome}, $output);
            _log "IAS-BATCH-DIST - local (dentro del bucle) :: $local";

            $log->info($dist->{buildhome},($output, "IAS-Batch: JAR generado para subaplicación $sa, $output."));
            ## UNIX: my ($viewpath,$toFile,$dest,$maq,$usu,$grp,$mask)=@{ $loc };
            my $fichero = "$sa.jar";    #Path::Class::file( $output )->basename;
            $log->debug("Proceso salida '$output' a para la subaplicación <b>$sa</b>...");

            my $backupNeeded = 1;       ##BACKUP solo en el primer destino

            ## UNIX
            foreach my $unix (@{$dest{unix} || []})
            {
                my $remoto          = File::Spec::Unix->catfile($unix->{path}, $fichero);    # final destination
                my $maquinaIASBatch = $unix->{maq};
                my $puertoIASBatch  = $unix->{puerto};
                my $pathIASBatch    = $unix->{path};
                my $userIASBatch    = $unix->{usu};

                ##BACKUP
                if (($TipoPase ne "B") and ($backupNeeded))
                {
                    # my ($sigoSinBackup) = getInf($CAM, "scm_seguir_sin_backup");             
                    # false, da igual y sigo; true, pase se interrumpe si no tiene backup
                    my $inf = BaselinerX::Model::InfUtil->new(cam => $CAM);
                    my $sigoSinBackup = $inf->get_inf(undef, [{column_name => 'scm_seguir_sin_backup'}]);

                    try
                    {
                        backup_ias_batch($log, $EnvironmentName, $env, 'IAS-Batch', $Pase, $dist->{buildhome}, $sa, $maquinaIASBatch, $puertoIASBatch, $pathIASBatch, $userIASBatch);
                        $backupNeeded = 0;
                    }
                    catch
                    {
                        if ($sigoSinBackup =~ m/N/i)
                        {                                                                    ##ups, tengo que parar el pase
                            _throw "Pase terminado por no poder generar el backup: " . shift();
                        }
                        else
                        {
                            $log->warn("Aviso: No he podido generar el backup de la aplicación actualmente desplegada: " . shift());
                        }
                    };
                }

                # my $harax = Harax->open($maquinaIASBatch, $puertoIASBatch);
                my $harax = _balix(host => $maquinaIASBatch, port => $puertoIASBatch);
                $log->info("IAS-BATCH (unix): enviando '$local' a $unix->{maq}:$remoto");
                if ($unix->{mask} =~ /heredar/i)
                {    # modo herencia de permisos?
                        # envio
                    my $tmp_remoto = File::Spec::Unix->catfile("/tmp", $fichero . '-' . ahoralog());
                    $log->debug("IAS-BATCH: modo herencia de permisos, envío a temporal $tmp_remoto");
                    my ($RC, $RET) = $harax->sendFile($local, $tmp_remoto);
                    _throw "IAS-BATCH: Error al enviar el fichero $tmp_remoto $RET" if $RC;

                    # propietario
                    ($RC, $RET) = $harax->execute(qq{chown $unix->{usu}:$unix->{grp} $tmp_remoto});
                    _throw "IAS-BATCH: Error al cambiar permisos a $unix->{usu}:$unix->{grp} del fichero $tmp_remoto: $RET" if $RC;

                    # copia para que pille los permisos - mejor que restar del umask
                    ($RC, $RET) = $harax->executeas($unix->{usu}, qq{cp $tmp_remoto $remoto});
                    _throw "IAS-BATCH: Error al copiar el fichero '$tmp_remoto' a '$remoto': $RET" if $RC;

                    # borrado del temporal
                    ($RC, $RET) = $harax->execute(qq{rm $tmp_remoto});
                    _throw "IAS-BATCH: Error al borra el fichero '$tmp_remoto': $RET" if $RC;
                }
                else
                {
                    $log->debug("IAS-BATCH: modo permisos con máscara $unix->{mask} de $remoto");

                    # envio
                    my ($RC, $RET) = $harax->sendFile($local, $remoto);
                    _throw "IAS-BATCH: Error al enviar el fichero $local: $RET" if $RC;

                    # propietario
                    ($RC, $RET) = $harax->execute(qq{chown $unix->{usu}:$unix->{grp} $remoto});
                    _throw "IAS-BATCH: Error al cambiar permisos a $unix->{usu}:$unix->{grp} del fichero $local: $RET" if $RC;

                    # mascara
                    ($RC, $RET) = $harax->execute(qq{chmod $unix->{mask} $remoto});
                    _throw "IAS-BATCH: Error al cambiar permisos a $unix->{usu}:$unix->{grp} del fichero $local: $RET" if $RC;
                }
                $harax->end;
            }

            ## WINDOWS
            foreach my $win (@{$dest{win} || []})
            {
                my $remoto = File::Spec::Win32->catfile($win->{path}, $fichero);    # final destination
                $log->info("IAS-BATCH (win): enviando '$local' a '$remoto'");
                # my $harax = Harax->open($win_maq, $win_puerto, 'win');
                my $harax = _balix(host => $win_maq, port => $win_puerto);

                # borro tar remoto por si acaso
                my ($RC, $RET) = $harax->execute(qq{del /Q $remoto});
                $log->debug("IAS-BATCH (win): borrado el fichero $remoto ($RC): $RET");

                # envío
                ($RC, $RET) = $harax->sendFile($local, $remoto);
                _throw "IAS-BATCH (win): error al copiar el fichero a $remoto: $RET" if $RC;
                $harax->end;
            }
        }

        # desplegar directorio /lib
        if (my $lib_dir = $dat->{lib})
        {

            ## UNIX LIB
            foreach my $unix (@{$dest{unix} || []})
            {
                my $remote_dir = File::Spec::Unix->catfile($unix->{path}, 'lib');

                # send unix /lib
                send_dir($log,
                         maq        => $unix->{maq},
                         puerto     => $unix->{puerto},
                         user       => $unix->{usu},
                         local_dir  => $lib_dir,
                         remote_dir => $remote_dir,
                         prefix     => 'IAS-BATCH (unix)',
                         tarname    => "${Pase}-$EnvironmentName-IASBATCH-Lib-unix");
            }

            ## WINDOWS LIB
            foreach my $win (@{$dest{win} || []})
            {
                my $remote_dir = File::Spec::Win32->catfile($win->{path}, 'lib');
                send_dir($log,
                         local_dir  => $lib_dir,
                         remote_dir => $remote_dir,
                         temp_dir   => File::Spec::Win32->catfile($Pase, $EnvironmentName, 'IAS-BATCH'),
                         prefix     => 'IAS-BATCH (win)',
                         tarname    => "${Pase}-$EnvironmentName-IASBATCH-Lib-win");
            }
        }

        # desplegar config
        if (my $config_dir = $dat->{config})
        {
            $log->info("IAS-BATCH ($sa): desplegando config $config_dir");

            log_publish_dir_as_tar($log,
                                   dir      => $config_dir,
                                   msg      => "tar de config para la subapl $sa",
                                   tar_dir  => $dist->{buildhome},
                                   tar_name => "$Pase-$sa-config.tar");

            ## UNIX CONFIG
            foreach my $unix (@{$dest{unix_config} || []})
            {
                # send unix config
                send_dir($log,
                         maq        => $unix->{maq},
                         puerto     => $unix->{puerto},
                         user       => $unix->{usu},
                         local_dir  => $config_dir,
                         remote_dir => $unix->{path},
                         prefix     => 'IAS-BATCH (unix)',
                         tarname    => "${Pase}-$EnvironmentName-IASBATCH-Config-unix");
            }

            ## WINDOWS
            foreach my $win (@{$dest{win_config} || []})
            {
                send_dir($log,
                         local_dir  => $config_dir,
                         remote_dir => $win->{path},
                         temp_dir   => File::Spec::Win32->catfile($Pase, $EnvironmentName, 'IAS-BATCH'),
                         prefix     => 'IAS-BATCH (win)',
                         tarname    => "${Pase}-$EnvironmentName-IASBATCH-Config-win");
            }

        }
        else
        {
            $log->debug("IAS-BATCH ($sa): no hay config para esta subaplicación");
        }
    }
}

sub get_inf_ias_batch
{
  my $log = shift;
  my ($CAM, $env, $red, $subapl) = @_;

  # Si no es I W G posiblemente sea LN, W3, etc.
  $red = net_r7_r12 $red;
  $env = uc substr $env, 0, 1;

  _log "get_inf_ias_batch - red    :: $red";
  _log "get_inf_ias_batch - env    :: $env";
  _log "get_inf_ias_batch - cam    :: $CAM";
  _log "get_inf_ias_batch - subapl :: $subapl";

  my $inf = BaselinerX::Model::InfUtil->new(cam => $CAM);
  my $resolver = BaselinerX::Ktecho::Inf::Resolver->new({entorno => $env,
                                                         sub_apl => $subapl,
                                                         cam     => $CAM});
  my @datos = map { $resolver->get_solved_value($_) || undef }
              map { scalar @{$_} ? $_->[0] : '' } 
                  ($inf->get_inf(undef,
                                [{column_name => 'IASBATCH_UNIX',
                                  idred       => $red,
                                  ident       => $env}]),
                  $inf->get_inf(undef,
                                [{column_name => 'IASBATCH_UNIX_CONFIG',
                                  idred       => $red,
                                  ident       => $env}]),
                  $inf->get_inf(undef,
                                [{column_name => 'IASBATCH_WIN',
                                  idred       => $red,
                                  ident       => $env}]),
                  $inf->get_inf(undef,
                                [{column_name => 'IASBATCH_WIN_CONFIG',
                                  idred       => $red,
                                  ident       => $env}]));

  _log "get_inf_ias_batch - datos :: " . Data::Dumper::Dumper \@datos;

  my @datos_sin_subapl;

  # filtro datos por subapl
  foreach my $field (@datos) {
    my @map;
    foreach my $sa (split('\|', $field)) {
      my @a = split(';', $sa);
      next unless $a[0] eq $subapl;

      # quito el nombre de subapl de la fila
      my ($path, $maq, $usu, $grp, $mask) = @a[1 .. $#a];
      $maq =~ s{^(.*)\(.*\)$}{$1}g;

      # my ($puerto) = getUnixServerInfo($maq, "HARAX_PORT");
      my $puerto = $inf->get_unix_server_info({env    => $env,
                                               server => $maq},
                                              qw/HARAX_PORT/);
      _log "puerto detectado en get_inf_ias_batch :: $puerto";

      push @map,
        {path   => $path,
         maq    => $maq,
         usu    => $usu,
         grp    => $grp,
         mask   => $mask,
         puerto => $puerto};
    }
    push @datos_sin_subapl, \@map;
  }
  my %res;
  @res{'unix', 'unix_config', 'win', 'win_config'} = @datos_sin_subapl;
  _log "salida de datos en get_inf_ias_batch :: " . Data::Dumper::Dumper \%res;
  return %res;
}

sub backup_ias_batch {
  my $log = shift;
  my ($EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subapl, $maquinaIASBatch, $puertoIASBatch, $pathIASBatch, $userIASBatch) = @_;
  my $tardestinosaix = _bde_conf 'tardestinosaix';

  my $localdir = "$PaseDir/backup";
  mkdir $localdir;
  my $retCode = 0;

  ##se conecta a la máquina destino (o la de staging windows) con harax
  try {
    _log "backup_ias_batch - instanciando harax para host: $maquinaIASBatch port: $puertoIASBatch";
    my $harax = _balix(host => $maquinaIASBatch, port => $puertoIASBatch);

    ## GESTIONAMOS LA VARIABLE DEL TAR A UTILIZAR
    my $tarExecutable;
    my $cmd = qq{ ls '$tardestinosaix' };
    _log "backup_ias_batch - ejecutando $cmd como $userIASBatch";
    my ($RC, $RET) = $harax->executeas($userIASBatch, qq{ ls '$tardestinosaix' });
    if ($RC ne 0) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
      $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
      $tarExecutable = "tar";
    }
    else {
      $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
      $tarExecutable = $tardestinosaix;
    }

    #############################################################################################
    #### TRAEMOS EL JAR
    #############################################################################################
    my $filenameLocal  = "${subapl}.jar";
    my $filenameRemote = "${subapl}.jar";
    my $localfile      = "$localdir/$filenameLocal";
    my $remotefile     = "$pathIASBatch/$filenameRemote";

    $log->info("Backup: guardando información IAS-Batch(.jar) - $filenameRemote ...");
    ##recupero el jar
    $log->debug("getFile $remotefile  -  $localfile");
    ($RC, $RET) = $harax->getFile($remotefile, $localfile);
    _log "\nrc:  $RC\nret: $RET";
    if ($RC ne 0) {
      $log->warn("Backup: error durante la transmisión del JAR $maquinaIASBatch:$filenameRemote.", $RET);
      $retCode++;
    }
    ##guardo el jar en la tabla
    _log "backup_ias_batch - guardando el jar en la tabla...";
    my ($idbak, $sizebak) = store_backup($EnvironmentName, $Entorno, $subapl, $Sufijo, $Pase, "JAR", $localfile);
    _log "backup_ias_batch - jar guardado";
    $log->info("Backup:(fichero de backup IAS-Batch(.jar) almacenado correctamente ($filenameRemote contiene <b>${sizebak} kb</b>)", $idbak);

    #############################################################################################
    #### TRAEMOS EL DIRECTORIO LIB
    #############################################################################################
    _log "Traemos el directorio lib...";
    my $filename = "${subapl}_Lib_backup.tar";
    _log "filename: $filename";
    $localfile = "$localdir/$filename";
    _log "localfile: $localfile";
    my $remfile = "/tmp/$filename";
    _log "remfile: $remfile";
    $log->info("Backup: guardando información de $pathIASBatch/lib (IASBatch-Lib)...");

    ## Generamos tar del directorio
    $cmd = "cd $pathIASBatch/lib ; $tarExecutable cvf $remfile *";
    _log "\n\n\nEjecutando: \n$cmd\n\nas: $userIASBatch\n\n";
    ($RC, $RET) = $harax->executeas($userIASBatch, "cd $pathIASBatch/lib ; $tarExecutable cvf $remfile *");
    if ($RC ne 0) {
      $log->warn("Backup: error al recuperar el directorio de Lib '$pathIASBatch/lib'.", $RET);
      _log "RET: $RET";
      $retCode++;
    }
    ##recupero el TAR
    _log "Recuperando el tar...";
    ($RC, $RET) = $harax->getFile($remfile, $localfile);
    if ($RC ne 0) {
      $log->warn("Backup: error durante la transmisión del fichero TAR $maquinaIASBatch:$remfile.", $RET);
      _log "RET: $RET";
      $retCode++;
      _log "retCode: $retCode";
    }

    ##borro el fichero remoto
    _log "borrando el fichero remoto...";
    ($RC, $RET) = $harax->execute("rm -f '$remfile'");
    ##guardo el ear en la tabla
    _log "guardando ear en la tabla";
    ($idbak, $sizebak) = store_backup($EnvironmentName, $Entorno, $subapl, $Sufijo, $Pase, "LIB", $localfile);
    $log->info("Backup:(fichero de backup Lib almacenado correctamente ($filename contiene <b>${sizebak} kb</b>)", $idbak);

    #############################################################################################
    #### TRAEMOS EL DIRECTORIO CONFIG
    #############################################################################################
    _log "Traemos el directorio config...";
    $filename  = "${subapl}_Config_backup.tar";
    _log "filename: $filename";
    $localfile = "$localdir/$filename";
    _log "localfile: $localfile";
    $remfile   = "/tmp/$filename";
    _log "remfile: $remfile";
    $log->info("Backup: guardando información de $pathIASBatch/configBatch (IASBatch-Config)...");

    ## Generamos tar del directorio
    _log "generando tar del directorio...";
    $cmd = "cd $pathIASBatch/configBatch ; $tarExecutable cvf $remfile *";
    _log "cmd: $cmd";
    _log "executeas: $userIASBatch";
    ($RC, $RET) = $harax->executeas($userIASBatch, "cd $pathIASBatch/configBatch ; $tarExecutable cvf $remfile *");
    if ($RC ne 0) {
      $log->warn("Backup: error al recuperar el directorio de Config '$pathIASBatch/configBatch'.", $RET);
      _log "RET: $RET";
      _log "incrementando retcode...";
      $retCode++;
      _log "retCode: $retCode";
    }
    ##recupero el TAR
    _log "recuperando tar...";
    ($RC, $RET) = $harax->getFile($remfile, $localfile);
    if ($RC ne 0) {
      $log->warn("Backup: error durante la transmisión del fichero TAR $maquinaIASBatch:$remfile.", $RET);
      _log "RET: $RET";
      $retCode++;
      _log "retCode: $retCode";
    }

    ##borro el fichero remoto
    _log "borrando fichero remoto";
    ($RC, $RET) = $harax->execute("rm -f '$remfile'");
    ##guardo el ear en la tabla
    _log "guardando ear en la tabla";
    ($idbak, $sizebak) = store_backup($EnvironmentName, $Entorno, $subapl, $Sufijo, $Pase, "CONFIG", $localfile);
    $log->info("Backup:(fichero de backup Config almacenado correctamente ($filename contiene <b>${sizebak} kb</b>)", $idbak);

    $harax->end;
  }
  catch {
    _throw "Error durante el backup: " . shift();
  };
  if ($retCode ne 0) {
    _throw "Error(es) durante el backup IAS-Batch (retcode=$retCode).";
  }
}

######################################################################################################
## 	RESTORE
######################################################################################################
sub restore_ias_batch {
  my $log = shift;
  my ($EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subapl) = @_;
  my ($cam, $CAM) = get_cam_uc($EnvironmentName);
  my $localdir = $PaseDir . "/restore";
  mkdir $localdir;
  my %BACKUPS = getBackups($EnvironmentName, $Entorno, $Sufijo, $localdir, $subapl);
  $log->debug("Backups encontrados para '$EnvironmentName', '$Entorno', '$Sufijo', '$subapl'", Dump(%BACKUPS));
  my $cnt = 0;

  if (keys %BACKUPS eq 0) {
    _throw "Restore: no hay backups disponibles para marcha atrás en la aplicación $EnvironmentName->$Entorno";
  }

  my $red = 'I';
  my %dest = get_inf_ias_batch($log, $CAM, $Entorno, $red, $subapl);

  ##bucleamos cada fichero de backup de este CAM
  foreach my $localfilename (keys %BACKUPS) {
    $cnt++;
    my ($bakPase, $localfile, $tipo, $rootPath, $subapl) = @{$BACKUPS{$localfilename}};

    if ($localfile && -e $localfile) {

      if ($tipo eq "JAR") {
        $log->info("Restore $cnt: localizado JAR IASBatch de backup '$localfilename' (generado por el pase $bakPase)");

        ##RESTORE
        try {
          ## UNIX
          foreach my $unix (@{$dest{unix} || []}) {
            my $maquinaIASBatch = $unix->{maq};
            my $puertoIASBatch  = $unix->{puerto};
            my $pathIASBatch    = $unix->{path} . '/' . $localfilename;
            my $userIASBatch    = $unix->{usu};

            $log->info("Restore: desplegando fichero JAR de backup en <b>$maquinaIASBatch</b>. Espere...");

            # my $harax = Harax->open($maquinaIASBatch, $puertoIASBatch);
            my $harax = _balix(host => $maquinaIASBatch, port => $puertoIASBatch);

            $log->debug("Restore $cnt: transferencia del fichero local '$localfile' a remoto '$maquinaIASBatch:$puertoIASBatch - $pathIASBatch'");
            my ($RC, $RET) = $harax->sendFile($localfile, $pathIASBatch);
            if ($RC ne 0) {
              my $stttrrr = "Restore $cnt: error durante la transmisión del fichero JAR.";
              $log->error($stttrrr, $RET);
              _throw $stttrrr;
            }

            $log->info("Restore $cnt Despliegue OK: fichero de restore desplegado correctamente.", $RET);

            $harax->end();
          }

          ##enseño el jar desplegado al usuario en el log
          $log->info($localdir,($localfilename, "Restore $cnt: fichero JAR recuperado."));

        }
        catch {
          _throw "Restore: error durante la marcha atrás del JAR: " . shift();
        };

      }
      elsif ($tipo eq "LIB") {
        $log->info("Restore $cnt: identificado directorio de Lib '$localfilename' (generado por el pase $bakPase)");
        try {
          ## UNIX
          foreach my $unix (@{$dest{unix} || []}) {
            my $maquinaIASBatch     = $unix->{maq};
            my $puertoIASBatch      = $unix->{puerto};
            my $pathIASBatchLib     = $unix->{path} . '/lib';
            my $pathIASBatchLibFile = $unix->{path} . '/lib/' . $localfilename;
            my $userIASBatch        = $unix->{usu};

            $log->info("Restore: desplegando directorio de Lib en <b>$maquinaIASBatch</b>. Espere...");

            # my $harax = Harax->open($maquinaIASBatch, $puertoIASBatch);
            my $harax = _balix(host => $maquinaIASBatch, port => $puertoIASBatch);
            config_dist_ias_batch($log, $harax, 'vpwas', 'gpwas', $localfile, $pathIASBatchLib, $pathIASBatchLibFile);
            $harax->end;
          }

          ##enseño el tar del directorio desplegado al usuario en el log
          $log->info($localdir,($localfilename, "Restore $cnt OK: directorio de $tipo IAS desplegado correctamente."));

        }
        catch {
          _throw "Restore: error durante la marcha atrás del directorio $tipo IAS: " . shift();
        };
      }
      elsif ($tipo eq "CONFIG") {
        $log->info("Restore $cnt: identificado directorio de Config '$localfilename' (generado por el pase $bakPase)");
        try {
          ## UNIX
          foreach my $unix_config (@{$dest{unix_config} || []}) {
            my $maquinaIASBatch        = $unix_config->{maq};
            my $puertoIASBatch         = $unix_config->{puerto};
            my $pathIASBatchConfig     = $unix_config->{path};
            my $pathIASBatchConfigFile = $unix_config->{path} . '/' . $localfilename;
            my $userIASBatch           = $unix_config->{usu};

            $log->info("Restore: desplegando directorio de Config en <b>$maquinaIASBatch</b>. Espere...");

            # my $harax = Harax->open($maquinaIASBatch, $puertoIASBatch);
            my $harax = _balix(host => $maquinaIASBatch, port => $puertoIASBatch);
            config_dist_ias_batch($log, $harax, 'vpwas', 'gpwas', $localfile, $pathIASBatchConfig, $pathIASBatchConfigFile);
            $harax->end;
          }

          ##enseño el tar del directorio desplegado al usuario en el log
          $log->info($localdir,($localfilename, "Restore $cnt OK: directorio de $tipo IAS desplegado correctamente."));

        }
        catch {
          _throw "Restore: error durante la marcha atrás del directorio $tipo IAS: " . shift();
        };

      }
      else {
        $log->warn("Restore $cnt: tipo de backup '$tipo' no contemplado en la marcha atrás (fichero '$localfilename', generado por el pase $bakPase)");
      }

    }
    else {
      ##fichero no existe, señal de que el fichero restore no estaba en DISTBAK
      _throw "Restore: no existe un fichero de backup para $EnvironmentName->$Entorno.";
    }
  }
}

## despliega el fichero TAR del Lib y el Config de IAS-Batch
sub config_dist_ias_batch {
  my $log            = shift;
  my $tardestinosaix = _bde_conf 'tardestinosaix';
  my ($harax, $dest_wasuser, $dest_wasgroup, $localfile, $rempath, $remfile) = @_;
  if ($localfile && $remfile && (-e $localfile)) {
    $log->info("Restaurando directorio: enviando ficheros a '$remfile'. Espere...");
    $log->debug("Restaurando directorio: enviando ficheros de $localfile a '$remfile'. Espere...");

    ## ENVIO TAR
    my ($RC, $RET) = $harax->sendFile($localfile, $remfile);
    if ($RC ne 0) {
      _throw "Error al enviar fichero tar '$localfile' a '$remfile': $RET";
    }
    else {
      $log->debug("Fichero tar de '$remfile' en destino: $RET");
    }

    ## CHMOD TAR
    ($RC, $RET) = $harax->execute("chown $dest_wasuser:$dest_wasgroup '$remfile' ");
    if ($RC ne 0) {
      _throw "Error al cambiar permisos del fichero TAR '$remfile': $RET";
    }
    else {
      $log->debug("Permisos de TAR cambiados: chown $dest_wasuser:$dest_wasgroup '$remfile': $RET");
    }

    ## BORRO /config/*
    ($RC, $RET) = $harax->executeas($dest_wasuser, "rm -Rf '$rempath'/*  ");
    if ($RC ne 0) {
      _throw "Error al limpiar el contenido del directorio en '$rempath': $RET";
    }
    else {
      $log->debug("Directorio vaciado '$remfile': $RET");
    }

    ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
    my $tarExecutable;

    ($RC, $RET) = $harax->executeas($dest_wasuser, qq{ ls '$tardestinosaix' });
    if ($RC ne 0) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
      $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
      $tarExecutable = "tar";
    }
    else {
      $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
      $tarExecutable = $tardestinosaix;
    }

    ## DESCOMPRIMO
    ($RC, $RET) = $harax->executeas($dest_wasuser, "cd '$rempath' ; $tarExecutable xvf '$remfile' ");

    #($RC,$RET) = $harax->execute("cd '$rempath' ; $tarExecutable xvf '$remfile' ");
    if ($RC ne 0) {
      _throw "Error al descomprimir directorio en '$remfile': $RET";
    }
    else {
      $log->debug("Directorio descomprimido en '$remfile': $RET");
    }

    ## CHOWN
    ($RC, $RET) = $harax->execute("chown -R $dest_wasuser:$dest_wasgroup '$rempath'/* ");
    if ($RC ne 0) {
      _throw "Error al cambiar permisos a <b>$dest_wasuser:$dest_wasgroup</b> en '$rempath': $RET";
    }
    else {
      $log->debug("Permisos cambiados a $dest_wasuser:$dest_wasgroup en '$rempath': $RET");
    }

    ## BORRO FICHERO TMP
    $harax->execute("rm -f '$remfile'");
  }
  else {
    $log->err("Falta algún parámetro al tratar de restaurar el directorio: $harax - $dest_wasuser - $dest_wasgroup - $localfile - $remfile");
  }
}

sub log_publish_dir_as_tar {
  my $log    = shift;
  my %p      = @_;
  my $gnutar = _bde_conf 'gnutar';
  $p{dir} or _throw "Error: log_publish_dir_as_tar: falta el parámetro 'dir'";
  # $p{tar_dir} ||= getcwd;
  $p{tar_dir} or _throw "No tengo tar_dir en log_publish_dir_as_tar";
  $p{msg} ||= "tar de '$p{dir}'";
  my $tar_filename = $p{tar_name} || ahora() . ".tar";
  my $tar_path = File::Spec->catfile($p{tar_dir}, $tar_filename);
  my $ret = `cd $p{dir} ; $gnutar -cvf "$tar_path" * ; gzip -f "$tar_path"`;
  if ($?) {
    $log->warn("IAS-Batch: error al generar el $p{msg} (RC=$?): $ret");
  }
  else {
    $log->info($p{tar_dir}, ("$tar_filename.gz", "IAS-Batch: $p{msg} generado: $tar_filename.gz."));
  }
}

1;
