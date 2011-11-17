package BaselinerX::J2EE::IAS;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use Data::Dumper;
use Try::Tiny;
use utf8;

sub ias_batch_build {
  my $self = shift;
  my $log = shift;
  my %p = %{shift()};

  # # Too late. I don't seem to need this at the moment.
  # my $elements = {$self->hash_elements($p{elements})};

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
      my $sa = $1 if $e->{subapl} =~ /(\w+)_BATCH/;
      $subapl{$sa} = $e->{project};

      # Guardo estos datos en el 'stash', para luego...
      $dist->{ias_batch}->{subapls}->{$sa} = $e->{project};
    }
  }

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

    $log->info("IAS-BATCH build_$project.xml ($buildxml_file)", $bx->data);
    $bx->save($buildxml_file);

    # quita el /config
    my $config = config_package($log,
                                {dist    => $dist,
                                 project => $project});

    # copia el /lib - no se borra pq tiene que ir a staging
    my $barra_lib = prepara_lib($log,
                                dist    => $dist,
                                project => $project);

    # build
    my @OUTPUT = $w->output();
    unless (@OUTPUT) {
      $log->info("No se ha podido detectar la estructura IAS-Batch para la subaplicación $sa (no output)");
      next;
    }

    _log "llamo a buildme";

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
  return @proyectos;
}

sub config_package {
  my ($log, $p) = @_;
  my $dist    = $p->{dist};
  my $subapl  = $p->{subapl};
  my $project = $p->{project};
  my $dir     = $dist->{buildhome} . "/" . $project . "/Config";
  my $destdir =
    File::Spec->canonpath($dist->{buildhome} . "/../" . $project . "Config");
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
  my $subapl  = $p{subapl};
  my $project = $p{project};
  my $dir     = $dist->{buildhome} . "/" . $project . "/lib";
  my $destdir =
    File::Spec->canonpath($dist->{buildhome} . "/../" . $project . "lib");
  if (-e $dir) {
    $log->debug("IAS-BATCH: Copiando y empaquetando directorio /lib '$dir'");
    $log->debug("Move $dir => $destdir", `cp -R $dir $destdir`);
  }
  else {
    $log->debug("IAS-BATCH: Directorio /lib '$dir' no existe");
  }
  $destdir;
}

sub buildme {
  my $log = shift;
  my %p         = @_;
  my $dist      = $p{dist};
  my $subapl    = $p{subapl};
  my $buildfile = $p{buildfile};
  my $buildxml  = $p{buildxml};
  my $output    = $p{output};

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
                 folders   => [qw/BATCH/],);

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

    $log->info("ANT compilando y empaquetando $buildxml (espere)...",
               "ant $param $buildxml");

    $executeString = qq[cd "$STA{buildhome}" ; $pathChange ant $param -buildfile $buildxml 2>&1];
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
    if (config_get('config.bde')->{sqa_activo}) {
      sqa_tar(
        $balix,
        { rem_dir  => $STA{buildhome},
          pase_dir => $buildhome . "/../..",
          subapl   => $subapl,
          entorno  => $Entorno,
          cam      => $CAM,
          pase     => $Pase,
          nature   => 'JAVABATCH',
        }
      );    # if $Dist{tipopase} eq 'N';
    }
  }
  catch {
    my $err = shift;
    $log->error("IAS-BATCH error durante la compilación", $err);
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

  $log->debug("send_dir options " . Dumper \%param);
  
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
    my ($win_maq, $win_puerto, $win_dir) =
      ($stawin, $stawinport, $stawindir);
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
    ($RC, $RET) = $balix->execute(
      "cd /D \"$temp_dir\" & $stawintarexe xvf \"$tarname\" & del /Q \"$remoto\""
    );
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
      # use Harax;
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
  my $log    = shift;
  my %p      = @_;
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
  my $log = shift;
  my %p   = @_;

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
  my $tmpdir = $ENV{TEMP} . "/${Pase}.tmp/";
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

1;
