package BaselinerX::Model::Eclipse::Dist;
use 5.010;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Try::Tiny;
use utf8;

has 'pase', is => 'rw', isa => 'Str', required => 1;
has 'conf', is => 'rw', isa => 'HashRef', lazy_build => 1;

sub _build_conf { config_get('config.bde') }

sub _eclipse_dir {
  my ($self, $env) = @_;
  my $str = "sta_eclipse_home_$env";
  config_get('config.bde')->{$str};
}

sub eclipseDist {
  my $self     = shift;
  my $Pase     = shift;
  $self->pase($Pase);
  my %Elements = %{shift @_};
  my ($PaseDir, $EnvironmentName, $Entorno, $Sufijo, $release, @tipos) = @_;
  my ($cam, $CAM)  = get_cam_uc($EnvironmentName);
  my $rootdir      = "$PaseDir/$CAM/$Sufijo";
  my %FEAT         = ();                        # listado de features afectadas por este pase
  my $configFolder = "configuration";

  my $apl_publico               = $self->conf->{apl_publico};
  my $gnutar                    = $self->conf->{gnutar};
  my $sqa_activo                = $self->conf->{sqa_activo};
  my $sta_eclipse_anthome       = $self->conf->{sta_eclipse_anthome};
  my $sta_eclipse_clase         = $self->conf->{sta_eclipse_clase};
  my $sta_eclipse_home          = $self->conf->{sta_eclipse_home};
  my $sta_eclipse_ias_feature   = $self->conf->{sta_eclipse_ias_feature};
  my $sta_eclipse_java_home     = $self->conf->{sta_eclipse_java_home};
  my $sta_eclipse_java_vmparams = $self->conf->{sta_eclipse_java_vmparams};
  my $sta_eclipse_javacsource   = $self->conf->{sta_eclipse_javacsource};
  my $sta_eclipse_javactarget   = $self->conf->{sta_eclipse_javactarget};
  my $sta_eclipse_maq           = $self->conf->{sta_eclipse_maq};
  my $sta_eclipse_staging       = $self->conf->{sta_eclipse_staging};
  my $sta_eclipse_version       = $self->conf->{sta_eclipse_version};
  my $sta_ias_precomp_jar       = $self->conf->{sta_ias_precomp_jar};
  my $sta_ias_precomp_use       = $self->conf->{sta_ias_precomp_use};
  my $state_publico             = $self->conf->{state_publico};
  my $stawin                    = $self->conf->{stawin};
  my $stawinchgperm             = $self->conf->{stawinchgperm};
  my $stawindir                 = $self->conf->{stawindir};
  my $stawinport                = $self->conf->{stawinport};
  my $stawintarexe              = $self->conf->{stawintarexe};

  # dir donde encuentro las versiones de eclipse instaladas (base, pde, etc.)
  my $eclipseDir     = $self->_eclipse_dir($Entorno) || $sta_eclipse_home;
  my $eclipseVersion = $sta_eclipse_version;
  my $javaHome       = $sta_eclipse_java_home;
  my $javacSource    = $sta_eclipse_javacsource;
  my $javacTarget    = $sta_eclipse_javactarget;

  # flag que controla si normalizamos por expresion regular o por XML-Smart
  my $normRE = 1;
  ## busco las features afectadas
  my $featDir = "";
  chdir $rootdir;
  my ($RC, $RET, @RET);
  my $plugHome = "$PaseDir/$CAM/$Sufijo/plugins";

  foreach my $VersionId (keys %Elements) {
    my $FileName        = $Elements{$VersionId}->{FileName}; 
    my $ObjectName      = $Elements{$VersionId}->{ObjectName}; 
    my $PackageName     = $Elements{$VersionId}->{PackageName}; 
    my $SystemName      = $Elements{$VersionId}->{SystemName}; 
    my $SubSystemName   = $Elements{$VersionId}->{SubSystemName}; 
    my $DSName          = $Elements{$VersionId}->{DSName}; 
    my $Extension       = $Elements{$VersionId}->{Extension}; 
    my $ElementState    = $Elements{$VersionId}->{ElementState}; 
    my $ElementVersion  = $Elements{$VersionId}->{ElementVersion}; 
    my $ElementPriority = $Elements{$VersionId}->{ElementPriority}; 
    my $ElementPath     = $Elements{$VersionId}->{ElementPath};
    my $carpeta         = $Elements{$VersionId}->{ElementPath};
    my $ElementID       = $Elements{$VersionId}->{ElementID}; 
    my $ParCompIni      = $Elements{$VersionId}->{ParCompIni}; 
    my $NewID           = $Elements{$VersionId}->{NewID}; 
    my $HarvestProject  = $Elements{$VersionId}->{HarvestProject}; 
    my $HarvestState    = $Elements{$VersionId}->{HarvestState}; 
    my $HarvestUser     = $Elements{$VersionId}->{HarvestUser}; 
    my $ModifiedTime    = $Elements{$VersionId}->{ModifiedTime};

    my $subapl = (split(/\//, $ElementPath))[3];

    _log "\$subapl = $subapl";

    if ($subapl =~ /feature/i) {
      $featDir = $subapl;    # = "features", pero puede que estÃ© en plural, o mayusculas...
      my $featName = (split(/\//, $ElementPath))[4];
      $FEAT{$featName}{featFile} = "$PaseDir/$CAM/$Sufijo/$featDir/$featName/feature.xml";
      _log "Feature afectada: $FEAT{$featName}{featFile}\n";
    }

    if (!%FEAT) {
      _log "No se han encontrado features para compilar (versiones de feature.xml) en los paquetes del pase.";  # WARN
      return;
    }

    ########################################################################################################
    #### PARSE
    ########################################################################################################

    foreach my $feat (keys %FEAT) {
      my $featFile = $FEAT{$feat}{featFile};
      my ($id, $version, $pde);
      _log "EclipseDist: procesando feature $featFile";  # INFO
      ## parse de campos del feature.xml...
      my $XML = XML::Smart->new($featFile);  # TODO check if exists
      if ($XML) {
        ## Parse: ID feature
        $id = $XML->{feature}{id};
        ## Parse: Version feature
        $version = $XML->{feature}{version};
        ## Parse: Version PDE
        $pde = $XML->{feature}{requires}{import}('plugin', 'eq', $sta_eclipse_clase)->{version};
        _log "InformaciÃ³n parseada de feature.xml: ID=<b>$id</b>, VERSION=<b>$version</b>, $sta_eclipse_clase=<b>$pde</b>";  # DEBUG

        ## Normalizando versiones de plugin
        _log "<b>$feat</b>: Normalizando versiones entre feature y plugins...";  # DEBUG
        my @ids = $XML->{feature}{plugin}('[@]', 'id');
        my $logtxt = "";

        # bucle de todos los plugins requeridos por la feature
        foreach my $id (@ids) {
          $logtxt .= "ID=$id";
          my $ver = $XML->{feature}{plugin}('id', 'eq', $id)->{version};
          $logtxt .= ", VERSION  PLUGIN EN FEATURE=$ver\n";

          #logdebug "VERSION PLUGIN EN FEATURE=$ver, FEATURE=$feat, ID_PLUGIN=$id, PLUGHOME=$plugHome";
          ## abro el plugin.xml y le cambio la version
          my $plugFile = "$plugHome/$id/plugin.xml";

          #logdebug "plugFile = $plugFile ";
          if ($normRE) {
            if (!open(PF, "<$plugFile")) {
              _log "<b>$feat</b>: ERROR: no he podido abrir $plugFile para normalizar: $!. Se procede a inspeccionar el MANIFEST.MF del plugin";    # WARN

              #logdebug "No se puede abrir o no existe el archivo $plugFile del plugin $id. Se procede a explorar el archivo MANIFEST.MF del plugin en su lugar...";
              _log "this subroutine may not exist...";


              _log "putFeatVersionToPlugManifest() may not exist!";  # XXX
              putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);  # TODO check if exists
            }
            else {
              my $pf;
              $pf .= $_ foreach (<PF>);
              close PF;

              # Busca la lÃ­nea plugin en el fichero de plugin.xml.
              if ($pf =~ /<plugin(.*?)>/sg) {

                # El archivo plugin.xml del plugin contine el elemento raÃ­z.
                my $tk = $1;
                if ($tk =~ /version(.*?)/sg) {

                  # El archivo plugin.xml contiene el atributo version.
                  #logdebug "Se procede a modificar el atributo version del archivo $plugFile del plugin $id.";
                  $tk =~ s/version="(.*?)"/version="$ver"/g;    ## esto tiene todos los peligros que supone usar variables en las RE, pero es mejor que el XML::Smart
                  my $oldver = $1;

                  # oldver es correcto
                  #logdebug "VersiÃ³n antigua=$oldver";
                  $logtxt .= "PLUGIN_VERSION=$oldver, REQUIRED_PLUGIN_VERSION=$ver\n";
                  if ($oldver ne $ver) {

                    #logdebug "version nueva =$ver";
                    # version nueva es correcto.
                    $pf =~ s/<plugin(.*?)>/<plugin${tk}>/gs;    ## mismo peligro que arriba

                    #logdebug "Plugin despuÃ©s de modificar la versiÃ³n=$pf";
                    open(PF, ">$plugFile") or die "ERROR: no he podido abrir $plugFile para escritura: $!";
                    print PF $pf;
                    close PF;
                    $logtxt .= ">>>>>> PLUGIN cambiado $id a '$ver'\n\n";
                  }
                }
                else {

                  # No existe el atributo version en el $plugFile. Explorando archivo MANIFEST.MF del plugin...;
                  _log "putFeatVersionToPlugManifest() may not exist!";    # XXX
                  putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
                }
              }
              else {

                # El archivo plugin.xml NO contiene el elemento raÃ­z plugin por lo que se procesa el manifest.mf del plugin en lugar del plugin.xml.
                _log "<b>$pf</b>: ERROR: no existe el elemento raÃ­z  /<plugin(.*?)>/sg en el archivo $plugFile: $!. Se procede a inspeccionar el MANIFEST.MF del plugin"; # WARN

                #logdebug "El archivo plugin.xml del plugin $id no contiene el elemento raÃ­z plugin por lo que se procede a inspeccionar el archivo MANIFEST.MF de este plugin en su lugar.";
                _log "putFeatVersionToPlugManifest() may not exist!";  # XXX
                putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
              }
            }
          }
          else {
            _log "No normalizado.";  # DEBUG
            my $XMLPLUG = XML::Smart->new($plugFile);
            if (!$XMLPLUG) {
              _log "<b>$feat</b>: ERROR: no he podido abrir el fichero $plugFile para normalizar: $!.Se procede a inspeccionar el MANIFEST.MF del plugin\n";  # WARN
              putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
            }
            else {
              my $oldver = $XMLPLUG->{plugin}{version};

              # Si no existe el atributo version en el plugin.xml se procesa el manifest.mf del plugin en lugar del plugin.xml.
              if ($oldver eq -1) {
                putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
              }
              else {

                # Ponemos en el archivo plugin.xml la versiÃ³n del plugin indicada en la feature para este plugin.
                $logtxt .= "PLUGIN_VERSION=$oldver, REQUIRED_PLUGIN_VERSION=$ver\n";
                $XMLPLUG->{plugin}{version} = $ver;
                $logtxt .= ">>>>>> PLUGIN $id cambiado a '$ver' (via XML::Smart)\n\n";
                $XMLPLUG->save($plugFile);    ## esto guarda el fichero de manera un poco distinta al original, no me gusta
              }
            }
          }
        }
        if ($logtxt) {
          ## me hago un tar de todos los plugin.xml para garantizar que la siguiente feature no los machaque
          my $RET = `cd "$PaseDir/$CAM/$Sufijo"; find . -name "plugin.xml" -exec $gnutar rvf plugins_${feat}.tar {} \\; 2>&1`;

          #logdebug "RET logtxt=$RET";
          _throw "no se ha podido crear el fichero de plugins plugins_${feat}.tar (RC=$RC): $RET" if ($RC);
          ## me hago un tar de todos los MANIFEST.MF para garantizar que la siguiente feature no los machaque
          my $RET2 = `cd "$PaseDir/$CAM/$Sufijo"; find . -name "MANIFEST.MF" -exec $gnutar rvf manifest_${feat}.tar {} \\; 2>&1`;

          #logdebug "RET2 logtxt=$RET2";
          my $RC2 = "";
          _throw "no se ha podido crear el fichero dearchivos manifest manifest_${feat}.tar (RC=$RC2): $RET2" if ($RC2);
          _log "<b>$feat</b>: fin de la normalizaciÃ³n de plugins.", $logtxt . "\n" . "TAR DE PLUGINS\n" . $RET . "\n" . "TAR DE MANIFEST\n" . $RET2; # DEBUG
        }
        else {
          _log "<b>$feat</b>: no he encontrado plugins para normalizar.";  # INFO
        }
      }

      if ((!$id) or (!$version) or (!$pde) or ($id eq "") or ($version eq "") or ($pde eq "")) {
        _log "<b>$feat</b>: falta alguna variable en el fichero feature.xml: ID=$id, VERSION=$version, $sta_eclipse_clase=$pde"; # ERROR
        _throw "Error al compilar feature $feat. Fichero feature.xml incompleto.";
      }

      $FEAT{$feat}{id}      = $id;
      $FEAT{$feat}{version} = $version;
      $FEAT{$feat}{pde}     = $pde;

      ## creo una carpeta de configuration para esta feature: configuration/<nombre_feature>
      my $configDir     = "$PaseDir/$CAM/$Sufijo/$configFolder/$eclipseVersion";
      my $featConfigDir = "$PaseDir/$CAM/$Sufijo/$configFolder/$feat";
      mkdir $featConfigDir;
      _log "<b>$feat</b>: Copiando contenidos de configuraciÃ³n de la carpeta de config '$configDir' a '$featConfigDir'"; # DEBUG
      @RET = `cp -R "$configDir"/* "$featConfigDir" 2>&1`;
      if ($? ne 0) { _throw "EclipseDist: no se ha podido generar la carpeta de configuraciÃ³n de la feature '$featConfigDir': @RET"; }

      ## Sustituye la versiÃ³n de PDE en configuration/><nombre_feature>/build.properties por la version PDE de feature
      my $buildProp = "$featConfigDir/build.properties";
      my $pathBase  = "$eclipseDir/$pde";
      open(BUILD, "<$buildProp") or _throw "EclipseDist: No he podido abrir el fichero $buildProp: $!";
      my $NEWBUILD;
      foreach my $line (<BUILD>) {
        if ($line =~ /base\=\<path\/to\/parent\/of\/eclipse\>/) {
          $NEWBUILD .= "$sta_eclipse_clase base=$pathBase\n";
          print "EclipseDist: modificado $buildProp\n";

        }
        elsif ($line =~ /buildType\=(.*?)$/) {  ## una letra, como I, M, N, S ...
          $FEAT{$feat}{buildType} = $1;
          $NEWBUILD .= $line;
        }
        elsif ($line =~ /buildId\=(.*?)$/) {   ## nombre libre
          $FEAT{$feat}{buildId} = $1;
          $NEWBUILD .= $line;
        }
        elsif ($line =~ /buildLabel\=(.*?)$/) {  ## buildid.buildtype - directorio de output
          $FEAT{$feat}{buildLabel} = $1;
          $NEWBUILD .= $line;
        }
        else {
          $NEWBUILD .= $line;
        }
      }
      close BUILD;
      ## no hace falta guardar datos en build.properties, se utiliza -Dvar=
      ## pero seguirÃ© manteniendo el fichero para que quede como documento del pase
      open BUILD, ">$buildProp";
      print BUILD $NEWBUILD;
      close BUILD;
      _log "<b>$feat</b>: Fichero <b>build.properties</b> modificado ($buildProp).", $NEWBUILD; # INFO

      ## Sustituye el id de feature en allElements.xml
      my $allElements = "$featConfigDir/allElements.xml";
      open(ALLE, "<$allElements") or _throw "EclipseDist: No he podido abrir el fichero $allElements: $!";
      my $NEWALLE;
      foreach my $line (<ALLE>) {
        $line =~ s/element.id/$id/g;
        $line =~ s/\[\.config\.spec\]//g;
        $NEWALLE .= $line;
      }
      close ALLE;
      open ALLE, ">$allElements";
      print ALLE $NEWALLE;
      close ALLE;

      ## ANT para descomprimir el zip de feature (para staging)
      open UNZIP, ">$rootdir/unzip.xml";
      my $unzip = qq|
        <project name="unzipFeature" default="main">
            <target name="main">
                <echo>Descomprimiendo el fichero de feature '\${featFile}' en '\${staFeatDir}'</echo>
                <unzip src="\${featFile}"
                        dest="\${staFeatDir}">
                </unzip>
                <!-- echo>Tar del fichero de feature '\${tarFile}' desde '\${staFeatDir}'</echo>
                <tar destfile="\${tarFile}" basedir="\${staFeatDir}" />
                <gzip src="\${tarFile}" destfile="\${tarFile}.gz"  / -->
            </target>
        </project>      
        |;
      print UNZIP $unzip;
      _log "Fichero para descomprimir features creado.", $unzip; # DEBUG
      close UNZIP;

      ## ANT para comprimir log del antRunner (en staging)
      open ZIPLOG, ">$rootdir/ziplog.xml";
      my $ziplog = qq|
        <project name="zipLogAntRunner" default="main">
            <target name="main">
                <echo>Comprimiendo el fichero de log del antRunner '\${logFile}' a '\${logZipFile}'</echo>
                <zip destfile="\${logZipFile}">
                    <fileset dir="\${logDir}" includes="\${logFile}" />
                </zip>
            </target>
        </project>      
        |;
      print ZIPLOG $ziplog;
      _log "Fichero para comprimir el log del antRunner creado.", $ziplog; # DEBUG
      close ZIPLOG;

    }

    ########################################################################################################
    #### ENVIO
    ########################################################################################################

    ## EnvÃ­o a Staging
    # GENERAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE
    my $tarfile = "$PaseDir/$CAM/$Sufijo/${Pase}-$EnvironmentName-$Sufijo.tar";
    $RET = `cd "$PaseDir/$CAM/$Sufijo";$gnutar -cvf "$tarfile" * 2>&1`;
    _log "TAR '$tarfile' del directorio '$PaseDir/$CAM/$Sufijo' finalizado.", $RET; # DEBUG

    # PARAMETROS DEL SERVIDOR DE STAGING
    my ($stamaq, $stapuerto, $stadir) = ($sta_eclipse_maq, $stawinport, $stawindir);
    if (!$stamaq) {
      $stamaq = $stawin;
    }
    _log "Abiendo conexiÃ³n con agente en $stamaq:$stapuerto";   # DEBUG
    my $harax = Harax->open($stamaq, $stapuerto, "win");  # TODO
    if (!$harax) {
      _log "No he podido establecer conexiÃ³n con el servidor de compilaciÃ³n $stamaq en el puerto $stapuerto"; # ERROR
      _throw "Error al establecer conexiÃ³n con el servidor de compilaciÃ³n";
    }
    _log "ConexiÃ³n abierta con el cliente en $stamaq:$stapuerto"; # DEBUG
    my $destpasedir = "${stadir}\\${Pase}\\$CAM\\$Sufijo";

    try {

      # NO BORRAR, el siguiente cÃ³digo, llamada a la subrutina doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir) estÃ¡ probado y

      # funciona pero de momento prescindimos de hacer xcopy en el caso de distribuciones eclipse por razones de rendimiento
      # ya que no hay problemas con los permisos tal y como ocurre con las distribuciones net, rs y biztalk.
      #loginfo "Llamando al mÃ³dulo utilsWin desde sub eclipseDist...";
      #doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir);
      #loginfo "Fin ejecuciÃ³n subrutina doUntarAndRestorePermission";

      # ENVIAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE AL SERVIDOR DE STAGING
      _log "Enviando el TAR a Staging ($destpasedir\\${Pase}.tar). Espere...";  # INFO
      my $desttarfile = "$destpasedir\\${Pase}.tar";
      ($RC, $RET) = $harax->sendFile($tarfile, $desttarfile);
      _log "Ok. TAR file en destino (RC=$RC)"; # INFO

      # DESCOMPRIMIMOS EL FICHERO TAR EN EL STAGING
      ($RC, $RET) = $harax->execute("cd /D \"$destpasedir\" & $stawintarexe pxvf ${Pase}.tar");
      if ($RC ne 0) {
        _log "Error en al descomprimir el archivo TAR (RC=$RC)", $RET;  # ERROR
        _throw "Error durante la preparaciÃ³n de la aplicaciÃ³n.";
      }
      else {
        _log "UNTAR (RC=$RC)", $RET;  # INFO
      }

      # BORRAMOS EL FICHERO TAR EN STAGING
      if ($RC eq 0) {
        ($RC, $RET) = $harax->execute("del \"$desttarfile\"");
      }

      ($RC, $RET) = $harax->execute("$stawinchgperm \"$destpasedir\"");
      if ($RC ne 0) {
        _log "Error  al asignar permisos de escritura a \"$destpasedir\" (RC=$RC) ", $RET;  #  ERROR
        _throw "Error durante la preparaciÃ³n de la aplicaciÃ³n.";
      }
      else {
        _log "Cambiados los permisos del directorio $destpasedir (RC=$RC)", $RET;  # INFO
      }
    }
    catch {
      _throw "Error al transferir ficheros al nodo $stamaq: " . shift();
    };

    ########################################################################################################
    #### CONSTRUCCION
    ########################################################################################################
    try {
      ## INVESTIGAMOS CUAL ES LA CARPETA DE BUILD DEL ECLIPSE
      my $eclipseHome = "$eclipseDir/$eclipseVersion";
      my $pdeBuildDir = "";
      _log "Buscando directorio de pde.build en '$eclipseHome/plugins/'...";  # DEBUG
      ($RC, $RET) = $harax->execute(qq{dir /b /n "$eclipseHome/plugins/"});
      if ($RC ne 0) { _throw "No se ha podido buscar el directorio de pde.build donde estarÃ­a el build.xml para el antRunner: $RET"; }
      else {
        $RET =~ s/\r//g;
        if ($RET =~ /org\.eclipse\.pde\.build_(.*?)\n/) {
          $pdeBuildDir = $1;
          if ($pdeBuildDir eq "") {
            _log "No se ha encontrado un directorio org.eclipse.pde.build_* en $eclipseHome/plugins/", $RET; # ERROR
            _throw "Error durante la preparaciÃ³n para la construcciÃ³n de feature/plugins.";
          }
          $pdeBuildDir = "org.eclipse.pde.build_" . $pdeBuildDir;
          _log "Directorio org.eclipse.pde.build detectado: <b>$pdeBuildDir</b>", $RET;  # DEBUG
        }
        else {
          _log "No se ha encontrado un directorio org.eclipse.pde.build_* en $eclipseHome/plugins/", $RET;   # ERROR
          _throw "Error durante la preparaciÃ³n para la construcciÃ³n de feature/plugins.";
        }
      }
      my $buildFile = "$eclipseHome/plugins/$pdeBuildDir/scripts/build.xml";

      ## LANZAMOS EL BUILD PARA CADA FEATURE
      foreach my $feat (keys %FEAT) {
        my $buildDir   = "$destpasedir";
        my $configDir  = "$buildDir/$configFolder/$feat";
        my $base       = "$eclipseDir/$FEAT{$feat}{pde}";
        my $buildId    = "$FEAT{$feat}{version}";  # utilizado en el nombre del fichero de salida
        my $buildLabel = "output-$feat";            # carpeta de salida
        my $localLog   = "antRunner-${feat}.log";
        my $logFile    = "$buildDir\\$localLog";
        _log "<b>$feat</b>: base=$base";  # DEBUG

        # Descomprimo tar de plugin.xml
        ($RC, $RET) = $harax->execute(qq|cd /D "$destpasedir" & $stawintarexe pxvf "plugins_${feat}.tar" 2>&1|);
        _log "<b>$feat</b>: untar de plugins (RC=$RC)", $RET;   # DEBUG

        # Descomprimo tar de MANIFEST.MF
        ($RC, $RET) = $harax->execute(qq|cd /D "$destpasedir" & $stawintarexe pxvf "manifest_${feat}.tar" 2>&1|);
        _log "<b>$feat</b>: untar de MANIFEST (RC=$RC)", $RET; # DEBUG
        my $cmd = qq|cd /D "$destpasedir" & ${javaHome}\\bin\\java $sta_eclipse_java_vmparams -jar ${eclipseHome}/startup.jar -application org.eclipse.ant.core.antRunner -buildfile "$buildFile" -Dbuilder="$configDir" -DbaseLocation="${base}" -DbuildDirectory="$buildDir" -DarchivePrefix=" " -DbuildId="$buildId" -DbuildLabel="$buildLabel" -DtopLevelElementId="$feat" > "$logFile" 2>&1|;
        _log "<b>$feat</b>: inicio del <b>antRunner</b>. Espere...", $cmd;  # INFO
        my ($antRC, $antRET) = $harax->execute($cmd);
        _log "<b>$feat</b>: fin del <b>antRunner</b> (RC=$RC). Recuperando y publicando fichero de log $logFile. Espere...";  # INFO
        ## ZIP del log
        ($RC, $RET) = $harax->execute(qq|set PATH=$javaHome\\bin;\%PATH\% & $sta_eclipse_anthome\\bin\\ant -f "$destpasedir\\ziplog.xml" -DlogFile="$localLog" -DlogZipFile="${logFile}.zip" -DlogDir="$destpasedir"|);
        if ($RC ne 0) {
          _log "<b>$feat</b>: No se ha podido comprimir el fichero $logFile => ${logFile}.zip en $stamaq. El log de antRunner no estarÃ¡ disponible.", $RET;  # WARN
        }
        else {
          _log "<b>$feat</b>: fichero de log de antRunner $logFile comprimido.", $RET;  # DEBUG
          ## Recupero el log
          my ($aRC, $aRET) = $harax->getFile("${logFile}.zip", "$rootdir/${localLog}.zip", "win");
          _log $rootdir, "${localLog}.zip", "<b>$feat</b>: log del antRunner.";  # file
        }
        if ($antRC ne 0) {
          _log "<b>$feat</b>: Error durante la ejecuciÃ³n de <b>antRunner</b> (RC=$RC) ", $antRET;   # ERROR
          _throw "Error durante la construcciÃ³n de la feature <b>$feat</b>.";
        }
        else {
          _log "<b>$feat</b>: <b>antRunner</b> terminado con Ã©xito (RC=$RC)", $antRET;   # INFO
        }
        $FEAT{$feat}{features}   = $buildDir . "/features";
        $FEAT{$feat}{plugins}    = $buildDir . "/plugins";
        $FEAT{$feat}{outputHome} = $buildDir . "/" . $buildLabel;
        $FEAT{$feat}{outputFile} = "$FEAT{$feat}{id}-$FEAT{$feat}{version}.zip";
        $FEAT{$feat}{configDir}  = $configDir;
      }
      ## SQA
#       if ( $sqa_activo || $PaseNodist  ) {
#           try { use strict;
#                   sqa_tar($harax, {
#                           rem_dir => $destpasedir,
#                           pase_dir => $PaseDir,
#                           subapl => $CAM,
#                           entorno => $Entorno,
#                           cam => $CAM,
#                           pase => $Pase,
#                           nature => 'ECLIPSE',
#                    });
#           } otherwise {
#                   logwarn "Error durante la generaciÃ³n de SQA: " . shift;
#           };
#       }
      ## FIN SQA
    }
    catch {
      _throw "Error durante la construcción: " . shift();
    };

    ########################################################################################################
    #### SALIDA
    ########################################################################################################

    ## SQA
    unless ($main::PaseNodist) {
      foreach my $feat (keys %FEAT) {
        ## RECUPERAMOS EMPAQUETADOS
        my $fich = "$FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile}";
        _log "<b>$feat</b>: recuperando fichero de salida $fich";    # INFO

        ## Creo la carpeta /staging/<id_feature>_<version_feature>/eclipse
        my $staFeat     = "$sta_eclipse_staging/$CAM/$FEAT{$feat}{id}_$FEAT{$feat}{version}/eclipse";
        my $staFeatures = "$staFeat/features";
        my $staPlugins  = "$staFeat/plugins";

        ## Creo carpeta y descomprimo contenido en Stagnig , solo si es pase a PROD.
        if ($Entorno eq "PROD") {

          ($RC, $RET) = $harax->execute(qq{mkdir "$staFeat"});
          if ($RC ne 0) {
            _log "<b>$feat</b>: No se ha podido crear la carpeta $staFeat en $stamaq (pueda que ya existiera). RC=$RC: $RET";    # WARN
            if ($RET =~ /already/i) {
              ($RC, $RET) = $harax->execute(qq{rmdir /S /Q "$staFeat" & mkdir "$staFeat"});
              if ($RC ne 0) {
                _log "<b>$feat</b>: No se ha podido borrar la carpeta $staFeat para volver a crearla (RC=$RC)", $RET;  # ERROR
                _throw "eclipseDist: error al crear la carpeta $staFeat";
              }
              else {
                _log "<b>$feat</b>: se ha vaciado y vuelto a crear la carpeta $staFeat.", $RET;   # DEBUG
              }
            }
          }
          else {
            _log "<b>$feat</b>: carpeta $staFeat creada.";  # DEBUG
          }
        }
        my $tarFile = "$FEAT{$feat}{id}_$FEAT{$feat}{version}.tar";

        ## 1) Unzip a /staging (SOLO PROD)
        ## if( ($Entorno eq "PROD") or ( scm_entorno() ne 'PROD' ) ) {  # en vtscm y vascm lo hacemos para todos los entornos
        if ($Entorno eq "PROD") {                                                                                                ## solo si el pase es para una version de PROD da igual en que broker. Cambio a peticion a raiz de la gdf 67506 .
          ($RC, $RET) = $harax->execute(qq|set PATH=$javaHome\\bin;\%PATH\% & $sta_eclipse_anthome\\bin\\ant -f "$destpasedir/unzip.xml" -DfeatFile="$FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile}" -DstaFeatDir="$staFeat" -DtarFile="$staFeat/$tarFile"|);
          if ($RC ne 0) {
            _log "<b>$feat</b>: No se ha podido descomprimir el fichero $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} => $staFeat en $stamaq", $RET;  # ERROR
            _throw "eclipseDist: error al descomprimir la feature a $staFeat";
          }
          else {
            _log "<b>$feat</b>: descomprimido $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} en $staFeat.", $RET;  # INFO
          }
        }

        # RECUPERAMOS EL ZIP CON EL RESULTADO DE LA PUBLICACIÃ“N
        my $origZipFile = "$FEAT{$feat}{outputHome}\\$FEAT{$feat}{outputFile}";
        $origZipFile =~ s/\//\\/g;
        _log "<b>$feat</b>: Recuperando fichero ZIP $FEAT{$feat}{outputHome}\\$FEAT{$feat}{outputFile}. Espere...";   # DEBUG
        ($RC, $RET) = $harax->getFile($origZipFile, "$rootdir/$FEAT{$feat}{outputFile}", "win");
        if ($RC ne 0) {
          _log "Error al recuperar fichero $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} a $rootdir/$FEAT{$feat}{outputFile} (RC=$RC)", $RET; # ERROR
          _throw "eclipseDist: error al recuperar tar de feature $feat";
        }
        else {
          _log "Recuperado fichero $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} a $rootdir/$FEAT{$feat}{outputFile} (RC=$RC)", $RET; # DEBUG
        }

        ## UNTAR LOCAL
        my $checkinHome = "$PaseDir/$CAM/$Sufijo/checkin";
        my $release     = "$FEAT{$feat}{id}-$FEAT{$feat}{version}";
        my $ViewPath    = "/$apl_publico/$CAM/$Sufijo/$Entorno";
        my $checkinDir  = "$checkinHome/$release";
        `mkdir -p "$checkinDir" 2>&1`;
        @RET = `cd $checkinDir ; mv $rootdir/$FEAT{$feat}{outputFile} . 2>&1`;
        if ($? ne 0) {
          _log "<b>$feat</b>: Error durante el move del fichero de feature $tarFile para checkin a $apl_publico.", "@RET"; # ERROR
          _throw "Error durante el checkin a PUBLICO de la feature $feat";
        }
        else {
          _log "<b>$feat</b>: ZIP movido a $checkinDir para checkin a $apl_publico.", "@RET"; # DEBUG
        }

        ## CHECKIN a la aplicaciÃ³n PUBLICO
        _log "<b>$feat</b>: inicio checkin a la aplicaciÃ³n $apl_publico. Espere...";  # INFO
        checkinPublico(
          path     => $checkinHome,
          entorno  => $Entorno,
          viewpath => $ViewPath,
          project  => $apl_publico,
          state    => $state_publico,
          release  => $release,
          desc     => "Creado por el pase $Pase"
        );  # TODO this may not exist
      }
    }
    else {
      _log "Pase sin distribuciÃ³n finalizado";   # INFO
    }    ## si no hay distribuciÃ³n
    ########################################################################################################
    #### PUBLICACION
    ########################################################################################################

    $harax->end();

    ## FIN

  }
}

########################################################################################################
########################################################################################################
########################################################################################################
##
## GENERAR EL PROYECTO DE PASE IAS
##
########################################################################################################
########################################################################################################
########################################################################################################

sub generaProyectoPase {
  my $self = shift;
  my %Elements = %{shift @_};

  my $apl_publico               = $self->conf->{apl_publico};
  my $gnutar                    = $self->conf->{gnutar};
  my $sqa_activo                = $self->conf->{sqa_activo};
  my $sta_eclipse_anthome       = $self->conf->{sta_eclipse_anthome};
  my $sta_eclipse_clase         = $self->conf->{sta_eclipse_clase};
  my $sta_eclipse_home          = $self->conf->{sta_eclipse_home};
  my $sta_eclipse_ias_feature   = $self->conf->{sta_eclipse_ias_feature};
  my $sta_eclipse_java_home     = $self->conf->{sta_eclipse_java_home};
  my $sta_eclipse_java_vmparams = $self->conf->{sta_eclipse_java_vmparams};
  my $sta_eclipse_javacsource   = $self->conf->{sta_eclipse_javacsource};
  my $sta_eclipse_javactarget   = $self->conf->{sta_eclipse_javactarget};
  my $sta_eclipse_maq           = $self->conf->{sta_eclipse_maq};
  my $sta_eclipse_staging       = $self->conf->{sta_eclipse_staging};
  my $sta_eclipse_version       = $self->conf->{sta_eclipse_version};
  my $sta_ias_precomp_jar       = $self->conf->{sta_ias_precomp_jar};
  my $sta_ias_precomp_use       = $self->conf->{sta_ias_precomp_use};
  my $state_publico             = $self->conf->{state_publico};
  my $stawin                    = $self->conf->{stawin};
  my $stawinchgperm             = $self->conf->{stawinchgperm};
  my $stawindir                 = $self->conf->{stawindir};
  my $stawinport                = $self->conf->{stawinport};
  my $stawintarexe              = $self->conf->{stawintarexe};

  my $Pase = $self->pase;
  my ($PaseDir, $EnvironmentName, $Entorno, $Sufijo, $release, @tipos) = @_;
  my ($cam, $CAM) = get_cam_uc($EnvironmentName);
  my $rootdir = "$PaseDir/$CAM/$Sufijo";
  my (@generados, @dirpase) = ();    # variables de retorno para indicar cuales proyectos son generados, y cuales tienen dir de pase _SCM
  my $configFolder        = "configuration";
  my $eclipseDir          = _eclipse_dir($Entorno) || $sta_eclipse_home;    # dir donde encuentro las versiones de eclipse instaladas (base, pde, etc.)
  my $staDir              = "$sta_eclipse_staging/IAS";                     # dir en staging donde estÃ¡n las features de IAS E:/APSDAT/STAGING/PUBLICO/IAS
  my $eclipseVersion      = $sta_eclipse_version;
  my $javaHome            = $sta_eclipse_java_home;                         # $javaHome=~ s{\/}{\\}g;
  my $featureIAS          = $sta_eclipse_ias_feature;
  my $useScriptPrecompIAS = scriptPrecompIAS($Entorno);                     # si se debe usar el script de precompilaciÃ³n ias

  ## Un fichero APLICACION.AP o APLICACION.BATCH- indica si se preprocesa IAS o no
  my %PRJS = getProjectsFromElements(\%Elements, $EnvironmentName);         # quiero saber los proyectos web afectados
  my @PROYECTOS = keys %PRJS;

  # buscar proyectos ear para los proyectos afectados
  my $Workspace = Baseliner::Parse::Eclipse::J2EE->parse(workspace => $rootdir);
  $Workspace->cutToSubset($Workspace->getRelatedProjects(@PROYECTOS));
  my @WARS = $Workspace->getWebProjects();

  ## Java JARs
  my $WorkspaceJava = Baseliner::Parse::Eclipse::Java->parse(workspace => $rootdir);
  $WorkspaceJava->cutToSubset(@PROYECTOS);
  my @JARS = $WorkspaceJava->getProjects();

  _log "Proyectos WEB identificados para la precompilaciÃ³n IAS: \n" . join ',',        @WARS;    # INFO
  _log "Proyectos Java (JAR) identificados para la precompilaciÃ³n IAS: \n" . join ',', @JARS;    # INFO

  _log "Proyecto(s) J2EE Identificado(s) para la precompilaciÃ³n: \n" . join("\n", @PROYECTOS);   # DEBUG
  my %PRE = ();
  foreach my $paseprj (@WARS, @JARS, @PROYECTOS) {
    my @ap = `find "$rootdir/${paseprj}" -name "aplicacion.ap" -o -name "aplicacion.batch" -o -name "aplicacion.aptest" -o -name "aplicacion.aplib"`;
    if (!@ap or ($? ne 0)) {
      _log "<b>$paseprj</b>: no se han encontrado ficheros aplicacion.ap, aplicacion.aptest o aplicacion.batch. No se precompilarÃ¡ el proyecto.", "$!\n@ap";    # WARN
      push @dirpase, $paseprj;
    }
    else {
      if ($useScriptPrecompIAS) {
        ## con script de precompilaciÃ³n, no se mira la versiÃ³n
        $PRE{$paseprj}{versionIAS} = 1;
      }
      else {
        my $apFile = shift @ap;           ## cojo el primer aplicacion.* solamente
        chop $apFile;
        _log "<b>$paseprj</b>: abro el fichero $apFile para parsear...";  # DEBUG
        my $XML = XML::Smart->new($apFile);
        my $version;
        if ($XML) {
          ## Parse: Version IAS
          $version = $XML->{aplicacion}{configuracionProyecto}{versionEntornoDesarrollo};
          if ($version) {
            $PRE{$paseprj}{versionIAS} = $version;
            _log "<b>$paseprj</b>: version de la arquitectura de desarrollo IAS detectada '$version' (en $apFile)"; # INFO
          }
          else {
            _log "<b>$paseprj</b>: no se ha detectado version de la arquitectura de desarrollo IAS en $apFile. No se realizarÃ¡ la precompilaciÃ³n.";  # WARN
          }
        }
        else {
          _log "<b>$paseprj</b>: error al intentar parsear el xml de $apFile. No se realizarÃ¡ la precompilaciÃ³n";  # WARN
        }
      }
    }
  }
  if (!(keys %PRE)) {    ## si no hay nada que precompilar, me voy
    _log "No hay proyectos IAS para precompilar. Se utilizarÃ¡n los proyectos de pase que estÃ©n disponibles.";  # WARN
    return (\@generados, \@dirpase);
  }

  # PARAMETROS DEL SERVIDOR DE STAGING
  my ($stamaq, $stapuerto, $stadir) = ($sta_eclipse_maq, $stawinport, $stawindir);
  if (!$stamaq) {
    $stamaq = $stawin;
  }
  _log "Abiendo conexiÃ³n con agente en $stamaq:$stapuerto";    # DEBUG
  my $harax = Harax->open($stamaq, $stapuerto, "win");
  if (!$harax) {
    _log "No he podido establecer conexiÃ³n con el servidor de compilaciÃ³n $stamaq en el puerto $stapuerto"; # ERROR
    _throw "Error al establecer conexiÃ³n con el servidor de compilaciÃ³n";
  }
  _log "ConexiÃ³n abierta con el cliente en $stamaq:$stapuerto";  # DEBUG
  my $destpasedir = "${stadir}\\${Pase}\\$CAM\\$Sufijo";

  my ($RC, $RET);
  if (!$useScriptPrecompIAS) {
    ## VERSIONES de IAS en STAGING
    _log "Compruebo las versiones de la arquitectura de desarrollo IAS ($featureIAS) en Staging ($staDir)...";  # DEBUG
    ($RC, $RET) = $harax->execute(qq{dir /b /n "$staDir" });
    if ($RC ne 0) {
      _log "No se ha podido comprobar las versiones de la arquitectura de desarrollo IAS disponibles en Staging $stamaq:$staDir (RC=$RC)", $RET;   # ERROR
      _throw "Error al intentar comprobar versiones de la arquitectura de desarrollo de IAS en Staging.";
    }
    $RET =~ s/\r//g;
    my $DIR = $RET;
    my @VERS = split /\n/, $RET;

    ## COMPRUEBO que existe la version de IAS para el proyecto en Staging
    foreach my $paseprj (keys %PRE) {
      _log "<b>$paseprj</b>: verifico si la versiÃ³n de la arquitectura de desarrollo IAS estÃ¡ en staging: $PRE{$paseprj}{versionIAS}";   # DEBUG
      my ($iasDir) = grep(/\_$PRE{$paseprj}{versionIAS}$/, @VERS);
      if ($iasDir =~ /$featureIAS/) {
        _log "<b>$paseprj</b>: Ok, version <b>$PRE{$paseprj}{versionIAS}</b> de la arquitectura de desarrollo IAS disponible en $stamaq:$staDir/$iasDir", $DIR;    # DEBUG
        push @generados, $paseprj;
      }
      else {
        _log "<b>$paseprj</b>: version <b>$PRE{$paseprj}{versionIAS}</b>  de la arquitectura de desarollo IAS no estÃ¡ disponible en $stamaq:$staDir. PrecompilaciÃ³n ignorada para este proyecto.", $DIR; # WARN
        push @dirpase, $paseprj;
        delete $PRE{$paseprj};
        next;
      }
      $PRE{$paseprj}{iasDir} = $iasDir;

      ## VERSION DE PDE para cada IAS
      my $iasDirFeat = "$staDir\\$iasDir\\eclipse\\features\\$iasDir\\feature.xml";
      _log "Investigo versiÃ³n de Eclipse para feature $iasDir..."; # DEBUG
      ($RC, $RET) = $harax->execute(qq{type "$iasDirFeat"});
      if ($RC ne 0) {
        _log "<b>$paseprj</b>: no he podido abrir el fichero feature.xml para parsear la versiÃ³n de Eclipse ($staDir\\$iasDir\\eclipse\\features\\$iasDir\\feature.xml) RC=$RC", $RET;  # ERROR
        _throw "Error al comprobar la versiÃ³n de Eclipse en Staging.";
      }
      my $XML = XML::Smart->new($RET);
      my ($id, $version, $pde) = ();
      if ($XML) {
        ## Parse: ID feature
        $id = $XML->{feature}{id};
        ## Parse: Version feature
        $version = $XML->{feature}{version};
        ## Parse: Version PDE
        $pde = $XML->{feature}{requires}{import}('plugin', 'eq', $sta_eclipse_clase)->{version};
        if (!$pde) {
          _log "<b>$paseprj</b>: No he podido comprobar la versiÃ³n de Eclipse en el fichero feature.xml para la feature $iasDir ($iasDirFeat): $!"; # ERROR
          _throw "Error al comprobar la versiÃ³n de Eclipse en Staging.";
        }
        else {
          _log "<b>$paseprj</b>: Detectada versiÃ³n de Eclipse (plugin $sta_eclipse_clase): <b>$pde</b>, en el fichero feature.xml para la feature $iasDir ($iasDirFeat): $!";    # DEBUG
          $PRE{$paseprj}{pde} = $pde;
        }
      }
      else {
        _log "<b>$paseprj</b>: No se ha podido leer el fichero feature.xml para la feature $iasDir ($iasDirFeat): $!";  # ERROR
        _throw "Error al comprobar la versiÃ³n de Eclipse en Staging.";
      }

      ## BUILD.XML
      my $location = "$destpasedir/$paseprj";
      $location =~ s{\\}{\/}g;
      my $build = <<BUILD
<project name="project" default="default">
   <description>Precompilacion de $paseprj, IAS=$PRE{$paseprj}{iasDir}, PDE=$PRE{$paseprj}{pde}</description> 
   <target name="default">
     <ias.build projectLocation="$location"
          projectName="$paseprj" 
          environment="$Entorno" /> 
    </target>
</project>  
BUILD
        ;
      _log "<b>$paseprj</b>: precompilaciÃ³n IAS: buildSCM.xml", $build;    # INFO
      my $buildFile = "$rootdir/$paseprj/buildSCM.xml";
      if (-e $buildFile) {
        _log "<b>$paseprj</b>: existe el fichero $buildFile. Se sobrescribirÃ¡.";    # WARN
      }
      open BB, ">$buildFile" or do {
        _log "<b>$paseprj</b>: Error al intentar crear el fichero build.xml: $!";    # ERROR
        _throw "Error en la preparaciÃ³n de la precompilaciÃ³n IAS.";
      };
      print BB $build;
      close BB;
    }
  }
  else {
    ## Generamos el ias-precomp.properties para el script de precompilaciÃ³n
    ## (datos de entrada al script)
    foreach my $paseprj (keys %PRE) {
      ## ias-precomp.properties:
      push @generados, $paseprj;
      my $base        = "$eclipseDir/$PRE{$paseprj}{pde}";
      my $eclipseHome = "$base";                             ## la version padre
      my $location    = "$destpasedir/$paseprj";
      $location =~ s{\\}{\/}g;
      my $properties = qq|
                # Directorio donde estÃ¡n las versiones de eclipse
                EclipsesDir=${eclipseHome}
                # Directorio donde estÃ¡n las features de IAS
                FeaturesDir=$staDir
                # Directorio donde estÃ¡ el proyecto a precompilar
                ProjectDir=$location
                # Entorno (TEST/ANTE/PROD)
                Environment=$Entorno
                # LocalizaciÃ³n de la mÃ¡quina virtual (se utilizarÃ¡ cuando la versiÃ³n de eclipse no tenga
                # una JDK dentro)
                JavaHome=${javaHome}
            |;
      _log "<b>$paseprj</b>: precompilaciÃ³n IAS: ias-precomp.properties", $properties;  # INFO
      my $propertiesFile = "$rootdir/$paseprj/ias-precomp.properties";

      if (-e $propertiesFile) {
        _log "<b>$paseprj</b>: existe el fichero $propertiesFile. Se sobrescribirÃ¡.";   # WARN
      }
      open BB, ">$propertiesFile" or do {
        _log "<b>$paseprj</b>: Error al intentar crear el fichero ias-precomp.properties: $!";  # ERROR
        _throw "Error en la preparaciÃ³n de la precompilaciÃ³n IAS.";
      };
      print BB $properties;
      close BB;
    }
  }
  my $tarfile = "$PaseDir/$CAM/$Sufijo/${Pase}-$EnvironmentName-$Sufijo.tar";
  if (@generados) {

    # GENERAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE
    #TODO: podrÃ­amos mandar sÃ³lo el TAR de los _WEB con aplicacion.ap, pero no estoy seguro de que esto sea lo Ãºnico que se necesita para compilar
    #(Juan DomÃ­nguez) -> Nope: hay que enviar todos los proyectos en el TAR porque la precompilaciÃ³n utiliza a veces jars del _EAR
    #y genera a veces ficheros en el _EJB.
    my @RET = `cd "$PaseDir/$CAM/$Sufijo";$gnutar -cvf "$tarfile" * 2>&1`;
    if ($? ne 0) {
      _log "Error al realizar el TAR para envÃ­o a staging: RC=$?", "@RET";    # ERROR
      _throw "Error en la preparaciÃ³n de la precompilaciÃ³n IAS.";
    }
    else {
      _log "TAR '$tarfile' del directorio '$PaseDir/$CAM/$Sufijo' finalizado.", $RET;    # DEBUG
    }

    try {

      # NO BORRAR, el siguiente cÃ³digo, llamada a la subrutina doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir) estÃ¡ probado y
      # funciona pero de momento prescindimos de hacer xcopy en el caso de distribuciones eclipse por razones de rendimiento
      # ya que no hay problemas con los permisos tal y como ocurre con las distribuciones net, rs y biztalk.
      #loginfo "Llamando al mÃ³dulo utilsWin desde sub generaProyectoPase...";
      #doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir);
      #loginfo "Fin ejecuciÃ³n subrutina doUntarAndRestorePermission";

      # ENVIAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE AL SERVIDOR DE STAGING
      _log "Enviando el TAR a Staging ($destpasedir\\${Pase}.tar). Espere...";    # INFO
      my $desttarfile = "$destpasedir\\${Pase}.tar";
      ($RC, $RET) = $harax->sendFile($tarfile, $desttarfile);
      _log "Ok. TAR file en destino (RC=$RC)";                                    # DEBUG

      # DESCOMPRIMIMOS EL FICHERO TAR EN EL STAGING
      ($RC, $RET) = $harax->execute("cd /D \"$destpasedir\" & $stawintarexe pxvf ${Pase}.tar");
      if ($RC ne 0) {
        _log "Error en al descomprimir el archivo TAR (RC=$RC)", $RET;            # ERROR
        _throw "Error durante la preparaciÃ³n de la aplicaciÃ³n.";
      }
      else {
        _log "UNTAR (RC=$RC)", $RET;                                              # DEBUG
      }

      # BORRAMOS EL FICHERO TAR EN STAGING
      if ($RC eq 0) {
        ($RC, $RET) = $harax->execute("del \"$desttarfile\"");
      }

      # PONEMOS PERMISOS A LOS FICHEROS
      ($RC, $RET) = $harax->execute("$stawinchgperm \"$destpasedir\"");
      if ($RC ne 0) {
        _log "Error  al asignar permisos de escritura a \"$destpasedir\" (RC=$RC) ", $RET;    # ERROR
        _throw "Error durante la preparaciÃ³n de la aplicaciÃ³n.";
      }
      else {
        _log "Cambiados los permisos del directorio $destpasedir (RC=$RC)", $RET;             # DEBUG
      }
    }
    catch {
      _throw "Error al transferir ficheros al nodo $stamaq: " . shift();
    };
  }

  ## CONSTRUCCION
  foreach my $paseprj (keys %PRE) {
    if ($useScriptPrecompIAS) {
      ## Llamada al script de precompilaciÃ³n.
      _log "<b>$paseprj</b>: inicio script precompilaciÃ³n IAS.";                             # INFO
      my $buildDir = "$destpasedir/$paseprj";
      $buildDir =~ s{\\}{\/}g;
      my $propertiesFile = "$buildDir/ias-precomp.properties";
      my $cmd            = qq|cd /D "$destpasedir" & ${javaHome}\\bin\\java $sta_eclipse_java_vmparams -jar "$sta_ias_precomp_jar" "$propertiesFile"|;
      _log "<b>$paseprj</b>: inicio del script. Espere...", $cmd;                             # INFO
      my ($scriptRC, $scriptRET) = $harax->execute($cmd);

      if ($scriptRC > 1) {
        _log "<b>$paseprj</b>: Error durante la ejecuciÃ³n del script de precompilaciÃ³n (RC=$scriptRC) ", $scriptRET;    # ERROR
        _throw "Error durante la precompilaciÃ³n IAS de <b>$paseprj</b>.";
      }
      elsif ($scriptRC eq 1) {
        _log "<b>$paseprj</b>: Script de precompilaciÃ³n terminado con Ã©xito, pero con warnings detectados (RC=$scriptRC) ", $scriptRET;    # WARN
      }
      else {
        _log "<b>$paseprj</b>: script de precompilaciÃ³n terminado con Ã©xito (RC=$scriptRC)", $scriptRET; # INFO
      }
    }
    else {
      _log "<b>$paseprj</b>: inicio precompilaciÃ³n IAS.";   # INFO
      my $base        = "$eclipseDir/$PRE{$paseprj}{pde}";
      my $eclipseHome = "$base";         ## la version padre
      my $linkDir     = "$base/links";
      my $linkFile    = "$linkDir/${featureIAS}.link";
      my $iasDir      = "$staDir/$PRE{$paseprj}{iasDir}";
      $iasDir =~ s{\\}{\/}g;
      my $buildDir = "$destpasedir/$paseprj";
      $buildDir =~ s{\\}{\/}g;
      my $buildFile = "$buildDir/buildSCM.xml";
      my $configDir = "$buildDir";
      my $localLog  = "antRunner-${paseprj}.log";
      my $logFile   = "$buildDir\\$localLog";

      ## MODIFICO LINK PDE
      ($RC, $RET) = $harax->execute(qq{mkdir "$linkDir"});
      if ($RC ne 0) {
        _log "<b>$paseprj</b>: no he podido crear el directorio de link $linkDir (puede que existiera) RC=$RC: $RET";    # DEBUG
      }
      else {
        _log "<b>$paseprj</b>: creado directorio de link $linkDir: $RET";    # INFO
      }
      ($RC, $RET) = $harax->execute(qq{echo path=$iasDir > "$linkFile"});
      if ($RC ne 0) {
        _log "<b>$paseprj</b>: error al crear el fichero de link al PDE $linkFile (path=$iasDir) RC=$RC: $RET";  # ERROR
        _throw "Error durante la preparaciÃ³n para precompilar $paseprj";
      }
      else {
        _log "<b>$paseprj</b>: creado fichero de link al PDE $linkFile (path=$iasDir): $RET";  # DEBUG
      }

      # Borrado de cachÃ©
      # Parece que la Ãºnica forma de que eclipse olvide links utilizados anteriormente a otras
      # versiones de la feature es forzar el borrado del directorio /configuration/org.eclipse/update
      # el semÃ¡foro deberÃ­a garantizar que no se borra un eclipse que estÃ¡ siendo utilizado por otro
      # pase.
      my $cmdDel = qq|del /Q /S /F "${eclipseHome}\\configuration\\org.eclipse.update"|;
      _log "<b>$paseprj</b>: limpieza de la cachÃ© de plugins de eclipse", $cmdDel;    # DEBUG
      my ($delRC, $delRET) = $harax->execute($cmdDel);
      if ($delRC ne 0) {
        _log "<b>$paseprj</b>: No se pudo borrar la cachÃ© de plugins de eclipse. PodrÃ­a compilarse con la versiÃ³n incorrecta de entorno de desarrollo IAS (RC=$delRC) ", $delRET;    # WARN
      }
      else {
        _log "<b>$paseprj</b>: cachÃ© de plugins borrada con Ã©xito. (RC=$delRC)", $delRET;    # DEBUG
      }

      ## ANTRUNNER
      ##my $cmd = qq{${javaHome}\\bin\\java -jar ${eclipseHome}/startup.jar -application org.eclipse.ant.core.antRunner -buildfile $buildFile -Dbuilder=$configDir -DbaseLocation="${base}" -DbuildDirectory="$buildDir" 2>&1 };
      ## Pasamos tambiÃ©n -clean para mayor seguridad
      my $cmd = qq|cd /D "$destpasedir" & ${javaHome}\\bin\\java $sta_eclipse_java_vmparams -jar "${eclipseHome}/startup.jar" -clean -application org.eclipse.ant.core.antRunner -buildfile "$buildFile"|;
      _log "<b>$paseprj</b>: inicio del <b>antRunner</b>. Espere...", $cmd;                                                                                                             # INFO
      my ($antRC, $antRET) = $harax->execute($cmd);
      if ($antRC ne 0) {
        _log "<b>$paseprj</b>: Error durante la ejecuciÃ³n de <b>antRunner</b> (RC=$antRC) ", $antRET;  # ERROR
        _throw "Error durante la precompilaciÃ³n IAS de <b>$paseprj</b>.";
      }
      else {
        _log "<b>$paseprj</b>: <b>antRunner</b> terminado con Ã©xito (RC=$antRC)", $antRET;  # INFO
      }
    }
## JRL - 20080627 - Si cerramos aquÃ­ harax, a la vuelta del bucle esta cerrada la conexiÃ³n, no da error y bloquea el pase.
##      $harax->end();

  }

  ## RECUPERACIÃ“N DEL TAR DE TODO LOS PROYECTOS
  if (keys %PRE) {
    ## TAR
    my $destpasetardir = "${stadir}\\${Pase}\\$CAM";
    (my $tar_file = "${Pase}-$EnvironmentName-PRECOMP.tar") =~ s{\s+}{_}g;  ## harax->getfile no soporta espacios en nombre de fich
    _log "<b>PrecompilaciÃ³n IAS</b>: inicio del TAR de ficheros generados ($destpasetardir\\$tar_file). Espere..."; # INFO
    ($RC, $RET) = $harax->execute(qq{cd /D "$destpasedir" & $stawintarexe --mode=770 -cvf "..\\$tar_file" *});
    if ($RC ne 0) {
      _log "<b>PrecompilaciÃ³n IAS</b>: error al crear el TAR con los resultados de la precompilaciÃ³n ($destpasedir) RC=$RC", $RET; # ERROR
      _throw "Error durante la recuperaciÃ³n de los generados en la PrecompilaciÃ³n IAS";
    }
    else {
      _log "<b>PrecompilaciÃ³n IAS</b>: Ok TAR con los resultados de la precompilaciÃ³n ($destpasedir) RC=$RC", $RET; # INFO
    }

    ## RECUPERACION
    my $tarWinFilePath = "$destpasetardir\\$tar_file";
    $tarWinFilePath =~ s{\/}{\\}g;
    _log "<b>PrecompilaciÃ³n IAS</b>: recuperando TAR de ficheros generados en Staging ($destpasedir/$tar_file). Espere...";   # INFO
    ($RC, $RET) = $harax->getFile($tarWinFilePath, "$rootdir/$tar_file", "win");
    if ($RC ne 0) {
      _log "Error al recuperar TAR $tarWinFilePath a $rootdir/$tar_file (RC=$RC)", $RET;   # ERROR
      _throw "eclipseDist: error al recuperar tar de generados IAS para la PrecompilaciÃ³n IAS";
    }
    else {
      _log "Recuperado fichero $tarWinFilePath a $rootdir/$tar_file (RC=$RC)", $RET;     # INFO
    }

    ## UNTAR
    my @RET = `cd "$rootdir" ; $gnutar xvf "$tar_file" 2>&1`;
    if ($? ne 0) {
      _log "Error durante el UNTAR de $rootdir/$tar_file (RC=$?)", "@RET";      # ERROR
      _throw "eclipseDist: error al recuperar tar de generados IAS.";
    }
    else {
      _log "UNTAR $rootdir/$tar_file en $rootdir (RC=$?)", "@RET";     # DEBUG
    }

    ## BORRADO TAR WINDOWS
    ($RC, $RET) = $harax->execute(qq{del /Q /S /F "$destpasetardir\\$tar_file"});

  }

## JRL - 20080627 - Movemos aquÃ­ el cierre de la conexiÃ³n
  $harax->end();

  return (\@generados, \@dirpase);
}

## JDJ - 20091112
## Variable de distribuidor "STA_IAS_PRECOMP_USE" permite activar/desactivar
## el uso del script por entorno.
sub scriptPrecompIAS {
  my $self = shift;
  my $Entorno = shift;
  my $sta_ias_precomp_use = $self->conf->{sta_ias_precomp_use};
  return 1 if $sta_ias_precomp_use eq "1";
  return ($sta_ias_precomp_use =~ m{$Entorno}i);
}

sub putFeatVersionToPlugManifest {
  my $self = shift;
  my ($ver, $feat, $id, $plugHome, $ref_logtxt) = @_;

  #logdebug "putFeatVersionToPlugManifest: ver=$ver, feat=$feat, id=$id, plugHome=$plugHome, logtxt=$ref_logtxt";
  # Abro el MANIFEST.MF y le cambio la version
  my $manifestFile = "$plugHome/$id/META-INF/MANIFEST.MF";

  if (!open(MF, "<$manifestFile")) {
    _log "<b>$feat</b>: ERROR: no se ha podido abrir $manifestFile para normalizar: $!. ";    # WARN
  }
  else {

    #Se busca la entrada Bundle-Version dentro del MANIFEST.MF
    my $mf;
    $mf .= $_ foreach (<MF>);
    close MF;
    if ($mf =~ /Bundle-Version(.*?)/sg) {

      # MANIFEST.MF contiene la entrada  Bundle-Version;
      #logdebug "MANIFEST.MF antes de modificar la version=$mf";
      $mf =~ s/Bundle-Version: (.*)/Bundle-Version: $ver/g;  # OK, sustituye bien. Probar la diferencia con la siguiente.
      my $oldver = $1;
      ${$ref_logtxt} .= "PLUGIN_VERSION EN MANIFEST=$oldver, REQUIRED_PLUGIN_VERSION=$ver\n";

      #logdebug "MANIFEST.MF con la versiÃ³n sustituida =$mf";
      open(MF, ">$manifestFile ") or die "ERROR: no se ha podido abrir $manifestFile  para escritura: $!";
      print MF $mf;
      close MF;
      ${$ref_logtxt} .= ">>>>>>  MANIFEST  DE PLUGIN cambiado $id a '$ver'\n\n";

      #logdebug "contenido de ref_logtxt  antes de salir de putFeatVersionToPlugManifest = ${$ref_logtxt} ";
    }
    else {
      _log "No existe la entrada <b>Bundle-Version</b> en el archivo $manifestFile";    # WARN
    }
  }
}

1;

