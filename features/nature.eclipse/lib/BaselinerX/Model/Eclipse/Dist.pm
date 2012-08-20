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

has 'log',  is => 'ro', isa => 'Object',  required   => 1;
has 'pase', is => 'ro', isa => 'Str',     required   => 1;
has 'conf', is => 'rw', isa => 'HashRef', lazy_build => 1;

my $balix_pool = BaselinerX::Dist::Utils::BalixPool->new;

sub _build_conf { config_get('config.bde') }

sub eclipseDist
{
    my $self = shift;
    my $log  = $self->log;
    my $conf = $self->conf;
    my $id;
    my $pde;
    my $version;
    my $Pase     = $self->pase;
    my %Elements = %{shift @_};
    my ($PaseDir, $EnvironmentName, $Entorno, $Sufijo, $release, @tipos) = @_;
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);
    my $rootdir      = "$PaseDir/$CAM/$Sufijo";
    my %FEAT         = ();                        ## listado de features afectadas por este pase
    my $configFolder = "configuration";

    my $sta_eclipse_pase = $conf->{sta_eclipse_pase};
    _log "sta_eclipse_pase: $sta_eclipse_pase";

    my $gnutar = $conf->{gnutar};
    _log "gnutar: $gnutar";

    my $stawindir                 = $conf->{stawindir}                 || _log "stawindir VACIO";
    my $sta_eclipse_maq           = $conf->{sta_eclipse_maq}           || _log "sta_eclipse_maq VACIO";
    my $stawinport                = $conf->{stawinport}                || _log "stawinport VACIO";
    my $stawin                    = $conf->{stawin}                    || _log "stawin VACIO";
    my $stawintarexe              = $conf->{stawintarexe}              || _log "stawintarexe VACIO";
    my $stawinchgperm             = $conf->{stawinchgperm}             || _log "stawinchgperm VACIO";
    my $sta_eclipse_java_vmparams = $conf->{sta_eclipse_java_vmparams} || _log "sta_eclipse_java_vmparams VACIO";
    my $sta_eclipse_anthome       = $conf->{sta_eclipse_anthome}       || _log "sta_eclipse_anthome VACIO";
    my $sta_eclipse_staging       = $conf->{sta_eclipse_staging}       || _log "sta_eclipse_staging VACIO";
    my $apl_publico               = $conf->{apl_publico}               || _log "apl_publico VACIO";
    my $state_publico             = $conf->{state_publico}             || _log "state_publico VACIO";

    my $entornoSem = $main::PaseNodist ? "SQA" : $Entorno;
    my $sta_eclipse_home = $conf->{sta_eclipse_home};
    _log "sta_eclipse_home: $sta_eclipse_home";
    my $eclipseDir = $conf->{"sta_eclipse_home_$entornoSem"} || $sta_eclipse_home;    ## dir dónde encuentro las versiones de eclipse instaladas (base, pde, etc.)
    my $sta_eclipse_version = $conf->{sta_eclipse_version};
    _log "sta_eclipse_version: $sta_eclipse_version";
    my $eclipseVersion        = $sta_eclipse_version;
    my $sta_eclipse_java_home = $conf->{sta_eclipse_java_home};
    _log "sta_eclipse_java_home: $sta_eclipse_java_home";
    my $javaHome                = $sta_eclipse_java_home;
    my $sta_eclipse_javacsource = $conf->{sta_eclipse_javacsource};
    _log "sta_eclipse_javacsource: $sta_eclipse_javacsource";
    my $javacSource             = $sta_eclipse_javacsource;
    my $sta_eclipse_javactarget = $conf->{sta_eclipse_javactarget};
    _log "sta_eclipse_javactarget: $sta_eclipse_javactarget";
    my $javacTarget = $sta_eclipse_javactarget;
    my $normRE      = 1;                          ## flag que controla si normalizamos por expresion regular o por XML-Smart
    ## busco las features afectadas
    my $featDir = "";
    chdir $rootdir;
    my ($RC, $RET, @RET);
    my $plugHome = "$PaseDir/$CAM/$Sufijo/plugins";

    foreach my $VersionId (keys %Elements)
    {
        my ($Element, $ElementName, $PackageName, $SystemName, $SubSystemName, $DSName, $ElementType, $ElementState, $ElementVersion, $ElementPriority, $ElementPath, $ElementID, $ParCompIni, $IID, $Project) = @{$Elements{$VersionId}};
        my $subapl = (split(/\//, $ElementPath))[3];
        if ($subapl =~ /feature/i)
        {
            $featDir = $subapl;    ## = "features", pero puede que esté en plural, o mayusculas...
            my $featName = (split(/\//, $ElementPath))[4];
            $FEAT{$featName}{featFile} = "$PaseDir/$CAM/$Sufijo/$featDir/$featName/feature.xml";
            print "Feature afectada: $FEAT{$featName}{featFile}\n";
        }
    }

    if (!%FEAT)
    {
        $log->warn("No se han encontrado features para compilar (versiones de feature.xml) en los paquetes del pase.");
        return;
    }

    ########################################################################################################
    #### PARSE
    ########################################################################################################

    foreach my $feat (keys %FEAT)
    {
        my $featFile = $FEAT{$feat}{featFile};
        $log->warn("No se han encontrado features para compilar (versiones de feature.xml) en los paquetes del pase.");
        print "EclipseDist: procesando feature $featFile\n";
        $log->info("EclipseDist: procesando feature $featFile");
        ## parse de campos del feature.xml...
        my $XML = XML::Smart->new($featFile);
        if ($XML)
        {
            ## Parse: ID feature
            $id = $XML->{feature}{id};
            ## Parse: Version feature
            $version = $XML->{feature}{version};
            ## Parse: Version PDE
            my $sta_eclipse_pase = $conf->{sta_eclipse_pase};
            _log "sta_eclipse_pase: $sta_eclipse_pase";
            $pde = $XML->{feature}{requires}{import}('plugin', 'eq', $sta_eclipse_pase)->{version};
            $log->debug("Información parseada de feature.xml: ID=<b>$id</b>, VERSION=<b>$version</b>, $sta_eclipse_pase=<b>$pde</b>");

            ## Normalizando versiones de plugin
            $log->debug("<b>$feat</b>: Normalizando versiones entre feature y plugins...");
            my @ids = $XML->{feature}{plugin}('[@]', 'id');
            my $logtxt = "";
            foreach my $id (@ids)
            {    ## bucle de todos los plugins requeridos por la feature
                $logtxt .= "ID=$id";
                my $ver = $XML->{feature}{plugin}('id', 'eq', $id)->{version};
                $logtxt .= ", VERSION  PLUGIN EN FEATURE=$ver\n";
                ## abro el plugin.xml y le cambio la version
                my $plugFile = "$plugHome/$id/plugin.xml";
                if ($normRE)
                {
                    if (!open(PF, "<$plugFile"))
                    {
                        $log->warn("<b>$feat</b>: ERROR: no he podido abrir $plugFile para normalizar: $!. Se procede a inspeccionar el MANIFEST.MF del plugin");
                        $self->putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
                    }
                    else
                    {
                        my $pf;
                        $pf .= $_ foreach (<PF>);
                        close PF;

                        # Busca la línea plugin en el fichero de plugin.xml.
                        if ($pf =~ /<plugin(.*?)>/sg)
                        {

                            # El archivo plugin.xml del plugin contine el elemento raíz.
                            my $tk = $1;
                            if ($tk =~ /version(.*?)/sg)
                            {

                                # El archivo plugin.xml contiene el atributo version.
                                $tk =~ s/version="(.*?)"/version="$ver"/g;    ## esto tiene todos los peligros que supone usar variables en las RE, pero es mejor que el XML::Smart
                                my $oldver = $1;

                                # oldver es correcto
                                $logtxt .= "PLUGIN_VERSION=$oldver, REQUIRED_PLUGIN_VERSION=$ver\n";
                                if ($oldver ne $ver)
                                {

                                    # version nueva es correcto.
                                    $pf =~ s/<plugin(.*?)>/<plugin${tk}>/gs;    ## mismo peligro que arriba
                                    open(PF, ">$plugFile") or die "ERROR: no he podido abrir $plugFile para escritura: $!";
                                    print PF $pf;
                                    close PF;
                                    $logtxt .= ">>>>>> PLUGIN cambiado $id a '$ver'\n\n";
                                }
                            }
                            else
                            {

                                # No existe el atributo version en el $plugFile. Explorando archivo MANIFEST.MF del plugin...;
                                $self->putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
                            }
                        }
                        else
                        {

                            # El archivo plugin.xml NO contiene el elemento raíz plugin por lo que se procesa el manifest.mf del plugin en lugar del plugin.xml.
                            $log->warn("<b>$pf</b>: ERROR: no existe el elemento raíz  /<plugin(.*?)>/sg en el archivo $plugFile: $!. Se procede a inspeccionar el MANIFEST.MF del plugin");
                            $self->putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
                        }
                    }
                }
                else
                {
                    $log->debug("No normalizado.");
                    my $XMLPLUG = XML::Smart->new($plugFile);
                    if (!$XMLPLUG)
                    {
                        $log->warn("<b>$feat</b>: ERROR: no he podido abrir el fichero $plugFile para normalizar: $!.Se procede a inspeccionar el MANIFEST.MF del plugin\n");
                        $self->putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
                    }
                    else
                    {
                        my $oldver = $XMLPLUG->{plugin}{version};

                        # Si no existe el atributo version en el plugin.xml se procesa el manifest.mf del plugin en lugar del plugin.xml.
                        if ($oldver eq -1)
                        {
                            $self->putFeatVersionToPlugManifest($ver, $feat, $id, $plugHome, \$logtxt);
                        }
                        else
                        {

                            # Ponemos en el archivo plugin.xml la versión del plugin indicada en la feature para este plugin.
                            $logtxt .= "PLUGIN_VERSION=$oldver, REQUIRED_PLUGIN_VERSION=$ver\n";
                            $XMLPLUG->{plugin}{version} = $ver;
                            $logtxt .= ">>>>>> PLUGIN $id cambiado a '$ver' (via XML::Smart)\n\n";
                            $XMLPLUG->save($plugFile);    ## esto guarda el fichero de manera un poco distinta al original, no me gusta
                        }
                    }
                }
            }
            if ($logtxt)
            {
                ## me hago un tar de todos los plugin.xml para garantizar que la siguiente feature no los machaque
                my $gnutar = $conf->{gnutar};
                _log "gnutar: $gnutar";
                my $RET = `cd "$PaseDir/$CAM/$Sufijo"; find . -name "plugin.xml" -exec $gnutar rvf plugins_${feat}.tar {} \\; 2>&1`;
                _throw "no se ha podido crear el fichero de plugins plugins_${feat}.tar (RC=$RC): $RET" if ($RC);
                ## me hago un tar de todos los MANIFEST.MF para garantizar que la siguiente feature no los machaque
                my $RET2 = `cd "$PaseDir/$CAM/$Sufijo"; find . -name "MANIFEST.MF" -exec $gnutar rvf manifest_${feat}.tar {} \\; 2>&1`;
                my $RC2  = "";
                _throw "no se ha podido crear el fichero dearchivos manifest manifest_${feat}.tar (RC=$RC2): $RET2" if ($RC2);
                $log->debug("<b>$feat</b>: fin de la normalización de plugins.", $logtxt . "\n" . "TAR DE PLUGINS\n" . $RET . "\n" . "TAR DE MANIFEST\n" . $RET2);
            }
            else
            {
                $log->info("<b>$feat</b>: no he encontrado plugins para normalizar.");
            }
        }

        if ((!$id) or (!$version) or (!$pde) or ($id eq "") or ($version eq "") or ($pde eq ""))
        {
            $log->error("<b>$feat</b>: falta alguna variable en el fichero feature.xml: ID=$id, VERSION=$version, $sta_eclipse_pase=$pde");
            _throw "Error al compilar feature $feat. Fichero feature.xml incompleto.";
        }

        $FEAT{$feat}{id}      = $id;
        $FEAT{$feat}{version} = $version;
        $FEAT{$feat}{pde}     = $pde;

        ## creo una carpeta de configuration para esta feature: configuration/<nombre_feature>
        my $configDir     = "$PaseDir/$CAM/$Sufijo/$configFolder/$eclipseVersion";
        my $featConfigDir = "$PaseDir/$CAM/$Sufijo/$configFolder/$feat";
        mkdir $featConfigDir;
        $log->debug("<b>$feat</b>: Copiando contenidos de configuración de la carpeta de config '$configDir' a '$featConfigDir'");
        @RET = `cp -R "$configDir"/* "$featConfigDir" 2>&1`;
        if ($? ne 0) { _throw "EclipseDist: no se ha podido generar la carpeta de configuración de la feature '$featConfigDir': @RET"; }

        ## Sustituye la versión de PDE en configuration/><nombre_feature>/build.properties por la version PDE de feature
        my $buildProp = "$featConfigDir/build.properties";
        my $pathBase  = "$eclipseDir/$pde";
        open(BUILD, "<$buildProp") or _throw "EclipseDist: No he podido abrir el fichero $buildProp: $!";
        my $NEWBUILD;
        foreach my $line (<BUILD>)
        {
            if ($line =~ /base\=\<path\/to\/parent\/of\/eclipse\>/)
            {
                $NEWBUILD .= "$sta_eclipse_pase base=$pathBase\n";
                print "EclipseDist: modificado $buildProp\n";

            }
            elsif ($line =~ /buildType\=(.*?)$/)
            {    ## una letra, como I, M, N, S ...
                $FEAT{$feat}{buildType} = $1;
                $NEWBUILD .= $line;
            }
            elsif ($line =~ /buildId\=(.*?)$/)
            {    ## nombre libre
                $FEAT{$feat}{buildId} = $1;
                $NEWBUILD .= $line;
            }
            elsif ($line =~ /buildLabel\=(.*?)$/)
            {    ## buildid.buildtype - directorio de output
                $FEAT{$feat}{buildLabel} = $1;
                $NEWBUILD .= $line;
            }
            else
            {
                $NEWBUILD .= $line;
            }
        }
        close BUILD;
        ## no hace falta guardar datos en build.properties, se utiliza -Dvar=
        ## pero seguiré manteniendo el fichero para que quede como documento del pase
        open BUILD, ">$buildProp";
        print BUILD $NEWBUILD;
        close BUILD;
        $log->info("<b>$feat</b>: Fichero <b>build.properties</b> modificado ($buildProp).", $NEWBUILD);

        ## Sustituye el id de feature en allElements.xml
        my $allElements = "$featConfigDir/allElements.xml";
        open(ALLE, "<$allElements") or _throw "EclipseDist: No he podido abrir el fichero $allElements: $!";
        my $NEWALLE;
        foreach my $line (<ALLE>)
        {
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
        my $unzip = qq(
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
        );
        print UNZIP $unzip;
        $log->debug("Fichero para descomprimir features creado.", $unzip);
        close UNZIP;

        ## ANT para comprimir log del antRunner (en staging)
        open ZIPLOG, ">$rootdir/ziplog.xml";
        my $ziplog = qq(
        <project name="zipLogAntRunner" default="main">
            <target name="main">
                <echo>Comprimiendo el fichero de log del antRunner '\${logFile}' a '\${logZipFile}'</echo>
                <zip destfile="\${logZipFile}">
                    <fileset dir="\${logDir}" includes="\${logFile}" />
                </zip>
            </target>
        </project>      
        );
        print ZIPLOG $ziplog;
        $log->debug("Fichero para comprimir el log del antRunner creado.", $ziplog);
        close ZIPLOG;

    }

    ########################################################################################################
    #### ENVIO
    ########################################################################################################

    ## Envío a Staging
    # GENERAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE
    my $tarfile = "$PaseDir/$CAM/$Sufijo/${Pase}-$EnvironmentName-$Sufijo.tar";
    $RET = `cd "$PaseDir/$CAM/$Sufijo";$gnutar -cvf "$tarfile" * 2>&1`;
    $log->debug("TAR '$tarfile' del directorio '$PaseDir/$CAM/$Sufijo' finalizado.", $RET);

    # PARAMETROS DEL SERVIDOR DE STAGING
    my ($stamaq, $stapuerto, $stadir) = ($sta_eclipse_maq, $stawinport, $stawindir);
    if (!$stamaq)
    {
        $stamaq = $stawin;
    }
    $log->debug("Abriendo conexión con agente en $stamaq:$stapuerto");

    # my $harax = Harax->open( $stamaq, $stapuerto, "win" );
    my $harax = $balix_pool->conn_port($stamaq, $stapuerto);
    if (!$harax)
    {
        $log->error("No he podido establecer conexión con el servidor de compilación $stamaq en el puerto $stapuerto");
        _throw "Error al establecer conexión con el servidor de compilación";
    }
    $log->debug("Conexión abierta con el cliente en $stamaq:$stapuerto");
    my $destpasedir = "${stadir}\\${Pase}\\$CAM\\$Sufijo";

    try
    {    # NO BORRAR, el siguiente código, llamada a la subrutina doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir) está probado y
            # funciona pero de momento prescindimos de hacer xcopy en el caso de distribuciones eclipse por razones de rendimiento
            # ya que no hay problemas con los permisos tal y como ocurre con las distribuciones net, rs y biztalk.
            #doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir);

        # ENVIAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE AL SERVIDOR DE STAGING
        $log->info("Enviando el TAR a Staging ($destpasedir\\${Pase}.tar). Espere...");
        my $desttarfile = "$destpasedir\\${Pase}.tar";
        ($RC, $RET) = $harax->sendFile($tarfile, $desttarfile);
        $log->info("Ok. TAR file en destino (RC=$RC)");

        # DESCOMPRIMIMOS EL FICHERO TAR EN EL STAGING
        my $cmd_dec = "cd /D \"$destpasedir\" & $stawintarexe pxvf ${Pase}.tar";
        _log "cmd descomprimir: $cmd_dec";
        ($RC, $RET) = $harax->execute("cd /D \"$destpasedir\" & $stawintarexe pxvf ${Pase}.tar");
        if ($RC ne 0)
        {
            $log->error("Error en al descomprimir el archivo TAR (RC=$RC)", $RET);
            _throw "Error durante la preparación de la aplicación.";
        }
        else
        {
            $log->info("UNTAR (RC=$RC)", $RET);
        }

        # BORRAMOS EL FICHERO TAR EN STAGING
        if ($RC eq 0)
        {
            _log "\n\n borrando fichero de staging... \n\n";
            ($RC, $RET) = $harax->execute("del \"$desttarfile\"");
        }

        ($RC, $RET) = $harax->execute("$stawinchgperm \"$destpasedir\"");
        if ($RC ne 0)
        {
            $log->error("Error  al asignar permisos de escritura a \"$destpasedir\" (RC=$RC) ", $RET);
            _throw "Error durante la preparación de la aplicación.";
        }
        else
        {
            $log->info("Cambiados los permisos del directorio $destpasedir (RC=$RC)", $RET);
        }
    }
    catch
    {
        _throw "Error al transferir ficheros al nodo $stamaq: " . shift();
    };

    ########################################################################################################
    #### CONSTRUCCION
    ########################################################################################################
    try
    {
        ## INVESTIGAMOS CUAL ES LA CARPETA DE BUILD DEL ECLIPSE
        my $eclipseHome = "$eclipseDir/$eclipseVersion";
        my $pdeBuildDir = "";
        $log->debug("Buscando directorio de pde.build en '$eclipseHome/plugins/'...");
        ($RC, $RET) = $harax->execute(qq{dir /b /n "$eclipseHome/plugins/"});
        if ($RC ne 0) { _throw "No se ha podido buscar el directorio de pde.build donde estaría el build.xml para el antRunner: $RET"; }
        else
        {
            $RET =~ s/\r//g;
            if ($RET =~ /org\.eclipse\.pde\.build_(.*?)\n/)
            {
                $pdeBuildDir = $1;
                if ($pdeBuildDir eq "")
                {
                    $log->error("No se ha encontrado un directorio org.eclipse.pde.build_* en $eclipseHome/plugins/", $RET);
                    _throw "Error durante la preparación para la construcción de feature/plugins.";
                }
                $pdeBuildDir = "org.eclipse.pde.build_" . $pdeBuildDir;
                $log->debug("Directorio org.eclipse.pde.build detectado: <b>$pdeBuildDir</b>", $RET);
            }
            else
            {
                $log->error("No se ha encontrado un directorio org.eclipse.pde.build_* en $eclipseHome/plugins/", $RET);
                _throw "Error durante la preparación para la construcción de feature/plugins.";
            }
        }
        my $buildFile = "$eclipseHome/plugins/$pdeBuildDir/scripts/build.xml";

        ## LANZAMOS EL BUILD PARA CADA FEATURE
        foreach my $feat (keys %FEAT)
        {
            my $buildDir   = "$destpasedir";
            my $configDir  = "$buildDir/$configFolder/$feat";
            my $base       = "$eclipseDir/$FEAT{$feat}{pde}";
            my $buildId    = "$FEAT{$feat}{version}";           ## utilizado en el nombre del fichero de salida
            my $buildLabel = "output-$feat";                    ## carpeta de salida
            my $localLog   = "antRunner-${feat}.log";
            my $logFile    = "$buildDir\\$localLog";
            $log->debug("<b>$feat</b>: base=$base");

            # Descomprimo tar de plugin.xml
            ($RC, $RET) = $harax->execute(qq{cd /D "$destpasedir" & $stawintarexe pxvf "plugins_${feat}.tar" 2>&1});
            $log->debug("<b>$feat</b>: untar de plugins (RC=$RC)", $RET);

            # Descomprimo tar de MANIFEST.MF
            ($RC, $RET) = $harax->execute(qq{cd /D "$destpasedir" & $stawintarexe pxvf "manifest_${feat}.tar" 2>&1});
            $log->debug("<b>$feat</b>: untar de MANIFEST (RC=$RC)", $RET);
            my $cmd = qq{cd /D "$destpasedir" & ${javaHome}\\bin\\java $sta_eclipse_java_vmparams -jar ${eclipseHome}/startup.jar -application org.eclipse.ant.core.antRunner -buildfile "$buildFile" -Dbuilder="$configDir" -DbaseLocation="${base}" -DbuildDirectory="$buildDir" -DarchivePrefix=" " -DbuildId="$buildId" -DbuildLabel="$buildLabel" -DtopLevelElementId="$feat" > "$logFile" 2>&1};
            $log->info("<b>$feat</b>: inicio del <b>antRunner</b>. Espere...", $cmd);
            my ($antRC, $antRET) = $harax->execute($cmd);
            $log->info("<b>$feat</b>: fin del <b>antRunner</b> (RC=$RC). Recuperando y publicando fichero de log $logFile. Espere...");
            ## ZIP del log
            ($RC, $RET) = $harax->execute(qq{set PATH=$javaHome\\bin;\%PATH\% & $sta_eclipse_anthome\\bin\\ant -f "$destpasedir\\ziplog.xml" -DlogFile="$localLog" -DlogZipFile="${logFile}.zip" -DlogDir="$destpasedir"});
            if ($RC ne 0)
            {
                $log->warn("<b>$feat</b>: No se ha podido comprimir el fichero $logFile => ${logFile}.zip en $stamaq. El log de antRunner no estará disponible.", $RET);
            }
            else
            {
                $log->debug("<b>$feat</b>: fichero de log de antRunner $logFile comprimido.", $RET);
                ## Recupero el log
                my ($aRC, $aRET) = $harax->getFile("${logFile}.zip", "$rootdir/${localLog}.zip", "win");

                # Existe algo tipo logfile???
                # logfile $rootdir, "${localLog}.zip", "<b>$feat</b>: log del antRunner.";
            }
            if ($antRC ne 0)
            {
                $log->error("<b>$feat</b>: Error durante la ejecución de <b>antRunner</b> (RC=$RC) ", $antRET);
                _throw "Error durante la construcción de la feature <b>$feat</b>.";
            }
            else
            {
                $log->info("<b>$feat</b>: <b>antRunner</b> terminado con éxito (RC=$RC)", $antRET);
            }
            $FEAT{$feat}{features}   = $buildDir . "/features";
            $FEAT{$feat}{plugins}    = $buildDir . "/plugins";
            $FEAT{$feat}{outputHome} = $buildDir . "/" . $buildLabel;
            $FEAT{$feat}{outputFile} = "$FEAT{$feat}{id}-$FEAT{$feat}{version}.zip";
            $FEAT{$feat}{configDir}  = $configDir;
        }
        ## SQA
        #       if ( $conf->{SQA_ACTIVO} || $PaseNodist  ) {
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
        #           } catch {
        #                   logwarn "Error durante la generación de SQA: " . shift;
        #           };
        #       }
        ## FIN SQA
    }
    catch
    {
        _throw "Error durante la construcción: " . shift();
    };

    ########################################################################################################
    #### SALIDA
    ########################################################################################################

    ## SQA
    unless ($main::PaseNodist)
    {
        foreach my $feat (keys %FEAT)
        {
            ## RECUPERAMOS EMPAQUETADOS
            my $fich = "$FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile}";
            $log->info("<b>$feat</b>: recuperando fichero de salida $fich");

            ## Creo la carpeta /staging/<id_feature>_<version_feature>/eclipse
            my $staFeat     = "$sta_eclipse_staging/$CAM/$FEAT{$feat}{id}_$FEAT{$feat}{version}/eclipse";
            my $staFeatures = "$staFeat/features";
            my $staPlugins  = "$staFeat/plugins";

            ## Creo carpeta y descomprimo contenido en Stagnig , solo si es pase a PROD.
            if ($Entorno eq "PROD")
            {

                ($RC, $RET) = $harax->execute(qq{mkdir "$staFeat"});
                if ($RC ne 0)
                {
                    $log->warn("<b>$feat</b>: No se ha podido crear la carpeta $staFeat en $stamaq (pueda que ya existiera). RC=$RC: $RET");
                    if ($RET =~ /already/i)
                    {
                        ($RC, $RET) = $harax->execute(qq{rmdir /S /Q "$staFeat" & mkdir "$staFeat"});
                        if ($RC ne 0)
                        {
                            $log->error("<b>$feat</b>: No se ha podido borrar la carpeta $staFeat para volver a crearla (RC=$RC)", $RET);
                            _throw "eclipseDist: error al crear la carpeta $staFeat";
                        }
                        else
                        {
                            $log->debug("<b>$feat</b>: se ha vaciado y vuelto a crear la carpeta $staFeat.", $RET);
                        }
                    }
                }
                else
                {
                    $log->debug("<b>$feat</b>: carpeta $staFeat creada.");
                }
            }
            my $tarFile = "$FEAT{$feat}{id}_$FEAT{$feat}{version}.tar";

            ## 1) Unzip a /staging (SOLO PROD)
            ## if( ($Entorno eq "PROD") or ( scm_entorno() ne 'PROD' ) ) {  # en vtscm y vascm lo hacemos para todos los entornos
            if ($Entorno eq "PROD")
            {    ## solo si el pase es para una version de PROD da igual en que broker. Cambio a peticion a raiz de la gdf 67506 .
                ($RC, $RET) = $harax->execute(qq{set PATH=$javaHome\\bin;\%PATH\% & $sta_eclipse_anthome\\bin\\ant -f "$destpasedir/unzip.xml" -DfeatFile="$FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile}" -DstaFeatDir="$staFeat" -DtarFile="$staFeat/$tarFile"});
                if ($RC ne 0)
                {
                    $log->error("<b>$feat</b>: No se ha podido descomprimir el fichero $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} => $staFeat en $stamaq", $RET) or _throw "eclipseDist: error al descomprimir la feature a $staFeat";
                }
                else
                {
                    $log->debug("<b>$feat</b>: descomprimido $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} en $staFeat.", $RET);
                }
            }

            # RECUPERAMOS EL ZIP CON EL RESULTADO DE LA PUBLICACIÓN
            my $origZipFile = "$FEAT{$feat}{outputHome}\\$FEAT{$feat}{outputFile}";
            $origZipFile =~ s/\//\\/g;
            $log->debug("<b>$feat</b>: Recuperando fichero ZIP $FEAT{$feat}{outputHome}\\$FEAT{$feat}{outputFile}. Espere...");
            ($RC, $RET) = $harax->getFile($origZipFile, "$rootdir/$FEAT{$feat}{outputFile}", "win");
            if ($RC ne 0)
            {
                $log->error("Error al recuperar fichero $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} a $rootdir/$FEAT{$feat}{outputFile} (RC=$RC)", $RET);
                _throw "eclipseDist: error al recuperar tar de feature $feat";
            }
            else
            {
                $log->debug("Recuperado fichero $FEAT{$feat}{outputHome}/$FEAT{$feat}{outputFile} a $rootdir/$FEAT{$feat}{outputFile} (RC=$RC)", $RET);
            }

            ## UNTAR LOCAL
            my $checkinHome = "$PaseDir/$CAM/$Sufijo/checkin";
            my $release     = "$FEAT{$feat}{id}-$FEAT{$feat}{version}";
            my $ViewPath    = "/$apl_publico/$CAM/$Sufijo/$Entorno";
            my $checkinDir  = "$checkinHome/$release";
            `mkdir -p "$checkinDir" 2>&1`;
            @RET = `cd $checkinDir ; mv $rootdir/$FEAT{$feat}{outputFile} . 2>&1`;
            if ($? ne 0)
            {
                $log->error("<b>$feat</b>: Error durante el move del fichero de feature $tarFile para checkin a $apl_publico.", "@RET");
                _throw "Error durante el checkin a PUBLICO de la feature $feat";
            }
            else
            {
                $log->debug("<b>$feat</b>: ZIP movido a $checkinDir para checkin a $apl_publico.", "@RET");
            }

            ## CHECKIN a la aplicación PUBLICO
            $log->info("<b>$feat</b>: inicio checkin a la aplicación $apl_publico. Espere...");
            checkinPublico(
                           path     => $checkinHome,
                           entorno  => $Entorno,
                           viewpath => $ViewPath,
                           project  => $apl_publico,
                           state    => $state_publico,
                           release  => $release,
                           desc     => "Creado por el pase $Pase"
                          );
        }
    }
    else
    {
        $log->info("Pase sin distribución finalizado");
    }    ## si no hay distribución
    ########################################################################################################
    #### PUBLICACION
    ########################################################################################################

    $balix_pool->purge;

    ## FIN

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

sub generaProyectoPase
{
    my $self                      = shift;
    my $log                       = $self->log;
    my $Pase                      = $self->pase;
    my $conf                      = $self->conf;
    my $sta_eclipse_home          = $conf->{sta_eclipse_home} || _log "sta_eclipse_home VACIO";
    my $sta_eclipse_staging       = $conf->{sta_eclipse_staging} || _log "sta_eclipse_staging VACIO";
    my $sta_eclipse_version       = $conf->{sta_eclipse_version} || _log "sta_eclipse_version VACIO";
    my $sta_eclipse_java_home     = $conf->{sta_eclipse_java_home} || _log "sta_eclipse_java_home VACIO";
    my $sta_eclipse_ias_feature   = $conf->{sta_eclipse_ias_feature} || _log "sta_eclipse_ias_feature VACIO";
    my $sta_eclipse_java_vmparams = $conf->{sta_eclipse_java_vmparams} || _log "sta_eclipse_java_vmparams VACIO";
    my $sta_eclipse_maq           = $conf->{sta_eclipse_maq} || _log "sta_eclipse_maq VACIO";
    my $stawinport                = $conf->{stawinport} || _log "stawinport VACIO";
    my $stawindir                 = $conf->{stawindir} || _log "stawindir VACIO";
    my $stawin                    = $conf->{stawin} || _log "stawin VACIO";
    my $sta_eclipse_clase         = $conf->{sta_eclipse_clase} || _log "sta_eclipse_clase VACIO";
    my $sta_eclipse_pase          = $conf->{sta_eclipse_pase} || "sta_eclipse_pase VACIO";
    my $sta_eclipse_vmetricas     = $conf->{sta_eclipse_vmetricas} || "sta_eclipse_vmetricas VACIO";
    my $gnutar                    = $conf->{gnutar} || "gnutar VACIO";
    _log "\n\n******************\ngnutar: $gnutar \n**********\n\n";
    my $stawintarexe        = $conf->{stawintarexe}        || "stawintarexe VACIO";
    my $stawinchgperm       = $conf->{stawinchgperm}       || "stawinchgperm VACIO";
    my $sta_ias_precomp_jar = $conf->{sta_ias_precomp_jar} || "sta_ias_precomp_jar VACIO";

    my %Elements = %{shift @_};
    my ($PaseDir, $EnvironmentName, $Entorno, $Sufijo, $release, @tipos) = @_;
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);
    my $rootdir = "$PaseDir/$CAM/$Sufijo";
    my (@generados, @dirpase) = ();    ## variables de retorno para indicar cuales proyectos son generados, y cuales tienen dir de pase _SCM
    my $configFolder        = "configuration";
    my $entornoSem          = $main::PaseNodist ? "SQA" : $Entorno;
    my $eclipseDir          = $conf->{"sta_eclipse_home_$entornoSem"} || $sta_eclipse_home;    ## dir dónde encuentro las versiones de eclipse instaladas (base, pde, etc.)
    my $staDir              = "$sta_eclipse_staging/IAS";                                      ## dir en staging donde están las features de IAS E:/APSDAT/STAGING/PUBLICO/IAS
    my $eclipseVersion      = $sta_eclipse_version;
    my $javaHome            = $sta_eclipse_java_home;                                          ##$javaHome=~ s{\/}{\\}g;
    my $featureIAS          = $sta_eclipse_ias_feature;
    my $useScriptPrecompIAS = $self->scriptPrecompIAS($Entorno);                               ## si se debe usar el script de precompilación ias

    $sta_eclipse_java_vmparams = $sta_eclipse_java_vmparams;

    _log "\n\n generaProyectoPase: got all vars needed\n\n";

    ## Un fichero APLICACION.AP o APLICACION.BATCH- indica si se preprocesa IAS o no
    my %PRJS = _projects_from_elements(\%Elements, $EnvironmentName);                          ##quiero saber los proyectos web afectados
    my @PROYECTOS = keys %PRJS;

    _log "\n\n generaProyectoPase: buscando proyectos...\n\n";

    # buscar proyectos ear para los proyectos afectados
    my ($Workspace, @WARS);
    try
    {
        $Workspace = BaselinerX::Eclipse::J2EE->parse(workspace => $rootdir);
        $Workspace->cutToSubset($Workspace->getRelatedProjects(@PROYECTOS));
        @WARS = $Workspace->getWebProjects();
    }
    catch
    {
        my $err_msg = shift();
        _log "\n\n error al parsear!\n$err_msg \n\n";
        $log->error("Fallo al intentar parsear.", $err_msg);
        _throw $err_msg;
    };

    _log "\n\n generaProyectoPase: buscando JARS...\n\n";

    ## Java JARs
    my $WorkspaceJava = BaselinerX::Eclipse::J2EE->parse(workspace => $rootdir);
    $WorkspaceJava->cutToSubset(@PROYECTOS);
    my @JARS = $WorkspaceJava->getProjects();

    _log "\n\n generaProyectoPase: dump de JARS: " . Data::Dumper::Dumper \@JARS;

    $log->info("Proyectos WEB identificados para la precompilación IAS: \n" . join ',',        @WARS);
    $log->info("Proyectos Java (JAR) identificados para la precompilación IAS: \n" . join ',', @JARS);

    $log->debug("Proyecto(s) J2EE Identificado(s) para la precompilación: \n" . join("\n", @PROYECTOS));
    my %PRE = ();

    _log "\n\n generaProyectoPase: entrando en bucle \n\n";

    foreach my $paseprj (@WARS, @JARS, @PROYECTOS)
    {
        my @ap = `find "$rootdir/${paseprj}" -name "aplicacion.ap" -o -name "aplicacion.batch" -o -name "aplicacion.aptest" -o -name "aplicacion.aplib"`;
        if (!@ap or ($? ne 0))
        {
            $log->warn("<b>$paseprj</b>: no se han encontrado ficheros aplicacion.ap, aplicacion.aptest o aplicacion.batch. No se precompilará el proyecto.", "$!\n@ap");
            push @dirpase, $paseprj;
        }
        else
        {
            if ($useScriptPrecompIAS)
            {
                ## con script de precompilación, no se mira la versión
                $PRE{$paseprj}{versionIAS} = 1;
            }
            else
            {
                my $apFile = shift @ap;    ## cojo el primer aplicacion.* solamente
                chop $apFile;
                $log->debug("<b>$paseprj</b>: abro el fichero $apFile para parsear...");
                my $XML = XML::Smart->new($apFile);
                my $version;
                if ($XML)
                {
                    ## Parse: Version IAS
                    $version = $XML->{aplicacion}{configuracionProyecto}{versionEntornoDesarrollo};
                    if ($version)
                    {
                        $PRE{$paseprj}{versionIAS} = $version;
                        $log->info("<b>$paseprj</b>: version de la arquitectura de desarrollo IAS detectada '$version' (en $apFile)");
                    }
                    else
                    {
                        $log->warn("<b>$paseprj</b>: no se ha detectado version de la arquitectura de desarrollo IAS en $apFile. No se realizará la precompilación.");
                    }
                }
                else
                {
                    $log->warn("<b>$paseprj</b>: error al intentar parsear el xml de $apFile. No se realizará la precompilación");
                }
            }
        }
    }
    if (!(keys %PRE))
    {    ## si no hay nada que precompilar, me voy
        $log->warn("No hay proyectos IAS para precompilar. Se utilizarán los proyectos de pase que estén disponibles.");
        return (\@generados, \@dirpase);
    }

    # PARAMETROS DEL SERVIDOR DE STAGING
    my ($stamaq, $stapuerto, $stadir) = ($sta_eclipse_maq, $stawinport, $stawindir);
    if (!$stamaq)
    {
        $stamaq = $stawin;
    }
    $log->debug("Abriendo conexión con agente en $stamaq:$stapuerto");

    # my $harax = Harax->open( $stamaq, $stapuerto, "win" );
    my $harax = $balix_pool->conn_port($stamaq, $stapuerto);
    if (!$harax)
    {
        $log->error("No he podido establecer conexión con el servidor de compilación $stamaq en el puerto $stapuerto");
        _throw "Error al establecer conexión con el servidor de compilación";
    }
    $log->debug("Conexión abierta con el cliente en $stamaq:$stapuerto");
    my $destpasedir = "${stadir}\\${Pase}\\$CAM\\$Sufijo";

    my ($RC, $RET);
    if (!$useScriptPrecompIAS)
    {
        ## VERSIONES de IAS en STAGING
        $log->debug("Compruebo las versiones de la arquitectura de desarrollo IAS ($featureIAS) en Staging ($staDir)...");
        ($RC, $RET) = $harax->execute(qq{dir /b /n "$staDir" });
        if ($RC ne 0)
        {
            $log->error("No se ha podido comprobar las versiones de la arquitectura de desarrollo IAS disponibles en Staging $stamaq:$staDir (RC=$RC)", $RET);
            _throw "Error al intentar comprobar versiones de la arquitectura de desarrollo de IAS en Staging.";
        }
        $RET =~ s/\r//g;
        my $DIR = $RET;
        my @VERS = split /\n/, $RET;

        ## COMPRUEBO que existe la version de IAS para el proyecto en Staging
        foreach my $paseprj (keys %PRE)
        {
            $log->debug("<b>$paseprj</b>: verifico si la versión de la arquitectura de desarrollo IAS está en staging: $PRE{$paseprj}{versionIAS}");
            my ($iasDir) = grep(/\_$PRE{$paseprj}{versionIAS}$/, @VERS);
            if ($iasDir =~ /$featureIAS/)
            {
                $log->debug("<b>$paseprj</b>: Ok, version <b>$PRE{$paseprj}{versionIAS}</b> de la arquitectura de desarrollo IAS disponible en $stamaq:$staDir/$iasDir", $DIR);
                push @generados, $paseprj;
            }
            else
            {
                $log->warn("<b>$paseprj</b>: version <b>$PRE{$paseprj}{versionIAS}</b>  de la arquitectura de desarollo IAS no está disponible en $stamaq:$staDir. Precompilación ignorada para este proyecto.", $DIR);
                push @dirpase, $paseprj;
                delete $PRE{$paseprj};
                next;
            }
            $PRE{$paseprj}{iasDir} = $iasDir;

            ## VERSION DE PDE para cada IAS
            my $iasDirFeat = "$staDir\\$iasDir\\eclipse\\features\\$iasDir\\feature.xml";
            $log->debug("Investigo versión de Eclipse para feature $iasDir...");
            ($RC, $RET) = $harax->execute(qq{type "$iasDirFeat"});
            if ($RC ne 0)
            {
                $log->error("<b>$paseprj</b>: no he podido abrir el fichero feature.xml para parsear la versión de Eclipse ($staDir\\$iasDir\\eclipse\\features\\$iasDir\\feature.xml) RC=$RC", $RET);
                _throw "Error al comprobar la versión de Eclipse en Staging.";
            }
            my $XML = XML::Smart->new($RET);
            my ($id, $version, $pde) = ();
            if ($XML)
            {
                ## Parse: ID feature
                $id = $XML->{feature}{id};
                ## Parse: Version feature
                $version = $XML->{feature}{version};
                ## Parse: Version PDE
                $pde = $XML->{feature}{requires}{import}('plugin', 'eq', $sta_eclipse_pase)->{version};
                if (!$pde)
                {
                    $log->error("<b>$paseprj</b>: No he podido comprobar la versión de Eclipse en el fichero feature.xml para la feature $iasDir ($iasDirFeat): $!");
                    _throw "Error al comprobar la versión de Eclipse en Staging.";
                }
                else
                {
                    $log->debug("<b>$paseprj</b>: Detectada versión de Eclipse (plugin $sta_eclipse_clase): <b>$pde</b>, en el fichero feature.xml para la feature $iasDir ($iasDirFeat): $!");
                    $PRE{$paseprj}{pde} = $pde;
                }
            }
            else
            {
                $log->error("<b>$paseprj</b>: No se ha podido leer el fichero feature.xml para la feature $iasDir ($iasDirFeat): $!");
                _throw "Error al comprobar la versión de Eclipse en Staging.";
            }

            ## BUILD.XML
            my $location = "$destpasedir/$paseprj";
            $location =~ s{\\}{\/}g;
            my $build = qq{
<project name="project" default="default">
   <description>Precompilacion de $paseprj, IAS=$PRE{$paseprj}{iasDir}, PDE=$PRE{$paseprj}{pde}</description> 
   <target name="default">
     <ias.build projectLocation="$location"
          projectName="$paseprj" 
          environment="$Entorno" /> 
    </target>
</project>  
             };
            $log->info("<b>$paseprj</b>: precompilación IAS: buildSCM.xml", $build);
            my $buildFile = "$rootdir/$paseprj/buildSCM.xml";
            if (-e $buildFile)
            {
                $log->warn("<b>$paseprj</b>: existe el fichero $buildFile. Se sobrescribirá.");
            }
            open BB, ">$buildFile" or do
            {
                $log->error("<b>$paseprj</b>: Error al intentar crear el fichero build.xml: $!");
                _throw "Error en la preparación de la precompilación IAS.";
            };
            print BB $build;
            close BB;
        }
    }
    else
    {
        ## Generamos el ias-precomp.properties para el script de precompilación
        ## (datos de entrada al script)
        foreach my $paseprj (keys %PRE)
        {
            ## ias-precomp.properties:
            push @generados, $paseprj;
            my $base        = "$eclipseDir/$PRE{$paseprj}{pde}";
            my $eclipseHome = "$base";                             ## la version padre
            my $location    = "$destpasedir/$paseprj";
            $location =~ s{\\}{\/}g;
            my $properties = qq{
                # Directorio donde están las versiones de eclipse
                EclipsesDir=${eclipseHome}
                # Directorio donde están las features de IAS
                FeaturesDir=$staDir
                # Directorio donde está el proyecto a precompilar
                ProjectDir=$location
                # Entorno (TEST/ANTE/PROD)
                Environment=$Entorno
                # Localización de la máquina virtual (se utilizará cuando la versión de eclipse no tenga
                # una JDK dentro)
                JavaHome=${javaHome}
                # Cambio para SQA. Versión del generador de métricas
                VMetricas=$sta_eclipse_vmetricas
            };
            $log->info("<b>$paseprj</b>: precompilación IAS: ias-precomp.properties", $properties);
            my $propertiesFile = "$rootdir/$paseprj/ias-precomp.properties";

            if (-e $propertiesFile)
            {
                $log->warn("<b>$paseprj</b>: existe el fichero $propertiesFile. Se sobrescribirá.");
            }
            open BB, ">$propertiesFile" or do
            {
                $log->error("<b>$paseprj</b>: Error al intentar crear el fichero ias-precomp.properties: $!");
                _throw "Error en la preparación de la precompilación IAS.";
            };
            print BB $properties;
            close BB;
        }
    }
    my $tarfile = "$PaseDir/$CAM/$Sufijo/${Pase}-$EnvironmentName-$Sufijo.tar";
    if (@generados)
    {

        # GENERAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE
        #TODO: podríamos mandar sólo el TAR de los _WEB con aplicacion.ap, pero no estoy seguro de que esto sea lo único que se necesita para compilar
        #(Juan Domínguez) -> Nope: hay que enviar todos los proyectos en el TAR porque la precompilación utiliza a veces jars del _EAR
        #y genera a veces ficheros en el _EJB.
        do
        {
            my $cmd = "cd \"$PaseDir/$CAM/$Sufijo\"; $gnutar -cvf \"$tarfile\" * 2>&1";
            my @RET = `$cmd`;
            if ($? ne 0)
            {
                $log->error("Error al realizar el TAR para envío a staging: RC=$?", "@RET");
                _throw "Error en la preparación de la precompilación IAS.";
            }
            else
            {
                $log->debug("TAR '$tarfile' del directorio '$PaseDir/$CAM/$Sufijo' finalizado.", $RET);
            }
        };

        try
        {

            # NO BORRAR, el siguiente código, llamada a la subrutina doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir) está probado y
            # funciona pero de momento prescindimos de hacer xcopy en el caso de distribuciones eclipse por razones de rendimiento
            # ya que no hay problemas con los permisos tal y como ocurre con las distribuciones net, rs y biztalk.
            #doUntarAndRestorePermission($Pase,$harax,$tarfile,$destpasedir);

            # ENVIAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE AL SERVIDOR DE STAGING
            $log->info("Enviando el TAR a Staging ($destpasedir\\${Pase}.tar). Espere...");
            my $desttarfile = "$destpasedir\\${Pase}.tar";
            ($RC, $RET) = $harax->sendFile($tarfile, $desttarfile);
            $log->debug("Ok. TAR file en destino (RC=$RC)");

            # DESCOMPRIMIMOS EL FICHERO TAR EN EL STAGING
            _log "\n\n descomprimimos fichero tar en staging: \n cmd: cd /D \"$destpasedir\" & $stawintarexe pxvf ${Pase}.tar\n\n";
            ($RC, $RET) = $harax->execute("cd /D \"$destpasedir\" & $stawintarexe pxvf ${Pase}.tar");
            if ($RC ne 0)
            {
                _log "error al descomprimir \n\n$RET";
                $log->error("Error en al descomprimir el archivo TAR (RC=$RC)", $RET);
                _throw "Error durante la preparación de la aplicación.";
            }
            else
            {
                $log->debug("UNTAR (RC=$RC)", $RET);
            }

            # BORRAMOS EL FICHERO TAR EN STAGING
            if ($RC eq 0)
            {
                ($RC, $RET) = $harax->execute("del \"$desttarfile\"");
            }

            # PONEMOS PERMISOS A LOS FICHEROS
            my $cmd_permisos = $stawinchgperm . " \"$destpasedir\"";
            _log " \n\n permisos a los ficheros cmd: $cmd_permisos \n\n";
            ($RC, $RET) = $harax->execute($stawinchgperm . " \"$destpasedir\"");
            if ($RC ne 0)
            {
                $log->error("Error  al asignar permisos de escritura a \"$destpasedir\" (RC=$RC) ", $RET);
                _throw "Error durante la preparación de la aplicación.";
            }
            else
            {
                $log->debug("Cambiados los permisos del directorio $destpasedir (RC=$RC)", $RET);
            }
        }
        catch
        {
            _throw "Error al transferir ficheros al nodo $stamaq: " . shift();
        };
    }

    ## CONSTRUCCION
    foreach my $paseprj (keys %PRE)
    {
        if ($useScriptPrecompIAS)
        {
            ## Llamada al script de precompilación.
            $log->info("<b>$paseprj</b>: inicio script precompilación IAS.");
            my $buildDir = "$destpasedir/$paseprj";
            $buildDir =~ s{\\}{\/}g;
            my $propertiesFile            = "$buildDir/ias-precomp.properties";
            my $sta_eclipse_java_vmparams = $sta_eclipse_java_vmparams;
            my $sta_ias_precomp_jar       = $sta_ias_precomp_jar;
            my $cmd                       = qq{cd /D "$destpasedir" & ${javaHome}\\bin\\java $sta_eclipse_java_vmparams -jar "$sta_ias_precomp_jar" "$propertiesFile"};
            $log->info("<b>$paseprj</b>: inicio del script. Espere...", $cmd);
            _log "\n\ninicio del scripl. espere... \n cmd: $cmd";
            my ($scriptRC, $scriptRET) = $harax->execute($cmd);

            if ($scriptRC > 1)
            {
                $log->error("<b>$paseprj</b>: Error durante la ejecución del script de precompilación (RC=$scriptRC) ", $scriptRET);
                _throw "Error durante la precompilación IAS de <b>$paseprj</b>.";
            }
            elsif ($scriptRC eq 1)
            {
                $log->warn("<b>$paseprj</b>: Script de precompilación terminado con éxito, pero con warnings detectados (RC=$scriptRC) ", $scriptRET);
            }
            else
            {
                $log->info("<b>$paseprj</b>: script de precompilación terminado con éxito (RC=$scriptRC)", $scriptRET);
            }
        }
        else
        {
            $log->info("<b>$paseprj</b>: inicio precompilación IAS.");
            my $base        = "$eclipseDir/$PRE{$paseprj}{pde}";
            my $eclipseHome = "$base";                             ## la version padre
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
            if ($RC ne 0)
            {
                $log->debug("<b>$paseprj</b>: no he podido crear el directorio de link $linkDir (puede que existiera) RC=$RC: $RET");
            }
            else
            {
                $log->info("<b>$paseprj</b>: creado directorio de link $linkDir: $RET");
            }
            ($RC, $RET) = $harax->execute(qq{echo path=$iasDir > "$linkFile"});
            if ($RC ne 0)
            {
                $log->error("<b>$paseprj</b>: error al crear el fichero de link al PDE $linkFile (path=$iasDir) RC=$RC: $RET");
                _throw "Error durante la preparación para precompilar $paseprj";
            }
            else
            {
                $log->debug("<b>$paseprj</b>: creado fichero de link al PDE $linkFile (path=$iasDir): $RET");
            }

            # Borrado de caché
            # Parece que la única forma de que eclipse olvide links utilizados anteriormente a otras
            # versiones de la feature es forzar el borrado del directorio /configuration/org.eclipse/update
            # el semáforo debería garantizar que no se borra un eclipse que está siendo utilizado por otro
            # pase.
            my $cmdDel = qq{del /Q /S /F "${eclipseHome}\\configuration\\org.eclipse.update"};
            $log->debug("<b>$paseprj</b>: limpieza de la caché de plugins de eclipse", $cmdDel);
            my ($delRC, $delRET) = $harax->execute($cmdDel);
            if ($delRC ne 0)
            {
                $log->warn("<b>$paseprj</b>: No se pudo borrar la caché de plugins de eclipse. Podría compilarse con la versión incorrecta de entorno de desarrollo IAS (RC=$delRC) ", $delRET);
            }
            else
            {
                $log->debug("<b>$paseprj</b>: caché de plugins borrada con éxito. (RC=$delRC)", $delRET);
            }

            ## ANTRUNNER
            ##my $cmd = qq{${javaHome}\\bin\\java -jar ${eclipseHome}/startup.jar -application org.eclipse.ant.core.antRunner -buildfile $buildFile -Dbuilder=$configDir -DbaseLocation="${base}" -DbuildDirectory="$buildDir" 2>&1 };
            ## Pasamos también -clean para mayor seguridad
            my $cmd = qq{cd /D "$destpasedir" & ${javaHome}\\bin\\java $sta_eclipse_java_vmparams -jar "${eclipseHome}/startup.jar" -clean -application org.eclipse.ant.core.antRunner -buildfile "$buildFile"};
            $log->info("<b>$paseprj</b>: inicio del <b>antRunner</b>. Espere...", $cmd);
            my ($antRC, $antRET) = $harax->execute($cmd);
            if ($antRC ne 0)
            {
                $log->error("<b>$paseprj</b>: Error durante la ejecución de <b>antRunner</b> (RC=$antRC) ", $antRET);
                _throw "Error durante la precompilación IAS de <b>$paseprj</b>.";
            }
            else
            {
                $log->info("<b>$paseprj</b>: <b>antRunner</b> terminado con éxito (RC=$antRC)", $antRET);
            }
        }
## JRL - 20080627 - Si cerramos aquí harax, a la vuelta del bucle esta cerrada la conexión, no da error y bloquea el pase.
##      $harax->end();

    }

    ## RECUPERACIÓN DEL TAR DE TODO LOS PROYECTOS
    if (keys %PRE)
    {
        ## TAR
        my $destpasetardir = "${stadir}\\${Pase}\\$CAM";
        (my $tar_file = "${Pase}-$EnvironmentName-PRECOMP.tar") =~ s{\s+}{_}g;    ## harax->getfile no soporta espacios en nombre de fich
        $log->info("<b>Precompilación IAS</b>: inicio del TAR de ficheros generados ($destpasetardir\\$tar_file). Espere...");
        ($RC, $RET) = $harax->execute(qq{cd /D "$destpasedir" & $stawintarexe --mode=770 -cvf "..\\$tar_file" *});
        if ($RC ne 0)
        {
            $log->error("<b>Precompilación IAS</b>: error al crear el TAR con los resultados de la precompilación ($destpasedir) RC=$RC", $RET);
            _throw "Error durante la recuperación de los generados en la Precompilación IAS";
        }
        else
        {
            $log->info("<b>Precompilación IAS</b>: Ok TAR con los resultados de la precompilación ($destpasedir) RC=$RC", $RET);
        }

        ## RECUPERACION
        my $tarWinFilePath = "$destpasetardir\\$tar_file";
        $tarWinFilePath =~ s{\/}{\\}g;
        $log->info("<b>Precompilación IAS</b>: recuperando TAR de ficheros generados en Staging ($destpasedir/$tar_file). Espere...");
        ($RC, $RET) = $harax->getFile($tarWinFilePath, "$rootdir/$tar_file", "win");
        if ($RC ne 0)
        {
            $log->error("Error al recuperar TAR $tarWinFilePath a $rootdir/$tar_file (RC=$RC)", $RET);
            _throw "eclipseDist: error al recuperar tar de generados IAS para la Precompilación IAS";
        }
        else
        {
            $log->info("Recuperado fichero $tarWinFilePath a $rootdir/$tar_file (RC=$RC)", $RET);
        }

        ## UNTAR
        my @RET = `cd "$rootdir" ; $gnutar xvf "$tar_file" 2>&1`;
        if ($? ne 0)
        {
            $log->error("Error durante el UNTAR de $rootdir/$tar_file (RC=$?)", "@RET");
            _throw "eclipseDist: error al recuperar tar de generados IAS.";
        }
        else { $log->debug("UNTAR $rootdir/$tar_file en $rootdir (RC=$?)", "@RET"); }    ## BORRADO TAR WINDOWS
        ($RC, $RET) = $harax->execute(qq{del /Q /S /F "$destpasetardir\\$tar_file"});
    }

## JRL - 20080627 - Movemos aquí el cierre de la conexión
    $harax->end();
    return (\@generados, \@dirpase);
}

## JDJ - 20091112 ## Variable de distribuidor "sta_ias_precomp_use" permite activar/desactivar ## el uso del script por entorno.

sub scriptPrecompIAS
{
    my $self                = shift;
    my $log                 = $self->log;
    my $conf                = $self->conf;
    my $sta_ias_precomp_use = $conf->{sta_ias_precomp_use} || "sta_ias_precomp_use VACIO";
    my $Entorno             = shift;
    return 1 if $sta_ias_precomp_use eq "1";
    return ($sta_ias_precomp_use =~ m{$Entorno}i);
}

sub putFeatVersionToPlugManifest
{
    my $self = shift;
    my $log  = $self->log;
    my $conf = $self->conf;
    my ($ver, $feat, $id, $plugHome, $ref_logtxt) = @_;

    # Abro el MANIFEST.MF y le cambio la version
    my $manifestFile = "$plugHome/$id/META-INF/MANIFEST.MF";

    if (!open(MF, "<$manifestFile"))
    {
        $log->warn("<b>$feat</b>: ERROR: no se ha podido abrir $manifestFile para normalizar: $!. ");
    }
    else
    {

        #Se busca la entrada Bundle-Version dentro del MANIFEST.MF
        my $mf;
        $mf .= $_ foreach (<MF>);
        close MF;
        if ($mf =~ /Bundle-Version(.*?)/sg)
        {

            # MANIFEST.MF contiene la entrada  Bundle-Version;
            $mf =~ s/Bundle-Version: (.*)/Bundle-Version: $ver/g;    # OK, sustituye bien. Probar la diferencia con la siguiente.
            my $oldver = $1;
            ${$ref_logtxt} .= "PLUGIN_VERSION EN MANIFEST=$oldver, REQUIRED_PLUGIN_VERSION=$ver\n";
            open(MF, ">$manifestFile ") or die "ERROR: no se ha podido abrir $manifestFile  para escritura: $!";
            print MF $mf;
            close MF;
            ${$ref_logtxt} .= ">>>>>>  MANIFEST  DE PLUGIIN cambiado $id a '$ver'\n\n";
        }
        else
        {
            $log->warn("No existe la entrada <b>Bundle-Version</b> en el archivo $manifestFile");
        }
    }
}

1;
