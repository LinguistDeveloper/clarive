package BaselinerX::Model::NET::Dist;
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
use utf8;

my $balix_pool = BaselinerX::Dist::Utils::BalixPool->new;

# Variables 'globales':
has 'cam',                  is => 'rw', isa => 'Str';
has 'log',                  is => 'rw', isa => 'Object';
has 'need_rollback',        is => 'rw', isa => 'Bool', default => 0;
has 'net_backup_coa_veces', is => 'rw', isa => 'Int';
has 'pase_no_dist',         is => 'rw', isa => 'Any';
has 'sigo_sin_backup',      is => 'rw', isa => 'Any';
has 'tipo_pase',            is => 'rw', isa => 'Str';
has 'prj',                  is => 'rw', isa => 'Str';

# Variables de entorno:
has 'apl_publico',         is => 'ro', isa => 'Str', default => sub { _bde_conf('apl_publico')         };
has 'clickonce_mantiene',  is => 'ro', isa => 'Str', default => sub { _bde_conf('clickonce_mantiene')  };
has 'gnutar',              is => 'ro', isa => 'Str', default => sub { _bde_conf('gnutar')              };
has 'iiswebdirbin',        is => 'ro', isa => 'Str', default => sub { _bde_conf('iiswebdirbin')        };
has 'iiswebdirs',          is => 'ro', isa => 'Str', default => sub { _bde_conf('iiswebdirs')          };
has 'net_borrar_pase_dir', is => 'ro', isa => 'Str', default => sub { _bde_conf('net_borrar_pase_dir') };
has 'net_text_extensions', is => 'ro', isa => 'Str', default => sub { _bde_conf('net_text_extensions') };
has 'sqa_activo',          is => 'ro', isa => 'Str', default => sub { _bde_conf('sqa_activo')          };
has 'state_publico',       is => 'ro', isa => 'Str', default => sub { _bde_conf('state_publico')       };
has 'stawin',              is => 'ro', isa => 'Str', default => sub { _bde_conf('stawin')              };
has 'stawinbizdirpublico', is => 'ro', isa => 'Str', default => sub { _bde_conf('stawinbizdirpublico') };
has 'stawinbizport',       is => 'ro', isa => 'Str', default => sub { _bde_conf('stawinbizport')       };
has 'stawinbizserver',     is => 'ro', isa => 'Str', default => sub { _bde_conf('stawinbizserver')     };
has 'stawincert',          is => 'ro', isa => 'Str', default => sub { _bde_conf('stawincert')          };
has 'stawincerthuella',    is => 'ro', isa => 'Str', default => sub { _bde_conf('stawincerthuella')    };
has 'stawindir',           is => 'ro', isa => 'Str', default => sub { _bde_conf('stawindir')           };
has 'stawindirpublico',    is => 'ro', isa => 'Str', default => sub { _bde_conf('stawindirpublico')    };
has 'stawindirtemp',       is => 'ro', isa => 'Str', default => sub { _bde_conf('stawindirtemp')       };
has 'stawinnantexe',       is => 'ro', isa => 'Str', default => sub { _bde_conf('stawinnantexe')       };
has 'stawinobtfecexp',     is => 'ro', isa => 'Str', default => sub { _bde_conf('stawinobtfecexp')     };
has 'stawinport',          is => 'ro', isa => 'Str', default => sub { _bde_conf('stawinport')          };
has 'stawintarexe',        is => 'ro', isa => 'Str', default => sub { _bde_conf('stawintarexe')        };
has 'tardestinosaix',      is => 'ro', isa => 'Str', default => sub { _bde_conf('tardestinosaix')      };
has 'temp_harax',          is => 'ro', isa => 'Str', default => sub { _bde_conf('temp_harax')          };
has 'templates',           is => 'ro', isa => 'Str', default => sub { _bde_conf('templates')           };
has 'ultverframework',     is => 'ro', isa => 'Str', default => sub { _bde_conf('ultverframework')     };
has 'wasgroup',            is => 'ro', isa => 'Str', default => sub { _bde_conf('was_group')           };

sub netBuild {
    my $self       = shift;
    my $log        = $self->log;
    my $PaseNodist = $self->pase_no_dist;

    #    my $log = shift;
    #    $self->log($log);
    #    my $PaseNodist = shift;
    #    $self->pase_no_dist($PaseNodist);
    my %Elements = %{ shift @_ };
    my ( $Pase, $PaseDir, $PaseRed, $EnvironmentName, $Entorno, $Sufijo, $subAplicacion, $TipoPase, @Packages ) = @_;
    $self->tipo_pase($TipoPase);
    my ( $cam, $CAM ) = get_cam_uc($EnvironmentName);

    # $self->cam($CAM);
    my $inf = BaselinerX::Model::InfUtil->new( cam => $CAM );
    my $buildhome = "$PaseDir/$CAM/$Sufijo";

    my $har_db = BaselinerX::CA::Harvest::DB->new;

    # my $esAplicacionPublica = infEsPublica($EnvironmentName);
    my $esAplicacionPublica = $inf->is_public_bool;
    _log "esAplicacionPublica: $esAplicacionPublica";

    my @release        = ();
    my $VersionPublica = "";

    # my ($sigoSinBackup) = getInf( $EnvironmentName, "SCM_SEGUIR_SIN_BACKUP" );
    my $sigoSinBackup = $inf->get_inf( undef, [ { column_name => 'SCM_SEGUIR_SIN_BACKUP' } ] );
    _log "sigoSinBackup: $sigoSinBackup";
    $self->sigo_sin_backup($sigoSinBackup);
    my $NetbackupCOAveces = 0;

    #### CONVERSION DE UNIX A DOS DE FICHEROS DE TEXTO

    my $net_text_extensions = $self->net_text_extensions;
    my @extensiones         = split( ',', $net_text_extensions );
    my $convertedfiles      = 0;
    $log->info( "Convirtiendo ficheros de texto unix2dos.  Extensiones:" . join( ",", @extensiones ) );
    for my $extension (@extensiones) {
        my @txtfiles = `cd "$PaseDir"; find . -name "*.$extension"`;

        $log->debug( "Ficheros encontrados.  Comando cd \"$PaseDir\"; find . -name \"*.$extension\"", "" . join( "", @txtfiles ) . "" );
        foreach (@txtfiles) {
            local $/;
            open( TEXTFILE, "<$PaseDir/$_" );
            my $inputfile = <TEXTFILE>;
            close(TEXTFILE);
            $log->debug( "Fichero $_ antes de convertir", $inputfile );
            $inputfile =~ s/\n/\r\n/gs;
            open( TEXTFILE, ">$PaseDir/$_" );
            print TEXTFILE $inputfile;
            close(TEXTFILE);
            $log->debug( "Fichero $_ convertido unix2dos", $inputfile );
            $convertedfiles++;
        }
    }
    $log->info("Convertidos $convertedfiles ficheros unix2dos");

    #### FIN DE LA CONVERSION

    if ($esAplicacionPublica) {
        $log->info("Detectada aplicación pública");
        foreach (@Packages) {
            $log->debug("Buscando los grupos de paquetes a los que pertenece $_");

            # my @pkgGroups = getPackageGroups($_);
            my @pkgGroups = $har_db->get_package_groups($_);
            _log 'pkgGroups: ' . Data::Dumper::Dumper \@pkgGroups;

            $log->debug( "El paquete pertenece a " . join( ',', @pkgGroups ) );
            push @release, @pkgGroups;
        }
        my %saw;
        @saw{@release} = ();
        @release = sort keys %saw;    ##nombres de pkggroup unicos
        if ( @release > 1 ) {
            _throw "Error: aplicación <b>$EnvironmentName</b> tiene más de una release (package group) asociada: @release";
        }
        elsif ( !@release ) {
            _throw "Error: aplicación <b>$EnvironmentName</b> no tiene una release asociada a los paquetes del pase: @Packages";
        }
        $VersionPublica = $release[0];
        $VersionPublica =~ s/ /_/g;
        $log->debug("Versión a publicar: $VersionPublica");
    }
    chdir "$PaseDir/$CAM/$Sufijo";
    my ( $RC, $RET );

    # PARAMETROS DEL SERVIDOR DE STAGING
    my $stawin     = $self->stawin;
    my $stawinport = $self->stawinport;
    my $stawindir  = $self->stawindir;
    my ( $stamaq, $stapuerto, $stadir ) = ( $stawin, $stawinport, $stawindir );
    $log->info("Abiendo conexión con agente en $stamaq:$stapuerto");

    # ABRIMOS LA CONEXIÓN CON EL STAGING
    my %param = ();
    $param{OS} = "win";

    # my $balix = Harax->open( $stamaq, $stapuerto, $param{OS} );
    my $balix = $balix_pool->conn_port( $stamaq, $stapuerto );

    if ( !$balix ) {
        $log->error("No he podido establecer conexión con el servidor de compilación $stamaq en el puerto $stapuerto");
        _throw "Error al establecer conexión con el servidor de compilación";
    }
    $log->info("Conexión abierta con el cliente en $stamaq:$stapuerto");

    # ESTABLECEMOS LAS VARIABLES DE PASE EN EL SERVIDOR DE STAGING
    my $directorioDestino = "";
    my $destpasedir       = "${stadir}\\${Pase}\\$CAM\\$Sufijo";
    my $destpasedir2      = "${stadir}\\${Pase}\\$CAM\\${Sufijo}2";

    #my $maquina = "p5745.bdeexp01.bde.es";
    #my $puerto = "11500";

    my $NombreCortoEntorno = q{};    # FIXME

    #Construimos el fichero de build además de descubrir el framework a utilizar
    my ( $framework, $ficheroBuild, $prjFiles, %dirsCopia, $esIIS ) = $self->buildFile( $Pase, $PaseDir, $PaseRed, $EnvironmentName, $Entorno, $NombreCortoEntorno, $Sufijo, $destpasedir, $subAplicacion, $balix, $esAplicacionPublica, $VersionPublica );

    # GENERAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE
    my $tarfile = "$PaseDir/$CAM/$Sufijo/${Pase}-$EnvironmentName-$Sufijo.tar";
    my $gnutar  = $self->gnutar;
    $RET = `cd "$PaseDir/$CAM/$Sufijo";$gnutar cvf "$tarfile" *`;
    $log->info( "TAR '$tarfile' del directorio '$PaseDir/$CAM/$Sufijo/$subAplicacion' finalizado." . "\n$RET" );

    # CREACION DEL OBJETO DE PASE
    my $p = {
        Pase            => $Pase,
        PaseDir         => $PaseDir,
        PaseRed         => $PaseRed,
        EnvironmentName => $EnvironmentName,
        Entorno         => $Entorno,
        CAM             => $CAM,
        cam             => $cam,
        Sufijo          => $Sufijo,
        destpasedir     => $destpasedir,
        subAplicacion   => $subAplicacion,
        buildhome       => $buildhome,
        prjFiles        => $prjFiles,
    };
    $log->debug( "Objeto de pase", YAML::Dump($p) );
    $p->{harax} = $balix;
    try {
        my $cmd = "";

        $self->doUntarAndRestorePermission( $Pase, $balix, $tarfile, $destpasedir );

        #($RC,$RET) = $balix->execute("tasklist");
        #$log->info("Tareas (RC=$RC)" . "\n$RET");

        # This belongs to an old version.
        #        $log->info("Ejecutando nANT.  Espere, por favor ...");
        #        my $stawinnantexe = $self->stawinnantexe;
        #
        #        ## DEPENDIENDO DEL FRAMEWORK SE COMPILARÁ CON 1.0, 1.1 O NO SE COMPILARÁ NADA SI IIS (APLICACIÓN WEB SIN SOLUCIÓN)
        #        _log ">>> framework: '$framework' <<<";
        #
        #        if ( $esIIS ne "Si" ) {
        #            my $cmd = qq| cd /D "$destpasedir" & $stawinnantexe -buildfile:$ficheroBuild -t:$framework |;
        #            _log "cmd: $cmd";
        #            ( $RC, $RET ) = $balix->execute($cmd);
        #        }
        #        else {
        #            ( $RC, $RET ) = $balix->execute("cd /D \"$destpasedir\" & $stawinnantexe");
        #        }

        my $stawinnantexe = $self->stawinnantexe;

        $log->info("Ejecutando nANT.  Espere, por favor ...");
        my $typemsbuild = 'type msbuild_log.xml';
        if ( $dirsCopia{"COW"} || $dirsCopia{"COA"} ) {
            $typemsbuild = 'type msbuild_log.xml & type msbuild_publish_log.xml';
        }

        ## DEPENDIENDO DEL FRAMEWORK SE COMPILARÁ CON 1.0, 1.1 O NO SE COMPILARÁ NADA SI IIS (APLICACIÓN WEB SIN SOLUCIÓN)

        if ( $esIIS ne "Si" ) {

            # TODO no encuentra el xml de marras !!!!!!!!!!!!!!! TODO
            # my $cmd = qq| cd /D "$destpasedir" & $stawinnantexe -buildfile:$ficheroBuild -t:$framework & $typemsbuild |;
            my $cmd = qq| cd /D "$destpasedir" & $stawinnantexe -buildfile:$ficheroBuild -t:$framework |;
            _log "$cmd";
            ( $RC, $RET ) = $balix->execute($cmd);
        }
        else {
            ( $RC, $RET ) = $balix->execute("cd /D \"$destpasedir\" & $stawinnantexe");
        }

        if ( $RC > 1 ) {
            $log->error( "Error en nANT (RC=$RC)\n" . $RET );
            _throw "Error durante la compilación.";
        }
        else {
            $log->info( "nANT ejecutado (RC=$RC)\n" . $RET );
            ## SQA
            my $sqa_activo = $self->sqa_activo;
            if ( $sqa_activo || $PaseNodist ) {
                $log->debug(
                    "<b>SQA</b>:Llamo a sqa_tar", qq/
                  sqa_tar($balix, {
                  rem_dir => $destpasedir,
                  pase_dir => $PaseDir,
                  subapl => $subAplicacion,
                  entorno => $Entorno,
                  cam => $CAM,
                  pase => $Pase,
                  nature => 'NET'}) /
                );

                # TODO SQA
                #                sqa_tar( $balix,
                #                    {   rem_dir  => $destpasedir,
                #                        pase_dir => $PaseDir,
                #                        subapl   => $subAplicacion,
                #                        entorno  => $Entorno,
                #                        cam      => $CAM,
                #                        pase     => $Pase,
                #                        nature   => 'NET',
                #                    });    #if $TipoPase eq 'N';
            }
        }

        unless ($PaseNodist) {

            # logsection "Despliegue";

            # EMPEZAMOS A DESPLEGAR EN EL SERVIDOR DE DESTINO
            my $dirAplicacion = "";

            # SI LA SUBAPLICACION ES IGUAL QUE EL CAM, SE DISTRIBUYE AL RAIZ.  SI NO A UN SUBDIRECTORIO DE SUBAPLICACION
            if ( uc($CAM) eq uc($subAplicacion) ) {
                $dirAplicacion = $subAplicacion;
            }
            else {
                $dirAplicacion = "$CAM\\$subAplicacion";
            }

            ## DISTRIBUCIÓN DE APLICACIÓN PÚBLICA
            if ( $dirsCopia{"PUB"} ) {
                ## RECUPERAMOS EL FICHERO DE VERSION
                my @RETORNO = `mkdir "$buildhome/PUB"`;
                @RETORNO = `mkdir "$buildhome/PUB/$VersionPublica"`;
                $log->debug("Al crear el directorio PUBLICO en local me ha salido un RC=$?");
                ( $RC, $RET ) = $balix->getFile( "$destpasedir\\$subAplicacion\\PUB\\$VersionPublica.tar", "$buildhome/PUB/$VersionPublica.tar", "win" );

                if ( $RC ne 0 ) {
                    $log->error( "Error al recuperar el fichero de assemblies públicos $destpasedir\\$subAplicacion\\PUB\\$VersionPublica.tar (RC=$RC)" . "\n$RET" );
                    _throw "La distribución de la aplicación pública";
                }
                else {
                    $log->info( "Recuperado el fichero de assemblies públicos $VersionPublica.tar (RC=$RC)" . "\n$RET" );
                }

                # DISTRIBUCION DE APLICACION PUBLICA A STAGING BIZTALK
                # CONECTAMOS AL SERVIDOR DE .NET para coger la version publicada  Y la enviamos al servidor de Biztalk
                ## ENVIAMOS EL TAR AL SERVIDOR DE BIZTALK
                my $stawinbizserver = $self->stawinbizserver;
                $log->debug(" Enviando versión pública al staging de Biztalk $stawinbizserver");
                my $stawinbizport = $self->stawinbizport;

                # my $balixBTS = Harax->open( $stawinbizserver, $stawinbizport, "win" ) ;    ## Conexión al servidor STAGING de Biztalk.
                my $balixBTS = $balix_pool->conn_port( $stawinbizserver, $stawinbizport );

                my $stawinbizdirpublico   = $self->stawinbizdirpublico;
                my $VersionPublicaBiztalk = q{};                          # FIXME
                ( $RC, $RET ) = $balixBTS->sendFile( "$buildhome/PUB/$VersionPublica.tar", "$stawinbizdirpublico\\$CAM\\$VersionPublica\\$VersionPublicaBiztalk.tar" );
                if ( $RC ne 0 ) {
                    $log->error( "Error al enviar fichero $buildhome/PUB/$VersionPublicaBiztalk.tar a $stawinbizserver (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la distribución de aplicación pública a servidor de Biztalk";
                }
                else {
                    $log->debug("Enviado fichero $buildhome/PUB/$VersionPublica.tar a $stawinbizdirpublico\\$CAM\\$VersionPublica\\$VersionPublica.tar (RC=$RC)");
                }

                my $stawintarexe = $self->stawintarexe;

                # DESCOMPRIMIMOS EL FICHERO TAR EN DESTINO
                ( $RC, $RET ) = $balixBTS->execute("cd \"$stawinbizdirpublico\\$CAM\\$VersionPublica\" & del *.dll");
                ( $RC, $RET ) = $balixBTS->execute( "cd \"$stawinbizdirpublico\\$CAM\\$VersionPublica\" & $stawintarexe  pxvf \"$VersionPublicaBiztalk.tar\"" );
                if ( $RC ne 0 ) {
                    $log->error( "Error al desempaquetar fichero $stawinbizdirpublico\\$VersionPublica\\$CAM\\$VersionPublicaBiztalk.tar en $stawinbizserver (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la distribución de aplicación pública a servidor de Biztalk";
                }
                else {
                    $log->debug( "Desempaquetado el fichero $stawinbizdirpublico\\$CAM\\$VersionPublica\\$VersionPublicaBiztalk.tar (RC=$RC)" . "\n$RET" );
                    ( $RC, $RET ) = $balixBTS->execute("cd \"$stawinbizdirpublico\\$CAM\\$VersionPublica\" & del \"$VersionPublicaBiztalk.tar\"");
                }
                ( $RC, $RET ) = $balixBTS->end;

                ## Dist Pub a Biztalk            @RETORNO = `cd "$buildhome/PUB/$VersionPublica"; xvf ../$VersionPublica.tar; rm ../$VersionPublica.tar`;
                @RETORNO = `cd "$buildhome/PUB/$VersionPublica";$gnutar xvf ../$VersionPublica.tar; rm ../$VersionPublica.tar`;

                my $apl_publico   = $self->apl_publico;
                my $state_publico = $self->state_publico;

                # TODO ???
                #                checkinPublico(
                #                    path     => "$buildhome/PUB",
                #                    entorno  => $Entorno,
                #                    viewpath => "/$apl_publico/$CAM/.NET/$Entorno",
                #                    project  => $apl_publico,
                #                    state    => $state_publico,
                #                    release  => $VersionPublica,
                #                    desc     => "Creado por el pase $Pase"
                #                );

            }

            # DISTRIBUCIÓN DE LIBRERÍAS EN SERVIDOR WEB
            if ( $dirsCopia{"SW"} ) {

                #RECUPERAMOS LA INFORMACIÓN DE INFRAESTRUCTURA PARA EL ENVÍO
                # my ($maquinaDestino) = getInf( $CAM, "${Entorno}_WIN_SERVER" );
                my $maquinaDestino = $inf->get_inf( undef, [ { column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno } ] );
                _log "\$inf->get_inf(undef, [{column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno}]);\n" . "maquinaDestino: $maquinaDestino";

                my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );

                # $maquinaDestino = infResolveVars( $maquinaDestino, $CAM, $Entorno );
                $maquinaDestino = $resolver->get_solved_value($maquinaDestino);
                _log "maquinaDestino: $maquinaDestino";
                $log->debug("Máquina de destino: $maquinaDestino");

                # ($directorioDestino) = getWinServerInfo( $maquinaDestino, "SHR_WEB_APL" );
                $directorioDestino = shift @{ $inf->get_win_server_info( $maquinaDestino, ['SHR_WEB_APL'] ) };
                _log "directorioDestino: $directorioDestino";
                $log->debug("Directorio de destino WEB: $directorioDestino");

                ## Vamos a hacer la copia de seguridad

                # $NETNeedRollback = 1;
                $self->need_rollback(1);

                if ( $Entorno eq "PROD" ) {

                    my $directorioGuardar = "\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion";
                    my $dirLocal          = "$destpasedir\\$subAplicacion";
                    my $tipoBackup        = "SW";
                    my $ficheroTar        = "$tipoBackup.tar";

                    try {
                        $self->netBackup( $balix, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno );
                    }
                    catch {
                        if ( $sigoSinBackup =~ m/N/i ) {    ##ups, tengo que parar el pase
                            _throw "Pase cancelado por no poder realizar el backup de la versión anterior (aplicación $CAM configurada para no permitir continuar el pase sin backup): " . shift();
                        }
                        else {
                            $log->warn("No se ha podido realizar el backup de la aplicación $CAM. El pase continúa (aplicación $CAM configurada para permitir continuar el pase sin backup)");
                            $log->debug( "Razón para no haber podido hacer el backup: " . shift() );
                        }
                    }
                }

                # SE BORRAN LOS FICHEROS ANTERIORES DEL DIRECTORIO DE DESTINO
                $log->debug( "Comando de borrado: " . "del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\*.*\"" );
                ( $RC, $RET ) = $balix->execute("del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\*.*\" 2>&1");

                if ( $RC ne 0 ) {
                    $log->error( "Error al borrar la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                    _throw "Error durante el borrado de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion.";
                }
                else {
                    $self->BorrarSubdirectorios( $maquinaDestino, $directorioDestino, $dirAplicacion, $balix );
                    $log->info( "Aplicación borrada de \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                }

                # A PARTIR DE AQUÍ NECESITA ROLLBACK SI PETA
                # $NETNeedRollback = 1;
                $self->need_rollback(1);

                # COPIAMOS LOS COMPILADOS EN EL DIRECTORIO DE DESTINO
                $log->debug( "Comando de copia: " . "xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\SW\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\"" );
                ( $RC, $RET ) = $balix->execute( "xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\SW\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\"" );

                if ( $RC ne 0 ) {
                    $log->error( "Error al copiar aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la copia de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion.";
                }
                else {
                    $log->info( "Aplicación copiada en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                }
            }

            # DISTRIBUCIÓN CLICKONCE EN WINDOWS
            if ( $dirsCopia{"COW"} ) {

                # RECUPERAMOS LOS DATOS DEL SERVIDOR DE DESTINO DEL FORMULARIO DE INFRAESTRUCTURA
                # my ($maquinaDestino) = getInf( $CAM, "${Entorno}_WIN_SERVER" );
                my $maquinaDestino = $inf->get_inf( undef, [ { column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno } ] );
                _log "\$inf->get_inf(undef, [{column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno}]);\n" . "maquinaDestino: $maquinaDestino";

                my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );

                # $maquinaDestino = infResolveVars( $maquinaDestino, $CAM, $Entorno );
                $maquinaDestino = $resolver->get_solved_value($maquinaDestino);
                _log "maquinaDestino: $maquinaDestino";

                $log->debug("Máquina de destino: $maquinaDestino");

                # ($directorioDestino) = getWinServerInfo( $maquinaDestino, "SHR_WEB_APL" );
                $directorioDestino = shift @{ $inf->get_win_server_info( $maquinaDestino, ['SHR_WEB_APL'] ) };
                _log "directorioDestino: $directorioDestino";
                $log->debug("Directorio de destino APS: $directorioDestino");

                ## Vamos a hacer la copia de seguridad

                # El NETBACKUP LO HEMOS REALIZADO ANTES EN EL NETBUILD ,POR QUE BORRAMOS LAS VERSIONES ANTIGUAS MENOS LAS $ENV{CLICKONE_MANTIENE} ULTIMAS
                # COPIAMOS EL CONTENIDO DEL DIRECTORIO COW EN EL DESTINO
                $log->debug( "Comando de copia: " . "xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\COW\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\\"" );
                ( $RC, $RET ) = $balix->execute( "xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\COW\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\\"" );

                if ( $RC ne 0 ) {
                    $log->error( "Error al copiar aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\ (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la copia de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\.";
                }
                else {
                    $log->info( "Aplicación copiada en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\ (RC=$RC)" . "\n$RET" );
                }
            }    ## COW

            # DISTRIBUCIÓN CLICKONCE EN APACHE
            if ( $dirsCopia{"COA"} ) {
                $self->coa_dist($p);
            }

            # LIBRERÍAS EN SERVIDOR
            if ( $dirsCopia{"SL"} || $dirsCopia{"SM"} ) {

                # RECUPERAMOS LOS DATOS DE DESTINO DEL FORMULARIO DE INFRAESTRUCTURA
                # SL: Bibliotecas de servidor
                # SM: Bibliotecas de servidor multientorno
                my $EntornoM   = "";
                my $tipoBackup = "SL";
                my $dirType    = "SL";
                if ( $dirsCopia{"SM"} ) {
                    $EntornoM      = $Entorno;
                    $dirAplicacion = "$CAM\\$EntornoM\\$subAplicacion";
                    $tipoBackup    = "SM";
                    $dirType       = "SM";
                }

                # my ($maquinasDestinos) = getInf( $CAM, "${Entorno}_WIN_SERVER_DIST" );
                my @maquinasDestinos = @{ $inf->get_inf( {}, [ { column_name => 'WIN_SERVER_DIST', idred => $PaseRed, ident => $Entorno } ] ) };
                _log "\$inf->get_inf(undef, [{column_name => 'WIN_SERVER_DIST', idred => '$PaseRed', ident => '$Entorno'}])";
                unless (@maquinasDestinos) {    ##ups, tengo que parar el pase
                    $log->error("No se ha encontrado máquina de destino para las librerías de servidor.  Seleccione un servidor para distribución en el formulario de infraestructura (Otro Servidor)");
                    _throw "No se ha encontrado máquina de destino para las librerías de servidor: " . shift();
                }
                my @varMaquinas    = @maquinasDestinos;
                my $maquinaDestino = "";

                my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );

                foreach $maquinaDestino (@varMaquinas) {

                    # $maquinaDestino = infResolveVars( $maquinaDestino, $CAM, $Entorno );
                    $maquinaDestino = $resolver->get_solved_value($maquinaDestino);
                    $log->debug("Máquina de destino: $maquinaDestino");

                    # ($directorioDestino) = getWinServerInfo( $maquinaDestino, "SHR_NOWEB_APL" );
                    $directorioDestino = shift @{ $inf->get_win_server_info( $maquinaDestino, ['SHR_NOWEB_APL'] ) };
                    $log->debug("Directorio de destino APS: $directorioDestino");
                    ## Vamos a hacer la copia de seguridad
                    if ( $Entorno eq "PROD" ) {
                        my $directorioGuardar = "\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion";
                        $log->debug("directorioGuardar =$directorioGuardar ");
                        my $dirLocal = "$destpasedir\\$subAplicacion";
                        $log->debug("dirLocal =$dirLocal ");
                        try {
                            $self->netBackup( $balix, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno );
                        }
                        catch {
                            if ( $sigoSinBackup =~ m/N/i ) {    ##ups, tengo que parar el pase
                                _throw "Pase cancelado por no poder realizar el backup de la versión anterior (aplicación $CAM configurada para no permitir continuar el pase sin backup): " . shift();
                            }
                            else {
                                $log->warn("No se ha podido realizar el backup de la aplicación $CAM. El pase continúa (aplicación $CAM configurada para permitir continuar el pase sin backup)");
                                $log->debug( "Razón para no haber podido hacer el backup: " . shift() );
                            }
                        }
                    }

                    # BORRAMOS LOS ASSEMBLIES ANTERIORES
                    $log->debug( "Comando de borrado: " . "del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\*.*\"" );
                    ( $RC, $RET ) = $balix->execute("del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\*.*\"");
                    if ( $RC ne 0 ) {
                        $log->error( "Error al borrar la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                        _throw "Error durante el borrado de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion.";
                    }
                    else {
                        $log->info( "Aplicación borrada de \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                    }

                    # A PARTIR DE AQUÍ NECESITO ROLLBACK SI PETA
                    # $NETNeedRollback = 1;
                    $self->need_rollback(1);

                    ( $RC, $RET ) = $balix->execute('dir "E:\APSDAT\SCM\N.TEST0000001212\SCT\.NET\sct_net" ');

                    # COPIAMOS LOS ASSEMBLIES NUEVOS (DIRECTORIO SL o SM) EN EL DIRECTORIO DE DESTINO
                    $log->debug("Comando de copia: xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\$dirType\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\"");
                    ( $RC, $RET ) = $balix->execute("xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\$dirType\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\"");

                    _log "  WARNING  ";
                    _log $RET;
                    _log "  WARNING  ";

                    if ( $RC ne 0 ) {
                        $log->error( "Error al copiar aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                        _throw "Error durante la copia de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion.";
                    }
                    else {
                        $log->info( "Aplicación copiada en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                    }
                }
            }    ## SL Y SM

            # DISTRIBUCIÓN A UNIDAD R:
            if ( $dirsCopia{"CR"} ) {
                my $dirAppR;
                my $dirSubAppR = "";
                my $entAppR    = "";

                # my ($dirsAppNoWeb) = getInf( $CAM, "${Entorno}_WIN_NOWEB_DIRS" );
                my $dirsAppNoWeb = $inf->get_inf( undef, [ { column_name => 'NET_NOWEB_DIRS', idred => $PaseRed, ident => $Entorno } ] );
                _log "\$inf->get_inf(undef, [{column_name => 'NET_NOWEB_DIRS', idered => $PaseRed, ident => $Entorno}]);\n" . "dirsAppNoWeb: $dirsAppNoWeb";
                my @dirsAppNoWebArray = split( /\|/, $dirsAppNoWeb );

                # Solo hacemos cosas si no hemos puesto ya algo en entAppR, en cuyo caso ya lo tenemos y no queremos buscar más.
                if ( $entAppR eq "" ) {
                    foreach my $dir (@dirsAppNoWebArray) {
                        if ( index( $dir, "R:\\$CAM" ) >= 0 ) {
                            my $pos = index( $dir, ${Entorno} );

                            if ( $pos >= 0 ) {
                                $entAppR = ${Entorno};
                            }
                        }
                    }
                }

                if ( uc($CAM) eq uc($subAplicacion) ) {
                    $dirAppR = $subAplicacion;
                }
                else {

                    #$dirAplicacion = "$CAM\\$subAplicacion";
                    $dirAppR    = "$CAM";
                    $dirSubAppR = "$subAplicacion";
                }

                # RECUPERAMOS LOS DATOS DE LA UNIDAD R: DE LAS VARIABLES DEL DISTRIBUIDOR
                # my $maquinaDestino = infResolveVars( "\$\{win_maq_apl_r\}", $CAM, $Entorno );
                my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );
                my $maquinaDestino = $resolver->get_solved_value("\$\{win_maq_apl_r\}");
                _log "maquinaDestino: $maquinaDestino";

                # $directorioDestino = infResolveVars( "\$\{win_dir_apl_r\}", $CAM, $Entorno );
                $directorioDestino = $resolver->get_solved_value("\$\{win_dir_apl_r\}");
                _log "directorioDestino: $directorioDestino";
                $log->debug("Directorio de destino APS: $directorioDestino");

                ## Vamos a hacer la copia de seguridad
                if ( $Entorno eq "PROD" ) {
                    my $directorioGuardar = "\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR";
                    if ( uc($CAM) eq uc($subAplicacion) ) {
                        $directorioGuardar = "\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR";
                    }
                    $log->debug("directorioGuardar=$directorioGuardar");
                    my $dirLocal   = "$destpasedir\\$subAplicacion";
                    my $tipoBackup = "CR";
                    my $ficheroTar = "$tipoBackup.tar";

                    try {
                        $self->netBackup( $balix, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno );
                    }
                    catch {
                        if ( $sigoSinBackup =~ m/N/i ) {    ##ups, tengo que parar el pase
                            _throw "Pase cancelado por no poder realizar el backup de la versión anterior (aplicación $CAM configurada para no permitir continuar el pase sin backup): " . shift();
                        }
                        else {
                            $log->warn("No se ha podido realizar el backup de la aplicación $CAM. El pase continúa (aplicación $CAM configurada para permitir continuar el pase sin backup)");
                            $log->debug( "Razón para no haber podido hacer el backup: " . shift() );
                        }
                    }
                }

                # BORRAMOS LA VERSIÓN EXISTENTE
                $log->debug("Comando de borrado: del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\\*.*\"");
                ( $RC, $RET ) = $balix->execute("del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\\*.*\"");
                if ( $RC ne 0 ) {
                    $log->error( "Error al borrar la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)\n" . $RET );
                    _throw "Error durante el borrado de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR.";
                }
                else {
                    $log->info( "Aplicación borrada de \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)\n" . $RET );
                }

                # A PARTIR DE AQUI NECESITO ROLLBACK SI PETA
                # $NETNeedRollback = 1;
                $self->need_rollback(1);

                # COPIAMOS LOS NUEVOS ASSEMBLIES EN EL DESTINO
                $log->debug( "Comando de copia: xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\CR\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\"" );
                ( $RC, $RET ) = $balix->execute( "xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\CR\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\"" );
                if ( $RC ne 0 ) {
                    $log->error( "Error al copiar aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la copia de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR.";
                }
                else {
                    $log->info( "Aplicación copiada en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)" . "\n$RET" );
                }
            }    ## CR

            # DISTRIBUCIÓN A UNIDAD R: DE SUCURSALES
            if ( $dirsCopia{"RS"} ) {
                my $dirAppR;
                my $dirSubAppR;
                my $entAppR;

                # my ($dirsAppNoWeb) = getInf( $CAM, "${Entorno}_WIN_NOWEB_DIRS" );
                my $dirsAppNoWeb = $inf->get_inf( undef, [ { column_name => 'NET_NOWEB_DIRS', idred => $PaseRed, ident => $Entorno } ] );
                _log "\$inf->get_inf(undef, [{column_name => 'NET_NOWEB_DIRS', idred => $PaseRed, ident => $Entorno}]);\n" . "dirsAppNoWeb: $dirsAppNoWeb";
                my @dirsAppNoWebArray = split( /\|/, $dirsAppNoWeb );

                # Solo hacemos cosas si no hemos puesto ya algo en entAppR, en cuyo caso ya lo tenemos y no queremos buscar más.
                if ( $entAppR eq "" ) {
                    foreach my $dir (@dirsAppNoWebArray) {
                        if ( index( $dir, "R:\\Sucursales\\$CAM" ) >= 0 ) {
                            my $pos = index( $dir, ${Entorno} );

                            if ( $pos >= 0 ) {
                                $entAppR = ${Entorno};
                            }
                        }
                    }
                }

                if ( uc($CAM) eq uc($subAplicacion) ) {
                    $dirAppR    = $subAplicacion;
                    $dirSubAppR = "";
                }
                else {

                    #$dirAplicacion = "$CAM\\$subAplicacion";
                    $dirAppR    = "$CAM";
                    $dirSubAppR = "$subAplicacion";
                }

                # RECUPERAMOS LOS DATOS DE LA UNIDAD R: DE LAS VARIABLES DEL DISTRIBUIDOR
                # my $maquinaDestino = infResolveVars( "\$\{win_maq_apl_r_suc\}", $CAM, $Entorno );
                # $directorioDestino = infResolveVars( "\$\{win_dir_apl_r_suc\}", $CAM, $Entorno );
                my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );
                my $maquinaDestino = $resolver->get_solved_value("\$\{win_maq_apl_r\}");
                _log "maquinaDestino: $maquinaDestino";
                $directorioDestino = $resolver->get_solved_value("\$\{win_dir_apl_r\}");
                _log "directorioDestino: $directorioDestino";
                $log->debug("Directorio de destino APS: $directorioDestino");

                ## Vamos a hacer la copia de seguridad
                if ( $Entorno eq "PROD" ) {
                    my $directorioGuardar = "\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR";
                    my $dirLocal          = "$destpasedir\\$subAplicacion";
                    my $tipoBackup        = "RS";
                    my $ficheroTar        = "$tipoBackup.tar";

                    try {
                        $self->netBackup( $balix, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno );
                    }
                    catch {
                        if ( $sigoSinBackup =~ m/N/i ) {    ##ups, tengo que parar el pase
                            _throw "Pase cancelado por no poder realizar el backup de la versión anterior (aplicación $CAM configurada para no permitir continuar el pase sin backup): " . shift();
                        }
                        else {
                            $log->warn("No se ha podido realizar el backup de la aplicación $CAM. El pase continúa (aplicación $CAM configurada para permitir continuar el pase sin backup)");
                            $log->debug( "Razón para no haber podido hacer el backup: " . shift() );
                        }
                    }
                }

                # BORRAMOS LA VERSIÓN EXISTENTE
                $log->debug("Comando de borrado: del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\\*.*\"");
                ( $RC, $RET ) = $balix->execute("del /Q /S /F \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\\*.*\"");
                if ( $RC ne 0 ) {
                    $log->error( "Error al borrar la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)" . "\n$RET" );
                    _throw "Error durante el borrado de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR.";
                }
                else {
                    $log->info( "Aplicación borrada de \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)" . "\n$RET" );
                }

                # A PARTIR NECESITO ROLLBACK SI PETA
                # $NETNeedRollback = 1;
                $self->need_rollback(1);

                # COPIAMOS LOS NUEVOS ASSEMBLIES EN EL DESTINO
                $log->debug( "Comando de copia: xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\RS\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\"" );
                ( $RC, $RET ) = $balix->execute( "xcopy /E /Y /S /K /R \"$destpasedir\\$subAplicacion\\RS\\*.*\" \"\\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR\"" );
                if ( $RC ne 0 ) {
                    $log->error( "Error al copiar aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la copia de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR.";
                }
                else {
                    $log->info( "Aplicación copiada en \\\\$maquinaDestino\\$directorioDestino\\$dirAppR\\$entAppR\\$dirSubAppR (RC=$RC)" . "\n$RET" );
                }
            }    ## RS

            # logsection "Despliegue";

            my $net_borrar_pase_dir = $self->net_borrar_pase_dir;
            $log->debug("Chequeo de borrado del directorio de pase NET_BORRAR_PASE_DIR=$net_borrar_pase_dir");

            if ( $net_borrar_pase_dir eq "1" ) {
                ( $RC, $RET ) = $balix->execute("rmdir /S /Q $destpasedir");
                if ( $RC eq 0 ) { $log->debug( "Directorio de pase $destpasedir borrado", $RET ); }
                else            { $log->debug( "No se ha podido borrar el directorio de pase (RC=$RC)" . "\n$RET" ); }
            }

            $balix->end;
        }
        else {
            $log->info("Distribución excluida.  Pase de calidad");
        }
    }
    catch {
        my $maquina = q{};    # FIXME
        _throw "Error al transferir ficheros al nodo $maquina: " . shift();
    };
    $log->debug("Fin de netDist");
    return ( release => $VersionPublica );
}

=head2 coa_dist($p)

ClickOnce Apache

=cut

sub coa_dist {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );
    my $p    = shift;

    #   use YAML;
    #   $log->debug("Parametros coa_dist " , Dump( $p ));
    my $destpasedir   = $p->{destpasedir};
    my $subAplicacion = $p->{subAplicacion};
    my $buildhome     = $p->{buildhome};
    my $Pase          = $p->{Pase};
    my $Entorno       = $p->{Entorno};
    my $PaseRed       = $p->{PaseRed};
    my $CAM           = $p->{CAM};
    my $cam           = $p->{cam};
    my $Sufijo        = $p->{Sufijo};
    my $prj           = $p->{prjFiles}->[0];    ## esto suele corresponder al global prj
    $self->prj($prj);

    # RECUPERAMOS EL TAR CON EL RESULTADO DE LA PUBLICACIÓN
    my ( $RC, $RET ) = $p->{harax}->getFile( "$destpasedir\\$subAplicacion\\COA\\COA.tar", "$buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar", "win" );

    if ( $RC ne 0 ) {
        $log->error( "Error al recuperar fichero $destpasedir\\$subAplicacion\\COA\\COA.tar (RC=$RC)" . "\n$RET" );
        _throw "Error durante la distribución clickonce";
    }
    else {
        $log->info("Recuperado fichero $destpasedir\\$subAplicacion\\COA\\COA.tar (RC=$RC)");
    }
    ## BUSCAMOS LA RED EN LA QUE HAY QUE DISTRIBUIR
    my $subMasPrefijo = "";

    if ( uc( ${cam} ) eq uc( ${subAplicacion} ) ) {
        $subMasPrefijo = uc( ${cam} );
    }
    else {
        ##$subMasPrefijo = uc("${cam}_${subAplicacion}");
        $subMasPrefijo = uc("${subAplicacion}");
    }

    #    my ( $esLN, $esW3 ) = getInfSub( $CAM, $subMasPrefijo, "LN_WAS", "W3_WAS" );

    my @dist_nets = map {m/\$\[(.+)\]/} @{ $inf->get_inf( { sub_apl => $subMasPrefijo }, [ { column_name => 'JAVA_SUBAPL_RED' } ] ) };

    $log->info( "Redes a las que se distribuirá .NET: " . ( join ', ', @dist_nets ) );

    #    if ( $esLN eq "No" && $esW3 eq "No" ) {
    #        $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha especificado la red (Red Interna o Internet) en el formulario de infraestructura");
    #        _throw "Error al configurar distribución APACHE. Revise los datos de infraestructura";
    #    }
    #
    #    if ( $esLN eq "Si" && $esW3 eq "Si" ) {
    #        $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache y se ha especificado ambas redes (Red Interna e Internet) en el formulario de infraestructura");
    #        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
    #    }
    #
    #    if ( $esLN eq "Si" ) {
    #        $PaseRed = "LN";
    #        $log->info("La aplicación se distribuirá en Red Interna");
    #    }
    #    else {
    #        $PaseRed = "W3";
    #        $log->info("La aplicación se distribuirá en Internet");
    #    }

    for my $PaseRed (@dist_nets) {

        # RECUPERAMOS LOS DATOS DEL SERVIDOR DE DESTINO DEL FORMULARIO DE INFRAESTRUCTURA
        # my ( $servidorVar, $nombreServer ) = getInfUnixServer( $CAM, $Entorno, "HTTP", $PaseRed );
        my ( $servidorVar, $nombreServer ) = $inf->get_inf_unix_server( { ent => $Entorno, red => $PaseRed, tipo => 'HTTP' } );
        _log "my (\$servidorVar, \$nombreServer) = \$inf->get_inf_unix_server({ent => $Entorno, red => $PaseRed, tipo => 'HTTP'});\n" . "servidorVar: $servidorVar\n" . "nombreServer: $nombreServer";

        # my ($directorio) = getInfUnixServerDir( $CAM, $Entorno, $nombreServer, $PaseRed );
        my $directorio = $inf->get_inf_unix_server_dir( { entorno => $Entorno, server => $nombreServer, red => $PaseRed } );
        _log "my \$directorio = \$inf->get_inf_unix_server_dir({entorno => $Entorno, server => $nombreServer, red => $PaseRed});\n" . "directorio: $directorio";

        # my $servidorPrincipal = infResolveVars( $servidorVar, $CAM, $Entorno );
        my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );
        my $servidorPrincipal = $resolver->get_solved_value($servidorVar);
        _log "servidorPrincipal: $servidorPrincipal";

        # my $servidorCluster = infResolveVars( getUnixServerInfo( $servidorPrincipal, "SERVER_CLUSTER" ) );
        my $servidorCluster = $resolver->get_solved_value( $inf->get_unix_server_info( { server => $servidorPrincipal }, qw/SERVER_CLUSTER/ ) );
        _log "servidorCluster: $servidorCluster";

        for my $servidor ( $servidorPrincipal, $servidorCluster ) {
            next unless ( $servidor =~ m/^\w+/g );

            # my ($puerto) = getUnixServerInfo( $servidor, "HARAX_PORT" );
            my $puerto = $inf->get_unix_server_info( { server => $servidor }, qw/HARAX_PORT/ );
            $log->info("La aplicación se distribuirá al servidor:puerto '$servidor:$puerto', en el directorio $directorio");

            # CONECTAMOS AL SERVIDOR DE DESTINO Y ENVIAMOS EL FICHERO TAR

            # my $UNIXharax = Harax->open( $servidor, $puerto );
            my $UNIXharax = $balix_pool->conn_port( $servidor, $puerto );

            my $temp_harax = $self->temp_harax;
            ( $RC, $RET ) = $UNIXharax->sendFile( "$buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar", "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar" );
            if ( $RC ne 0 ) {
                $log->error( "Error al enviar fichero $buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar a $servidor (RC=$RC)" . "\n$RET" );
                _throw "Error durante la distribución clickonce";
            }
            else {
                $log->debug("Enviado fichero $buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar a $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar (RC=$RC)");
            }

            ############ DESCOMPRIMIMOS EL FICHERO TAR EN DESTINO
            # my ( $usuarioFuncional, $grupoFuncional ) = getInf( $CAM, "${Entorno}_AIX_UFUN", "${Entorno}_AIX_GFUN" );

            my $usuarioFuncional = $inf->get_inf( undef, [ { column_name => 'AIX_UFUN', idred => $PaseRed, ident => $Entorno } ] );
            _log "my \$usuarioFuncional = \$inf->get_inf(undef, [{column_name => 'AIX_UFUN', idred => $PaseRed, ident => $Entorno}]);\n" . "usuarioFuncional: $usuarioFuncional";

            # Nota: Por lo visto, todas las redes son 'G'. Comprobar.
            my $grupoFuncional = $inf->get_inf( undef, [ { column_name => 'AIX_GFUN', ident => $Entorno } ] );
            _log "my \$grupoFuncional = \$inf->get_inf(undef, [{column_name => 'AIX_GFUN', ident => $Entorno}]);\n" . "grupoFuncional: $grupoFuncional";

            my $dirClickOnce = "$directorio/" . uc($subAplicacion);
            ## ($RC,$RET) = $UNIXharax->execute(qq{mkdir "$dirClickOnce"; chown $usuarioFuncional:$wasgroup "$dirClickOnce"});

            ############  COMPROBAMOS SI EXISTE EL DIRECTORIO DE LA APLICACION  ####################################
            ( $RC, $RET ) = $UNIXharax->execute(qq{ ls "$dirClickOnce"});
            my $wasgroup = $self->wasgroup;

            if ( $RC ne 0 ) {
                ( $RC, $RET ) = $UNIXharax->executeas( $usuarioFuncional, qq{mkdir "$dirClickOnce"} );
                $log->debug( "Creado y cambiado de propietario el directorio <b>$dirClickOnce</b> ($usuarioFuncional:$wasgroup) en $servidor (RC=$RC)" . "\n$RET" );
            }
            else {
                $log->debug(" El directorio </b>$dirClickOnce</b>  existe .");
            }

            ############  GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR
            my $tarExecutable;

            my $tardestinosaix = $self->tardestinosaix;
            ( $RC, $RET ) = $UNIXharax->execute(qq| ls '$tardestinosaix' |);
            if ( $RC ne 0 ) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
                $log->debug( "Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina." . "\n$RET" );
                $tarExecutable = "tar";
            }
            else {
                $log->debug( "Esta máquina dispone de tar especial de IBM. Lo usamos." . "\n$RET" );
                $tarExecutable = $tardestinosaix;
            }

            $self->need_rollback(1);

            ############DESCOMPRIMIMOS CON EL USUARIO FUNCIINAL PARA LA HERENCIA DE PERMISOS            #################

            ( $RC, $RET ) = $UNIXharax->executeas( $usuarioFuncional, qq|cd "$dirClickOnce"; $tarExecutable xv --no-overwrite-dir --file   "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar"| );

            if ( $RC ne 0 ) {
                $log->error( "Error al desempaquetar fichero $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar en $servidor (RC=$RC)" . "\n$RET" );
                _throw "Error durante la distribución clickonce";
            }
            else {
                $log->debug( "Desempaquetado el fichero $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar (RC=$RC)" . "\n$RET" );
            }

            # BORRAMOS EL TAR DEL DESTINO
            ( $RC, $RET ) = $UNIXharax->execute(qq|rm "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar"|);
            if ( $RC ne 0 ) {
                $log->error( "Error borrar el fichero $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar en $servidor (RC=$RC)" . "\n$RET" );
                _throw "Error durante la distribución clickonce";
            }
            else {
                $log->debug("Borrado el fichero $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-COA.tar (RC=$RC)");
            }
        }
    }
}

=head2 buildFile

Genera el fichero de build antes de enviarlo a staging.

=cut

sub buildFile {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );
    my ( $Pase, $PaseDir, $PaseRed, $EnvironmentName, $Entorno, $NombreCortoEntorno, $Sufijo, $destpasedir, $subAplicacion, $balix, $esAplicacionPublica, $release ) = @_;
    my ( $cam, $CAM ) = get_cam_uc($EnvironmentName);
    my $solutions;
    my $copys;
    my $filesets;
    my $deletes;
    my %dirsCopia = ();
    my $buildhome = "$PaseDir/$CAM/$Sufijo";

    # GENERAMOS EL LISTADO DE SOLUCIONES
    my @slnfiles = `cd "$buildhome"; find ./$subAplicacion -name "*.sln"`;

    # GENERAMOS EL LISTADO DE PROYECTOS
    my @prjFiles = `cd "$buildhome"; find . -name "*.??proj"`;

    my $slnVersion = "";

    # RECUPERAMOS TODOS LOS PROYECTOS POR TIPO DE DISTRIBUCIÓN
    # my %prjTypes = getNetProjectsTypes( $EnvironmentName, $subAplicacion );
    my %prjTypes = $inf->get_net_project_types( $EnvironmentName, $subAplicacion );

    my $framework    = "";
    my @webDirs      = ();
    my $dirBase      = "";
    my $dirsBase     = "";
    my @dirsWebBase  = ();
    my $copyPublicas = "";

    #INFAUMX ENERO 2010
    my $esIIS = "No";

    $copys = "";

    # CON ESTO DECIDIMOS SI ES UNA APLICACIÓN WEB O NO
    # my ($esAplicacionWeb) = getInfSub( $CAM, $subAplicacion, "WIN_WEBAPL" );
    _log "my \$esAplicacionWeb = \$inf->get_inf({sub_apl => $subAplicacion}, [{column_name => 'NET_WEBAPL'}]);";
    my $esAplicacionWeb = $inf->get_inf( { sub_apl => $subAplicacion }, [ { column_name => 'NET_WEBAPL' } ] );
    _log "esAplicacionWeb: $esAplicacionWeb";

    #$log->debug("esAplicacionWeb=$esAplicacionWeb");

    # BUSCAMOS EL VIEW PATH DE LAS CARPETAS WEB EN EL FORMULARIO DE INFRAESTRUCTURA
    if ( $esAplicacionWeb eq "Si" ) {
        my $iiswebdirs = $self->iiswebdirs;
        @webDirs = split( ",", $iiswebdirs );

        # ($dirsBase) = getInfSub( $CAM, $subAplicacion, "WIN_IIS_VIEW_PATH" );
        $dirsBase = $inf->get_inf( { sub_apl => $subAplicacion }, [ { column_name => 'NET_IIS_VIEW_PATH' } ] );
        _log "\$dirsBase = \$inf->get_inf({sub_apl => '$subAplicacion'}, [{column_name => 'NET_IIS_VIEW_PATH'}]);\n" . "dirsBase: $dirsBase";

        if ($dirsBase) {
            @dirsWebBase = split( ",", $dirsBase );
        }
        else {
            push @dirsWebBase, "";
        }
        my $dirsWebBase_logtxt = join ', ', @dirsWebBase;
        $log->debug("Datos de despliegue web: Dirsbase=$dirsWebBase_logtxt, webDirs=@webDirs");
    }

    $dirsBase =~ s/\\/\\\\/g;    # Escapamos las posibles backslash que haya podido poner el usuario en el context-root

    # SI HAY FICHEROS DE SOLUCIÓN HAY QUE COMPILAR Y GENERAR EL BUILD FILE CON TASKS ESPECÍFICAS
    if (@slnfiles) {

        # logsection "Compilación";
        for my $sln (@slnfiles) {
            chop $sln;
            my $slnPath = $sln;

            # ESTE PATH LO USAREMOS PARA CALIFICAR LOS PATHS DE LOS FICHEROS A COPIAR EN EL BUILD FILE
            $slnPath =~ s/(.*)\/(.*?)$/$1/g;
            $copyPublicas = "";

            $log->debug("Identificada solución .NET: $sln");

            # RECUPERAMOS LA VERSION DE LA SOLUCIÓN PARA SABER COMO TENEMOS QUE COMPILAR
            $slnVersion = net_version("$PaseDir/$CAM/$Sufijo/$sln");

            # infaumx: Octubre 2009
            my $versFramework = "3.5";

            # ($versFramework) = getInfSub( $CAM, $subAplicacion, "VERSION_FRAMEWORK" );
            $versFramework = $inf->get_inf( { sub_apl => $subAplicacion }, [ { column_name => 'NET_VERS_FRAMEWORK' } ] );
            _log "\$versFramework = \$inf->get_inf({sub_apl => $subAplicacion}, [{column_name => 'NET_VERS_FRAMEWORK'}]);\n" . "versFramework: $versFramework";
            $log->debug("Versión de Framework detectada para $CAM y $subAplicacion es $versFramework ");

            # if ($slnVersion eq "2003") {
            if ( $versFramework eq "1.1" ) {
                ## COMPILAREMOS CON NANT
                $framework = "net-1.1";
                $solutions .= qq{
                    <solution configuration="\$\{configuration\}" solutionfile="$sln"> \n 
                };
                ## Ponemos los mapeos para modificar las URL http://localhost
                if ($esAplicacionWeb) {
                    $solutions .= qq{
                            <webmap>
                                <map url="http://localhost" path="."/>
                            </webmap>
                    };
                }
                $solutions .= qq{
                    </solution>
                };

            }
            else {

                # COMPILAREMOS CON MSBUILD
                $framework = "net-" . $versFramework;
                if ( $framework eq "net-" ) {

                    # infaumx enero 2010
                    my $ultverframework = $self->ultverframework;
                    $framework = $ultverframework;
                    $log->warn("No se ha encontrado la versión del framework con la que se tiene que compilar. Por favor, actualice el formulario. Por defecto, se procede a compilar con $framework");
                }
                $solutions .= qq{
                    <exec program="\$\{msBuild.exe\}" output="msbuild_log.xml" failonerror="true">
                            <arg value="$sln"/>
                            <arg value="/t:Build"/>
                            <arg line="/p:Configuration=\$\{configuration\}"/>
                    </exec>
                };
            }

            # Generamos los copys de los binarios de proyectos
            $log->debug("Proyectos detectados: @prjFiles");
            $log->debug( "Proyectos catalogados: " . join( "<br>", keys(%prjTypes) ) );

            my $prj;

            foreach $prj (@prjFiles) {
                chop $prj;

                my $prjName = $prj;
                my $prjPath = $prj;

                $prjName =~ s/(.*)\/(.*?)$/$2/g;
                $prjPath =~ s/(.*)\/(.*?)$/$1/g;
                my $prjNameNoExt = $prjName;
                $prjNameNoExt =~ s/(.*)\.(.*?)$/$1/g;

                my $releaseDir = "";

                $releaseDir = "$prjPath/bin/Release";

                my $stawindirpublico = $self->stawindirpublico;

                if ($esAplicacionPublica) {

                    if ( $Entorno eq "PROD" ) {
                        $copys .= qq|
                                    <mkdir dir="$stawindirpublico\\$CAM\\$release"/>
                                    <copy todir="$stawindirpublico\\$CAM\\$release">
                                        <fileset basedir="${releaseDir}">
                                            <include name="*.dll"/>
                                        </fileset>
                                    </copy>                     
                                |;
                    }
                    $filesets .= qq|
                                <fileset basedir="${releaseDir}">
                                    <include name="*.dll"/>
                                </fileset>                          
                        |;
                    $deletes .= qq|
                        <delete>
                                <fileset basedir="${releaseDir}">
                                    <include name="*.dll"/>
                                </fileset>
                        </delete>
                        |;
                    $dirsCopia{"PUB"} = 1;
                }
                else {

                    my @prjTypesArray = exists $prjTypes{$prjName} ? @{ $prjTypes{$prjName} } : ();
                    my $prjType = "";

                    foreach $prjType (@prjTypesArray) {
                        $log->debug("Investigando el proyecto $prjName.  Tipo: $prjType");
                        if ( $prjType eq "SL" || $prjType eq "SM" ) {
                            $log->debug("Proyecto $prjName de tipo $prjType");
                            $copys .= qq|
                                    <copy todir="$destpasedir\\$subAplicacion\\$prjType">
                                        <fileset basedir="${releaseDir}">
                                            <include name="**/*"/>
                                            <exclude name="*.pdb"/>
                                        </fileset>
                                    </copy>                                                 
                                |;
                            if ( $prjType eq "SL" ) {
                                $dirsCopia{"SL"} = 1;
                            }
                            else {
                                $dirsCopia{"SM"} = 1;
                            }

                            #$dirsCopia{$prjType } = 1;
                        }
                        elsif ( $prjType eq "SW" ) {
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            _log "HAAAAAAAAAAAAAAAAHAAAHAHAHAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHAHA";
                            $log->debug("Proyecto $prjName de tipo SW");
                            $copys .= qq!
                                    <copy todir="$destpasedir\\$subAplicacion\\SW\\bin">
                                        <fileset basedir="${releaseDir}">
                                            <include name="**/*"/>
                                            <exclude name="*.pdb"/>
                                        </fileset>
                                    </copy>                                         
                                !;
                            $dirsCopia{"SW"} = 1;
                        }
                        elsif ( $prjType eq "CR" ) {
                            $log->debug("Proyecto $prjName de tipo CR");
                            $copys .= qq!
                                    <copy todir="$destpasedir\\$subAplicacion\\CR" includeemptydirs="false">
                                        <fileset basedir="${releaseDir}">
                                            <include name="**/*"/>
                                            <exclude name="*.pdb"/>
                                        </fileset>
                                    </copy>                     
                                !;
                            $dirsCopia{"CR"} = 1;
                        }
                        elsif ( $prjType eq "RS" ) {
                            $log->debug("Proyecto $prjName de tipo RS");
                            $copys .= qq!
                                    <copy todir="$destpasedir\\$subAplicacion\\RS" includeemptydirs="false">
                                        <fileset basedir="${releaseDir}">
                                            <include name="**/*"/>
                                            <exclude name="*.pdb"/>
                                        </fileset>
                                    </copy>                     
                                !;
                            $dirsCopia{"RS"} = 1;
                        }
                        elsif ( $prjType eq "CO" ) {
                            unless ( $self->PaseNodist ) {
                                my $EntornoCO = "";

                                if ( $Entorno ne "PROD" ) {
                                    $EntornoCO = "_${Entorno}";
                                }

                                $log->debug("Proyecto $prjName de tipo CO");

                                ### A PARTIR DE AQUI GESTIONAMOS LA DISTRIBUCIÓN CLICKONCE EN IIS

                                ## BUSCAMOS LA VERSION CLICKONCE A GENERAR EN EL FICHERO DE PROYECTO.
                                ## RECUPERAMOS LA VERSION Y EL INCREMENTO EN CASO DE QUE NO SEA VERSION FIJA
                                my ( $versionCO, $incremento ) = clickonce_version("$PaseDir/$CAM/$Sufijo/$prj");

                                #$log->debug("Versión detectada: $versionCO");

                                my $url = "";

                                ## SI HAY ESTRUCTURA MICROSOFT DISTRIBUIMOS EN IIS

                                ## SI NO ES APLICACIÓN WEB, NO TIENE INFRAESTRUCTURA IIS PEDIDA
                                if ( $esAplicacionWeb ne "Si" ) {
                                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Windows pero no se ha encontrado infraestructura web IIS para la subaplicación $subAplicacion");
                                    _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                }

                                ## BUSCAMOS LA URL CON LA QUE SE EJECUTARA EL PROCESO DE PUBLICACIÓN
                                # ($url) = getInfSub( $CAM, $subAplicacion, "${Entorno}_WIN_URL_DISTR" );
                                $url = $inf->get_inf( { sub_apl => $subAplicacion }, [ { column_name => 'NET_URL_DISTR', idred => $PaseRed, ident => $Entorno } ] );
                                _log "my \$url = \$inf->get_inf({sub_apl => $subAplicacion}, [{column_name => 'NET_URL_DISTR', idred => $PaseRed, ident => $Entorno}]);\n" . "url: $url";
                                $url .= uc($subAplicacion) . "/appdeploy/";

                                ## BUSCAMOS LA MÁQUINA SERVIDOR DE IIS
                                # my ($maquinaDestinoVar) = getInf( $CAM, "${Entorno}_WIN_SERVER" );
                                my $maquinaDestinoVar = $inf->get_inf( undef, [ { column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno } ] );
                                _log "my \$maquinaDestinoVar = \$inf->get_inf(undef, [{column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno}]);\n" . "maquinaDestinoVar: $maquinaDestinoVar";

                                $log->debug("Máquina de destino=$maquinaDestinoVar");

                                ## RESOLVEMOS LA VARIABLE QUE INDICA LA MÁQUINA DE DESTINO
                                # my $maquinaDestino = infResolveVars( $maquinaDestinoVar, $CAM, $Entorno );
                                my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );
                                my $maquinaDestino = $resolver->get_solved_value($maquinaDestinoVar);
                                _log "maquinaDestino: $maquinaDestino";

                                if ( !$maquinaDestino ) {
                                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> pero no se ha especificado maquina IIS de destino en el formulario de infraestructura");
                                    _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                }

                                ## BUSCAMOS EL SHARE DE APLICACIONES WEB DE ESTA MÁQUINA DE DESTINO
                                # my ($directorioDestino) = getWinServerInfo( $maquinaDestino, "SHR_WEB_APL" );
                                my $directorioDestino = shift @{ $inf->get_win_server_info( $maquinaDestino, ['SHR_WEB_APL'] ) };
                                _log "directorioDestino: $directorioDestino";
                                if ( !$directorioDestino ) {
                                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> pero la máquina de destino $maquinaDestino no tiene un recurso compartido para aplicaciones web");
                                    _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                }

                                my $dirAplicacion = "";

                                ## SI LA SUBAPLICACION ES IGUAL AL CAM, SE DISTRIBUYE EN EL RAIZ
                                if ( uc($CAM) eq uc($subAplicacion) ) {
                                    $dirAplicacion = $subAplicacion;
                                }
                                else {
                                    $dirAplicacion = "$CAM\\$subAplicacion";
                                }

                                #Vamos a ver si hay algo que copiar

                                my ( $RC, $RET ) = $balix->execute("dir /b /od /ad \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\*\"");

                                ## HACEMOS EL COPY DE FICHEROS, CREAMOS EL DIRECTORIO DE BACKUP, Y TAREAMOS LOS ASSEMBLIES COMPILADOS
                                if ( $RC == 0 ) {

                                    $copyPublicas .= qq!
                                        <copy todir="${releaseDir}/$prjNameNoExt${EntornoCO}.publish">
                                            <fileset basedir="\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy">
                                                <include name="**/*"/>
                                            </fileset>
                                        </copy>
                                        <mkdir dir="$destpasedir\\$subAplicacion\\backup"/>
                                        <tar destfile="$destpasedir\\$subAplicacion\\backup\\COW.tar">
                                            <fileset basedir="${releaseDir}/$prjNameNoExt${EntornoCO}.publish">
                                                <include name="**/*"/>
                                            </fileset>
                                        </tar>                                          
                                    !;
                                }

                                ## SI TENEMOS QUE INCREMENTAR LA VERSION
                                my $Listadeversiones = "";
                                my $nuevaVersion     = 0;
                                my $versionCOW       = $versionCO;
                                if ( $incremento eq "si" ) {
                                    $log->debug( "Comando de listado de versiones: dir /b /od /ad \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\${prjNameNoExt}${EntornoCO}_${versionCO}*\"" );
                                    ( $RC, $RET ) = $balix->execute( "dir /b /o-d /ad \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\${prjNameNoExt}${EntornoCO}_${versionCO}_*\"" );

                                    if ( $RC ne 0 && $RC ne 1 ) {
                                        $log->error( "Error al buscar versiones de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion (RC=$RC)" . "\n$RET" );
                                        _throw "Error durante la búsqueda de versiones de la aplicación en \\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy";
                                    }
                                    ## me guardo la salida de la busqueda para luego si tengo que borrar versiones
                                    $Listadeversiones = $RET;
                                    $log->debug( "Retorno del comando de búsqueda (RC=$RC)" . "\n$RET" );
                                    if ( $RC eq 1 ) {
                                        ## NO HAY VERSIONES ANTERIORES
                                        $versionCO .= "_0";
                                    }
                                    else {
                                        ## HAY VERSIONES ANTERIORES. BUSCO LA SIGUIENTE VERSIÓN
                                        my @dirs = split( /\n/, $RET );
                                        my $queVersion = "";
                                        foreach $queVersion (@dirs) {
                                            $queVersion =~ s/^.*_(.*?)_(.*?)_(.*?)_(.*?)$/$4/;
                                            if ( $queVersion > $nuevaVersion ) {
                                                $nuevaVersion = $queVersion;
                                            }
                                        }
                                        $versionCO .= "_" . ++$nuevaVersion;
                                    }
                                    $log->debug("Nueva version: $versionCO");
                                    ### Vamos a cambiar la versión en el fichero de proyecto
                                    ### para que se genere bien el .application
                                    open( PROY, "<$buildhome/$prj" );

                                    my $linea            = "";
                                    my @lineas           = ();
                                    my $versionConPuntos = $versionCO;

                                    $versionConPuntos =~ s/\_/\./g;

                                    foreach $linea (<PROY>) {
                                        $linea =~ s/^(.*)\<ApplicationVersion\>(.*)\<\/ApplicationVersion\>(.*)$/$1\<ApplicationVersion\>$versionConPuntos\<\/ApplicationVersion\>$3/;
                                        $linea =~ s/^(.*)\<PublishUrl\>(.*)\<\/PublishUrl\>(.*)$/$1\<PublishUrl\>$url\<\/PublishUrl\>$3/;
                                        $linea =~ s/^(.*)\<UpdateUrl\>(.*)\<\/UpdateUrl\>(.*)$/$1\<UpdateUrl\>$url\<\/UpdateUrl\>$3/;
                                        $linea =~ s/^(.*)\<InstallUrl\>(.*)\<\/InstallUrl\>(.*)$/$1\<InstallUrl\>$url\<\/InstallUrl\>$3/;
                                        $linea =~ s/^(.*)\<OutputPath\>(.*)\<\/OutputPath\>(.*)$/$1\<OutputPath\>bin\\Release\\\<\/OutputPath\>$3/;
                                        $linea =~ s/^(.*)\<AssemblyName\>(.*)\<\/AssemblyName\>(.*)$/$1\<AssemblyName\>$2${EntornoCO}\<\/AssemblyName\>$3/;
                                        push( @lineas, $linea );
                                    }
                                    $log->debug( "Fichero $buildhome/$prj modificado", join( "\n", @lineas ) );
                                    close(PROY);
                                    open( PROY, ">$buildhome/$prj" );
                                    print PROY foreach (@lineas);
                                    close(PROY);
                                }

                                ## Vamos a hacer la copia de seguridad en Producción de tipo COW antes de borrar todas las versiones - ClickOnce_mantiene
                                ## Ahora se hace aqui por que despues se borran todas las veriones menos las {$ENV(ClickOnce_mantiene)}  ultimas

                                # RECUPERAMOS LOS DATOS DEL SERVIDOR DE DESTINO DEL FORMULARIO DE INFRAESTRUCTURA

                                # my ($maquinaDestino) = getInf( $CAM, "${Entorno}_WIN_SERVER" );
                                $maquinaDestino = $inf->get_inf( undef, [ { column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno } ] );
                                _log "my \$maquinaDestino = \$inf->get_inf(undef, [{column_name => 'WIN_SERVER', idred => $PaseRed, ident => $Entorno}]);\n" . "maquinaDestino: $maquinaDestino";

                                # $maquinaDestino = infResolveVars( $maquinaDestino, $CAM, $Entorno );
                                $maquinaDestino = $resolver->get_solved_value($maquinaDestino);
                                _log "maquinaDestino: $maquinaDestino";
                                $log->debug("Máquina de destino: $maquinaDestino");

                                # ($directorioDestino) = getWinServerInfo( $maquinaDestino, "SHR_WEB_APL" );
                                $directorioDestino = shift @{ $inf->get_win_server_info( $maquinaDestino, ['SHR_WEB_APL'] ) };
                                _log "directorioDestino: $directorioDestino";
                                $log->debug("Directorio de destino APS: $directorioDestino");

                                ## Vamos a hacer la copia de seguridad

                                if ( $Entorno eq "PROD" ) {
                                    my $directorioGuardar = "\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy";
                                    my $dirLocal          = "$destpasedir\\$subAplicacion";
                                    my $tipoBackup        = "COW";
                                    my $ficheroTar        = "$tipoBackup.tar";

                                    try {
                                        $self->netBackup( $balix, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno );
                                    }
                                    catch {
                                        my $sigoSinBackup = $self->sigo_sin_backup;
                                        if ( $sigoSinBackup =~ m/N/i ) {    ##ups, tengo que parar el pase
                                            _throw "Pase cancelado por no poder realizar el backup de la versión anterior (aplicación $CAM configurada para no permitir continuar el pase sin backup): " . shift();
                                        }
                                        else {
                                            $log->warn("No se ha podido realizar el backup de la aplicación $CAM. El pase continúa (aplicación $CAM configurada para permitir continuar el pase sin backup)");
                                            $log->debug( "Razón para no haber podido hacer el backup: " . shift() );
                                        }
                                    }

                                }

                                # A PARTIR DE AQUÍ NECESITA ROLLBACK SI PETA
                                # $NETNeedRollback = 1;
                                $self->need_rollback(1);
                                my $clickonce_mantiene = $self->clickonce_mantiene;
                                my $mantieneCO         = $clickonce_mantiene;
                                if ( $nuevaVersion > $mantieneCO ) {
                                    ## BORRO TODAS LAS VERSIONES CLICKONCE EN SERVIDOR EXCEPTO LAS 2 MAS RECIENTES
                                    ## (o lo que ponga la variable de distribuidor $clickonce_mantiene)
                                    ## ordenadas por fecha, más recientes primero
                                    my $LogDelete = "";
                                    ( $RC, $RET ) = $balix->execute( "dir /b /o-d /ad \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\${prjNameNoExt}${EntornoCO}_${versionCOW}_*\"" );
                                    $log->debug( "Retorno del comando de búsqueda (RC=$RC)", $Listadeversiones );
                                    if ( $RC eq 0 ) {
                                        my @dirs = "";
                                        ## lo meto en un array para recorrerlo
                                        @dirs = split( /\n/, $Listadeversiones );
                                        $mantieneCO = 2 if ( !$mantieneCO );
                                        $log->debug("Clickonce IIS: buscando versiones para borrar, manteniendo las $mantieneCO últimas...");
                                        $LogDelete .= "Clickonce IIS: buscando versiones para borrar, manteniendo las $mantieneCO últimas...\n";
                                        my $queVersion  = "";
                                        my $versionTOPE = $nuevaVersion - $mantieneCO;
                                        $LogDelete .= "Clickonce IIS: Borro todas las versiones hasta la version $versionTOPE \n";

                                        for my $CualVersion (@dirs) {
                                            my $versionaBorrar = $CualVersion;
                                            $CualVersion =~ s/^.*_(.*?)_(.*?)_(.*?)_(.*?)$/$4/;
                                            if ( $CualVersion < $versionTOPE ) {
                                                $LogDelete .= "Clickonce IIS: borro la versión $versionaBorrar \n($maquinaDestino: \\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\$versionaBorrar) \n";
                                                ( $RC, $RET ) = $balix->execute( "rmdir /S /Q \"\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\$versionaBorrar\"" );
                                                if ( $RC eq 0 ) {
                                                    $LogDelete .= "Clickonce IIS: borrada la versión $versionaBorrar\n";
                                                }
                                                else {
                                                    $LogDelete .= "Clickonce IIS:ERROR al borrar la versión $versionaBorrar (RC=$RC) -->  $RET \n ";
                                                }
                                            }
                                            else {
                                                $LogDelete .= "Clickonce IIS: se mantiene la versión $versionaBorrar \n($maquinaDestino:\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\appdeploy\\$versionaBorrar)\n";
                                            }
                                        }
                                        $log->info( "Clickonce IIS: Informe de las Versiones Borradas y Conservadas. ", $LogDelete );
                                    }
                                    else {
                                        $log->debug(qq|Clickonce IIS: no he encontrado carpetas de versiones para borrar: dir /b /o-d /ad \\$maquinaDestino\$directorioDestino\$dirAplicacion\appdeploy\${prjNameNoExt}${EntornoCO}_*  |);
                                    }
                                }
                                else {
                                    $log->debug("Clickonce IIS: No hay versiones que borrar por que la variable clickone_mantine es mayor que el numero de versiones ");
                                }

                                ## GENERO EL COPY DE LOS ASSEMBLIES GENERADOS
                                $copys .= qq!
                                    <copy todir="$destpasedir\\$subAplicacion\\COW">
                                        <fileset basedir="${releaseDir}/${prjNameNoExt}${EntornoCO}.publish">
                                            <include name="**/*"/>
                                        </fileset>
                                    </copy>                                                             
                                !;

                                ## LA PUBLICACIÓN SE FIRMARÁ CON EL CERTIFICADO SIGUIENTE Y SU HUELLA DIGITAL
                                my ( $certificadoClickOnce, $huellaDigital ) = $self->ObtenerCertificadoDigital();

                                ## OBTENEMOS LA FECHA DE EXPIRACIÓN DEL CERTIFICADO DIGITAL Y
                                ## LA GUARDAMOS EN LA BASE DE DATOS
                                $self->RegistrarPublicacionClickOnce( $CAM, $subAplicacion, $Entorno, $certificadoClickOnce, $Pase, $balix );

                                ## EJECUTAMOS LA PUBLICACIÓN
                                $solutions .= qq{
                                <exec program="\$\{msBuild.exe\}" output="msbuild_publish_log.xml" failonerror="true">
                                        <arg value="$sln"/>
                                        <arg value="/t:publish"/>
                                        <arg line="/p:Configuration=\$\{configuration\};UpdateURL=$url;UpdateMode=Foreground;UpdateEnabled=true;PublishURL=$url;InstallUrl=$url;WebPage=publish.htm;CreateWebPageOnPublish=true;ApplicationVersion=$versionCO;GenerateApplicationManifest=true;GenerateDeploymentManifest=true;ManifestCertificateThumbprint=$huellaDigital;ManifestKeyFile=$certificadoClickOnce"/>
                                </exec>                         
                                };
                                $dirsCopia{"COW"} = 1;
                            }
                        }
                        elsif ( $prjType eq "CA" ) {

                            unless ( $self->pase_no_dist ) {
                                my $EntornoCO = "";

                                if ( $Entorno ne "PROD" ) {
                                    $EntornoCO = "_${Entorno}";
                                }

                                ### A PARTIR DE AQUI GESTIONAMOS LA DISTRIBUCIÓN CLICKONCE EN APACHE

                                ## BUSCAMOS LA VERSION CLICKONCE A GENERAR EN EL FICHERO DE PROYECTO.
                                ## RECUPERAMOS LA VERSION Y EL INCREMENTO EN CASO DE QUE NO SEA VERSION FIJA
                                my ( $versionCO, $incremento ) = clickonce_version("$PaseDir/$CAM/$Sufijo/$prj");

                                $log->debug("Versión detectada: $versionCO");
                                $log->debug("Incrementar versión: $incremento");

                                my $subMasPrefijo = "";

                                if ( uc( ${cam} ) eq uc( ${subAplicacion} ) ) {
                                    $subMasPrefijo = uc( ${cam} );
                                }
                                else {
                                    ##$subMasPrefijo = uc("${cam}_${subAplicacion}");
                                    $subMasPrefijo = uc("${subAplicacion}");
                                }

                                ##INFAUMX - ABRIL2010
                                ## BUSCAMOS LA RED EN LA QUE HAY QUE DISTRIBUIR

                                my @dist_nets = map {m/\$\[(.+)\]/} @{ $inf->get_inf( { sub_apl => $subMasPrefijo }, [ { column_name => 'JAVA_SUBAPL_RED' } ] ) };

                                #                                my ( $esLN, $esW3 ) = getInfSub( $CAM, $subMasPrefijo, "LN_WAS", "W3_WAS" );
                                #
                                #                                if ( $esLN eq "No" && $esW3 eq "No" ) {
                                #                                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha especificado la red (Red Interna o Internet) en el formulario de infraestructura");
                                #                                    _throw
                                #                                        "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                #                                }
                                #                                if ( $esLN eq "Si" && $esW3 eq "Si" ) {
                                #                                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache y se ha especificado ambas redes (Red Interna e Internet) en el formulario de infraestructura");
                                #                                    _throw
                                #                                        "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                #                                }
                                #
                                #                                if ( $esLN eq "Si" ) {
                                #                                    $PaseRed = "LN";
                                #                                }
                                #                                else {
                                #                                    $PaseRed = "W3";
                                #                                }

                                ##FIN

                                for my $PaseRed (@dist_nets) {

                                    ## RECUPERO LA INFORMACIÓN DE INFRAESTRUCTURA NECESARIA
                                    #$log->debug("Le mando esto ($subMasPrefijo) como subaplicacion");

                                    ## infaumx- abril2010- Se cambia de donde se coge el campo para poder distribuir tanto por Red interna como por Internet.

                                    # my ($url) = getInfSub( $CAM, $subMasPrefijo, "${Entorno}_${PaseRed}_WAS_URL_DISTR" );
                                    my $url = $inf->get_inf( { sub_apl => $subMasPrefijo }, [ { column_name => 'WAS_URL_DISTR', ident => $Entorno, idred => $PaseRed } ] );
                                    _log "my \$url = \$inf->get_inf({sub_apl => $subMasPrefijo}, [{column_name => 'WAS_URL_DISTR', ident => $Entorno, idred => $PaseRed}]);\n" . "url: $url";

                                    #$log->debug("Recupero el valor del campo ${Entorno}_${PaseRed}_WAS_URL_DISTR: $url ");

                                    if ( !$url ) {
                                        $log->error( "El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha encontrado URL de acceso a la subaplicación " . lc($subAplicacion) );
                                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura (${Entorno}_${PaseRed}_WAS_URL_DISTR vacío)";
                                    }
                                    $url .= uc($subAplicacion) . "/";

                                    ## EN ESTE LUGAR ES DONDE ESTABA ANTES LA SECCIÓN: BUSCAMOS LA RED EN LA QUE HAY QUE DISTRIBUIR

                                    ## RECUPERO EL SERVIDOR DE DESTINO
                                    # my ( $servidorVar, $nombreServer ) = getInfUnixServer( $CAM, $Entorno, "HTTP", $PaseRed );
                                    my ( $servidorVar, $nombreServer ) = $inf->get_inf_unix_server( { ent => $Entorno, red => $PaseRed, tipo => 'HTTP' } );
                                    _log "my (\$servidorVar, \$nombreServer) = \$inf->get_inf_unix_server({ent => $Entorno, red => $PaseRed, tipo => 'HTTP'});\n" . "servidorVar: $servidorVar\n" . "nombreServer: $nombreServer";

                                    $log->debug("Servidor recuperado de la infraestructura=$servidorVar");

                                    if ( !$servidorVar ) {
                                        $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha encontrado el servidor HTTP en la infraestructura AIX");
                                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                    }

                                    ## TRADUCIMOS LA VARIABLE DEL SERVIDOR
                                    # my $servidor = infResolveVars( $servidorVar, $CAM, $Entorno );
                                    my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );
                                    my $servidor = $resolver->get_solved_value($servidorVar);
                                    _log "servidor: $servidor";

                                    ## RECUPERAMOS EL DIRECTORIO DE DESTINO
                                    # my $directorio = getInfUnixServerDir( $CAM, $Entorno, $nombreServer, $PaseRed );
                                    my $directorio = $inf->get_inf_unix_server_dir( { entorno => $Entorno, server => $nombreServer, red => $PaseRed } );
                                    _log "my \$directorio = \$inf->get_inf_unix_server_dir({entorno => $Entorno, server => $nombreServer, red => $PaseRed});\n" . "directorio: $directorio";

                                    if ( !$directorio ) {
                                        $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha encontrado directorio de aplicación en el servidor $servidor en la infraestructura AIX");
                                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                    }
                                    $directorio = "$directorio/" . uc($subAplicacion);
                                    ## BUSCAMOS EL PUERTO HARAX DEL DESTINO
                                    # my ($puerto) = getUnixServerInfo( $servidor, "HARAX_PORT" );
                                    my $puerto = $inf->get_unix_server_info( { server => $servidor }, qw/HARAX_PORT/ );
                                    if ( !$puerto ) {
                                        $log->error("No se ha encontrado el puerto de conexión a la máquina $servidor en los datos de infraestructura");
                                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                    }

                                    $log->info("Abriendo conexión con agente en $servidor:$puerto");

                                    # my $UNIXharax = Harax->open( $servidor, $puerto );
                                    my $UNIXharax = $balix_pool->conn_port( $servidor, $puerto );

                                    if ( !$UNIXharax ) {
                                        $log->error("No he podido establecer conexión con el servidor $servidor en el puerto $puerto");
                                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                                    }

                                    ## ¿Existe el directorio destino?
                                    $log->debug( "Comprobamos que existe el directorio destino", qq{cd "$directorio"} );
                                    my ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$directorio"});
                                    if ( $RC ne 0 ) {
                                        $log->error( "No existe la infraestructura en $directorio o los permisos no son los correctos (RC=$RC)" . "\n$RET" );
                                        _throw "No existe la infraestructura en $directorio o los permisos no son los correctos";
                                    }

                                    ## SI TENEMOS QUE INCREMENTAR LA VERSIÓN ...
                                    if ( $incremento eq "si" ) {

                                        ## ... BUSCAMOS LAS VERSIONES QUE EXISTEN YA
                                        $log->debug( "Comando de búsqueda: " . qq!cd "$directorio"; ls -d -rt ${prjNameNoExt}${EntornoCO}_${versionCO}_*! );
                                        ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$directorio"; ls -d -rt ${prjNameNoExt}${EntornoCO}_${versionCO}_*});
                                        if ( $RC ne 0 && $RC ne 512 && $RC ne 256 ) {
                                            $log->error( "Error al buscar versiones de la aplicación en $directorio (RC=$RC)" . "\n$RET" );
                                            _throw "Error durante la búsqueda de versiones de la aplicación en $directorio";
                                        }

                                        $log->debug( "Retorno del comando de búsqueda (RC=$RC)" . "\n$RET" );
                                        if ( $RC eq 512 ) {
                                            ## NO HAY VERSIONES ANTERIORES
                                            $versionCO .= "_0";
                                        }
                                        else {
                                            ## HAY VERSIONES ANTERIORES.  INCREMENTO LA ÚLTIMA EN UNO
                                            my @dirs         = split( /\n/, $RET );
                                            my $queVersion   = "";
                                            my $nuevaVersion = 0;
                                            foreach $queVersion (@dirs) {
                                                $queVersion =~ s/^.*_(.*?)_(.*?)_(.*?)_(.*?)$/$4/;
                                                if ( $queVersion > $nuevaVersion ) {
                                                    $nuevaVersion = $queVersion;
                                                }
                                            }
                                            $versionCO .= "_" . ++$nuevaVersion;
                                        }
                                        $log->debug("Nueva version: $versionCO");
                                        ### Vamos a cambiar la versión en el fichero de proyecto
                                        ### para que se genere bien el .application
                                        open( PROY, "<$buildhome/$prj" );

                                        my $linea            = "";
                                        my @lineas           = ();
                                        my $versionConPuntos = $versionCO;

                                        $versionConPuntos =~ s/\_/\./g;

                                        foreach $linea (<PROY>) {
                                            $linea =~ s/^(.*)\<ApplicationVersion\>(.*)\<\/ApplicationVersion\>(.*)$/$1\<ApplicationVersion\>$versionConPuntos\<\/ApplicationVersion\>$3/;
                                            push( @lineas, $linea );
                                        }
                                        $log->debug( "Fichero $buildhome/$prj modificado", join( "\n", @lineas ) );
                                        close(PROY);
                                        open( PROY, ">$buildhome/$prj" );
                                        print PROY foreach (@lineas);
                                        close(PROY);
                                    }
                                    $log->info("Nueva version clickOnce a publicar: $versionCO");
                                    open( PROY, "<$buildhome/$prj" );

                                    my $linea  = "";
                                    my @lineas = ();

                                    for my $linea (<PROY>) {
                                        $linea =~ s/^(.*)\<PublishUrl\>(.*)\<\/PublishUrl\>(.*)$/$1\<PublishUrl\>$url\<\/PublishUrl\>$3/;
                                        $linea =~ s/^(.*)\<UpdateUrl\>(.*)\<\/UpdateUrl\>(.*)$/$1\<UpdateUrl\>$url\<\/UpdateUrl\>$3/;
                                        $linea =~ s/^(.*)\<InstallUrl\>(.*)\<\/InstallUrl\>(.*)$/$1\<InstallUrl\>$url\<\/InstallUrl\>$3/;
                                        $linea =~ s/^(.*)\<OutputPath\>(.*)\<\/OutputPath\>(.*)$/$1\<OutputPath\>bin\\Release\\\<\/OutputPath\>$3/;
                                        $linea =~ s/^(.*)\<AssemblyName\>(.*)\<\/AssemblyName\>(.*)$/$1\<AssemblyName\>$2${EntornoCO}\<\/AssemblyName\>$3/;
                                        push( @lineas, $linea );
                                    }
                                    $log->debug( "Fichero $buildhome/$prj modificado", join( "\n", @lineas ) );
                                    close(PROY);
                                    open( PROY, ">$buildhome/$prj" );
                                    print PROY foreach (@lineas);
                                    close(PROY);

                                    # a ver si hay algo que copiar

                                    ## SI HAY VERSIONES ANTERIORES ...
                                    $log->debug( "Comando para comprobar si hay algo que copiar: " . qq{cd "$directorio"; ls -rt *} );
                                    ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$directorio"});

                                    if ( $RC eq 0 ) {
                                        ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$directorio"; ls -rt *});

                                        if ( $RC eq 0 ) {
                                            my $TipoPase = $self->tipo_pase;
                                            if ( ( $TipoPase eq "N" ) and ( $Entorno eq "PROD" ) ) {
                                                my $directorioGuardar = "$directorio";
                                                my $dirLocal          = "$buildhome/$subAplicacion/BACKUP";
                                                my $tipoBackup        = "COA";

                                                my $NetbackupCOAveces = $self->net_backup_coa_veces;
                                                $NetbackupCOAveces++;
                                                $self->net_backup_coa_veces($NetbackupCOAveces);

                                                ## COMPROBAMOS DE QUE SOLO SE REALIZA UN NETBACKUPCOA POR PASE
                                                if ( $NetbackupCOAveces == 1 ) {
                                                    ## LLAMAMOS A netBackupCOA QUE ES UNA VARIANTE DE netBackup
                                                    try {
                                                        $self->netBackupCOA( $UNIXharax, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno );
                                                    }
                                                    catch {
                                                        my $sigoSinBackup = $self->sigo_sin_backup;
                                                        if ( $sigoSinBackup =~ m/N/i ) {    ##ups, tengo que parar el pase
                                                            _throw "Pase cancelado por no poder realizar el backup de la versión anterior (aplicación $CAM configurada para no permitir continuar el pase sin backup): " . shift();
                                                        }
                                                        else {
                                                            $log->warn("No se ha podido realizar el backup de la aplicación $CAM. El pase continúa (aplicación $CAM configurada para permitir continuar el pase sin backup)");
                                                            $log->debug( "Razón para no haber podido hacer el backup: " . shift() );
                                                        }
                                                    }
                                                }
                                                else {
                                                    $log->debug(" No se hace netBackupCOA por que ya se ha realizado anteriormente ");
                                                }
                                            }

                                            ## BORRO TODAS LAS VERSIONES CLICKONCE EN SERVIDOR EXCEPTO LAS 2 MAS RECIENTES
                                            ## (o lo que ponga la variable de distribuidor $clickonce_mantiene)
                                            ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$directorio"; ls -d -t ${prjNameNoExt}${EntornoCO}_*});    ## ordenadas por fecha, más recientes primero
                                            if ( $RC eq 0 ) {
                                                my @dirs               = split( /\n/, $RET );
                                                my $cnt                = 0;
                                                my $clickonce_mantiene = $self->clickonce_mantiene;
                                                my $mantieneCO         = $clickonce_mantiene;
                                                $mantieneCO = 2 if ( !$mantieneCO );
                                                $log->debug("Clickonce Apache: buscando versiones para borrar, manteniendo las $mantieneCO últimas...");
                                                foreach my $verCO (@dirs) {
                                                    if ( ( $cnt >= $mantieneCO ) && ( length($verCO) > 1 ) ) {
                                                        $log->debug("Clickonce Apache: borro la versión $verCO ($servidor:$directorio/$verCO)");
                                                        ( $RC, $RET ) = $UNIXharax->execute(qq{rm -Rf "$directorio/$verCO"});
                                                        if ( $RC eq 0 ) {
                                                            $log->debug( "Clickonce Apache: borrada la versión $verCO" . "\n$RET" );
                                                        }
                                                        else {
                                                            $log->debug( "Clickonce Apache: ERROR al borrar la versión $verCO (RC=$RC)" . "\n$RET" );
                                                        }
                                                    }
                                                    else {
                                                        $log->debug("Clickonce Apache: se mantiene la versión $verCO ($servidor:$directorio/$verCO)");
                                                    }
                                                    $cnt++;
                                                }
                                            }
                                            else {
                                                $log->debug(qq!Clickonce Apache: no he encontrado carpetas de versiones para borrar: cd "$directorio"; ls -d -t ${prjNameNoExt}${EntornoCO}_${versionCO}_* !);
                                            }

                                            ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
                                            my $tarExecutable;
                                            my $tardestinosaix = $self->tardestinosaix;
                                            ( $RC, $RET ) = $UNIXharax->execute(qq! ls '$tardestinosaix' !);
                                            if ( $RC ne 0 ) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
                                                $log->debug( "Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina." . "\n$RET" );
                                                $tarExecutable = "tar";
                                            }
                                            else {
                                                $log->debug( "Esta máquina dispone de tar especial de IBM. Lo usamos." . "\n$RET" );
                                                $tarExecutable = $tardestinosaix;
                                            }

                                            ## TAREO EL CONTENIDO DEL DIRECTORIO DE DESTINO
                                            my $temp_harax = $self->temp_harax;
                                            $log->debug( "Comando de empaquetado del directorio: " . qq!cd "$directorio"; $tarExecutable cvf "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar"! );
                                            ( $RC, $RET ) = $UNIXharax->execute(qq!cd "$directorio"; $tarExecutable cvf "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar" *!);
                                            if ( $RC ne 0 ) {
                                                $log->error( "Error al generar copia del contenido del directorio clickonce (RC=$RC)" . "\n$RET" );
                                                _throw "Error al generar copia del contenido del directorio clickonce";
                                            }

                                            ## RECUPERO EL FICHERO TAR QUE ACABO DE GENERAR
                                            ( $RC, $RET ) = $UNIXharax->getFile( "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar", "$buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar" );
                                            if ( $RC ne 0 ) {
                                                $log->error( "Error transferir el fichero $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar (RC=$RC)" . "\n$RET" );
                                                _throw "Error al generar copia del contenido del directorio clickonce";
                                            }

                                            ## BORRO EL TAR TEMPORAL
                                            ( $RC, $RET ) = $UNIXharax->execute(qq!rm "$temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar"!);
                                            if ( $RC ne 0 ) {
                                                $log->error( "Error borrar el fichero $temp_harax/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar (RC=$RC)" . "\n$RET" );
                                                _throw "Error al generar copia del contenido del directorio clickonce";
                                            }

                                            ## CREAMOS LOS DIRECTORIOS DE SALIDA DE LA PUBLICACIÓN POR SI NO EXIXTEN YA
                                            if ( !( -e "$buildhome/$prjPath/bin" ) ) {
                                                mkdir "$buildhome/$prjPath/bin";
                                                mkdir "$buildhome/$prjPath/bin/release";
                                            }
                                            elsif ( !( -e "$buildhome/$prjPath/bin/release" ) ) {
                                                mkdir "$buildhome/$prjPath/bin/release";
                                            }

                                            ## CREAMOS EL DIRECTORIO PUBLISH
                                            mkdir "$buildhome/$prjPath/bin/release/${prjNameNoExt}${EntornoCO}.publish";

                                            ## DESCOMPRIMIMOS EL FICHERO TAR CON EL CONTENIDO ACTUAL DEL DIRECTORIO DE DESTINO
                                            my $gnutar = $self->gnutar;
                                            $RET = `cd "$buildhome/$prjPath/bin/release/${prjNameNoExt}_${Entorno}.publish"; $gnutar xvf "$buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar"`;
                                            $log->info( "Copiado contenido actual del directorio de publicación clickonce" . "\n$RET" );

                                            ## SI NO HAY DIRECTORIO DE BACKUP, LO CREO
                                            $RET = `mkdir "$buildhome/$subAplicacion/backup"`;

                                            ## USO EL DIRECTORIO ACTUAL COMO BACKUP DE LA APLICACIÓN PARA ROLLBACK
                                            $RET = `mv "$buildhome/${Pase}-$CAM-$subAplicacion-$Sufijo-CO.tar" "$buildhome/$subAplicacion/backup/COA.tar"`;
                                            ( $RC, $RET ) = $UNIXharax->end;
                                        }
                                    }
                                    else {
                                        $log->info("No se realiza backup tipo COA al no haber contenido en el servidor destino.");
                                    }

                                    ## COPIAMOS EL RESULTADO DE LA PUBLICACIÓN PARA SU DISTRIBUCIÓN POSTERIOR
                                    $copys .= qq!
                                        <mkdir dir="$destpasedir\\$subAplicacion\\COA"/>
                                        <tar destfile="$destpasedir\\$subAplicacion\\COA\\COA.tar">
                                            <fileset basedir="${releaseDir}/${prjNameNoExt}${EntornoCO}.publish">
                                                <include name="**/*"/>
                                            </fileset>
                                        </tar>
                                !;

                                    ## LA PUBLICACIÓN SE FIRMARÁ CON EL CERTIFICADO SIGUIENTE Y SU HUELLA DIGITAL
                                    my ( $certificadoClickOnce, $huellaDigital ) = $self->ObtenerCertificadoDigital();

                                    ## OBTENEMOS LA FECHA DE EXPIRACIÓN DEL CERTIFICADO DIGITAL Y
                                    ## LA GUARDAMOS EN LA BASE DE DATOS
                                    $self->RegistrarPublicacionClickOnce( $CAM, $subAplicacion, $Entorno, $certificadoClickOnce, $Pase, $balix );

                                    ## EJECUTAMOS LA PUBLICACIÓN
                                    $solutions .= qq{
                                <exec program="\$\{msBuild.exe\}" output="msbuild_publish_log.xml" failonerror="true">
                                        <arg value="$sln"/>
                                        <arg value="/t:publish"/>
                                        <arg line="/p:Configuration=\$\{configuration\};UpdateURL=$url;UpdateMode=Foreground;UpdateEnabled=true;PublishURL=$url;InstallUrl=$url;WebPage=publish.htm;CreateWebPageOnPublish=true;ApplicationVersion=$versionCO;GenerateApplicationManifest=true;GenerateDeploymentManifest=true;ManifestCertificateThumbprint=$huellaDigital;ManifestKeyFile=$certificadoClickOnce"/>
                                </exec>                         
                                };
                                    $dirsCopia{"COA"} = 1;

                                    # antes de aquí
                                }
                            }
                        }
                    }
                }

                $copyPublicas .= qq{
                    <copy todir="$destpasedir\\$subAplicacion\\PAC">
                        <fileset basedir="$prjPath/PAC">
                            <include name="**/*"/>
                        </fileset>
                    </copy> 
                    <copy todir="$destpasedir\\$subAplicacion\\STRONGNAME">
                        <fileset basedir="$prjPath/STRONGNAME">
                            <include name="**/*"/>
                        </fileset>
                    </copy>                                     
                };
                ## Cambiamos los hintpath del fichero de proyecto
                #$log->debug("Cambiando fichero de proyecto $buildhome/$prj");
                ## Cambiamos el por si acaso el directorio de salida de compilación por :
                ## \$dirbase\script o por \bin\release segun .

                open( PROY, "<$buildhome/$prj" );

                my $linea        = "";
                my @lineas       = ();
                my @webDirBin    = ();
                my $iiswebdirbin = $self->iiswebdirbin;
                @webDirBin    = split( ",", $iiswebdirbin );
                my $dir          = "";
                if ( $slnVersion eq "2003" ) {
                    foreach $linea (<PROY>) {
                        $linea =~ s/^(.*)HintPath = \"(.*)\\(.*?)\".*$/$1HintPath = \"$destpasedir\\$subAplicacion\\PAC\\$3\"/;
                        if ( $linea =~ /OutputPath/i ) {
                            my $lineacambiada = 0;
                            foreach $dir (@webDirBin) {
                                if ( $linea =~ /\\$dirsBase\\$dir\\<\/OutputPath>/i ) {
                                    $linea         = $linea;
                                    $lineacambiada = 1;
                                    last;
                                }
                            }

                            if ( $lineacambiada == 0 ) {
                                $linea =~ s/^(.*)OutputPath = \"(.*)\"(.*)$/$1OutputPath = \"bin\\Release\\\"$3/;
                            }
                        }
                        push( @lineas, $linea );
                    }
                }
                else {
                    foreach $linea (<PROY>) {
                        $linea =~ s/^(.*)\<HintPath\>(.*)\\(.*?)\<\/HintPath\>.*$/$1\<HintPath\>$destpasedir\\$subAplicacion\\PAC\\$3\<\/HintPath\>/;
                        if ( $linea =~ /OutputPath/i ) {
                            my $lineacambiada = 0;
                            foreach $dir (@webDirBin) {

                                if ( $linea =~ /\\$dirsBase\\$dir\\<\/OutputPath>/i ) {
                                    $linea         = $linea;
                                    $lineacambiada = 1;
                                    last;
                                }
                            }
                            if ( $lineacambiada == 0 ) {
                                $linea =~ s/^(.*)\<OutputPath\>(.*)\<\/OutputPath\>(.*)$/$1\<OutputPath\>bin\\Release\\\<\/OutputPath\>$3/;
                            }
                        }
                        push( @lineas, $linea );
                    }
                }

                ##$log->debug("Fichero $buildhome/$prj modificado", join("\n",@lineas));
                close(PROY);
                open( PROY, ">$buildhome/$prj" );
                print PROY foreach (@lineas);
                close(PROY);

                ## Vamos a cambiar el path del AssemblyKeyFile en caso de que haya fichero AssemblyInfo.xx (vb ó cs)

                my $ficheroInfo = "";
                if ( -e "$buildhome/$prjPath/AssemblyInfo.cs" ) {
                    $ficheroInfo = "$buildhome/$prjPath/AssemblyInfo.cs";
                }

                if ( -e "$buildhome/$prjPath/AssemblyInfo.vb" ) {
                    $ficheroInfo = "$buildhome/$prjPath/AssemblyInfo.vb";
                }

                if ($ficheroInfo) {
                    open( PROY, "<$ficheroInfo" );

                    my $linea  = "";
                    my @lineas = ();

                    foreach $linea (<PROY>) {
                        $linea =~ s/^(.*)AssemblyKeyFile\(\"(.*)\\(.*?)/$1AssemblyKeyFile\(\"$destpasedir\\$subAplicacion\\STRONGNAME\\$3/;
                        push( @lineas, $linea );
                    }
                    $log->debug( "Fichero $ficheroInfo modificado", join( "\n", @lineas ) );
                    close(PROY);
                    open( PROY, ">$ficheroInfo" );
                    print PROY foreach (@lineas);
                    close(PROY);
                }
            }    ## foreach $prj

            if ($esAplicacionPublica) {
                $copys .= qq{
                    <mkdir dir="$destpasedir\\$subAplicacion\\PUB"/>                        
                    <tar destfile="$destpasedir\\$subAplicacion\\PUB\\$release.tar">
                        $filesets
                        <fileset basedir="$destpasedir\\$subAplicacion\\FAD">
                            <include name="**/*"/>
                        </fileset>                      
                    </tar>                          
                };
                $dirsCopia{"PUB"} = 1;
            }

            # ES UNA APLICACIÓN WEB LUEGO TENEMOS QUE COPIAR LO QUE HAY EN EL RAIZ
            if ( $esAplicacionWeb and $dirsCopia{"SW"} ) {

                # COPIAMOS LAS DLL DINAMICAS DE LOS ASMX Y ASPX AL DIRECTORIO BIN
                foreach $dirBase (@dirsWebBase) {
                    if ($dirBase) {
                        $dirBase .= "/";
                    }
                    $copys .= qq!
                            <copy todir="$slnPath/${dirBase}bin" flatten="true">
                                <fileset basedir="$slnPath/PrecompiledWeb">
                                    <include name="**/*.dll"/>
                                </fileset>
                            </copy>
                    !;
                    foreach (@webDirs) {
                        if ( $_ eq "bin" ) {
                            $copys .= qq{
                                <copy todir="$destpasedir\\$subAplicacion\\SW\\$_">
                                    <fileset basedir="$slnPath/$dirBase$_">
                                        <include name="*"/>
                                        <exclude name="*.pdb"/>
                                    </fileset>
                                </copy> 
                                <copy todir="$destpasedir\\$subAplicacion\\SW\\$_">
                                    <fileset basedir="$slnPath/$dirBase$_/Release">
                                        <include name="*"/>
                                        <exclude name="*.pdb"/>
                                    </fileset>
                                </copy>                     
                            }
                        }
                        elsif ( $_ eq "srvweb" ) {
                            $copys .= qq{
                                <copy todir="$destpasedir\\$subAplicacion\\SW\\$_">
                                    <fileset basedir="$slnPath/$dirBase$_">
                                        <include name="**/*"/>                                      
                                        <exclude name="*.vb"/>
                                        <exclude name="*.cs"/>
                                    </fileset>
                                </copy>                     
                            }
                        }
                        else {
                            $copys .= qq{
                                <copy todir="$destpasedir\\$subAplicacion\\SW\\$_">
                                    <fileset basedir="$slnPath/$dirBase$_">
                                        <include name="**/*"/>
                                    </fileset>
                                </copy>                     
                            };
                        }
                    }
                    $copys .= qq{
                        <copy todir="$destpasedir\\$subAplicacion\\SW\\">
                            <fileset basedir="$slnPath/$dirBase">
                                <include name="Global.asax"/>
                                <include name="*.Config"/>                          
                                <include name="default.html"/>
                                <include name="default.htm"/>
                            </fileset>
                        </copy>                     
                    };
                }
            }

            ##### COMPROBACION DE APLICACIONES PUBLICAS OBSOLETAS

            # my %aplPublicas_VEROBS = getAplicacionesPublicasNetFORM($CAM);
            my %aplPublicas_VEROBS = $inf->get_aplicaciones_publicas_net_form;
            $log->debug( "Comprobación de versiones públicas del formulario: " . join( ",", keys %aplPublicas_VEROBS ) );
            my $verPublicaNET = "";
            foreach $verPublicaNET ( keys %aplPublicas_VEROBS ) {
                my $ESTADO = "";

                # my @EstadoVerPubNET = VersionPublicaObsoleta($verPublicaNET);
                my @EstadoVerPubNET = $inf->obsolete_public_version($verPublicaNET);
                foreach $ESTADO (@EstadoVerPubNET) {
                    if ( $ESTADO eq "Obsoleto" ) {
                        $log->warn("La version publica  $verPublicaNET  esta en estado OBSOLETO, por favor, actualice el formulario de la aplicación");
                    }
                    elsif ( $ESTADO eq "Borrado" ) {
                        $log->warn("La versión pública $verPublicaNET ha sido borrada por los responsables de la aplicación, si su pase hace uso de esta versión fallará el pase");
                        $log->warn("Si necesita utilizar la versión pública $verPublicaNET ,por favor pongase en contacto con los Responsables de la aplicación");
                    }
                }
            }

            ##### APLICACIONES PUBLICAS

            # my %aplPublicas = getAplicacionesPublicasNet($CAM);
            my %aplPublicas = $inf->get_aplicaciones_publicas_net;

            $slnPath =~ s/\//\\/;

            my $stawindirpublico = $self->stawindirpublico;
            $copyPublicas .= qq!
                <copy todir="$destpasedir\\$subAplicacion\\PAC">
                    <fileset basedir="$stawindirpublico\\PUB">
                        <include name="**/*"/>
                    </fileset>
                </copy>                     
            !;

            if (%aplPublicas) {
                $log->debug( "Utilizando aplicaciones públicas: " . join( ",", keys %aplPublicas ) );
                my $apl = "";
                foreach $apl ( keys %aplPublicas ) {
                    $log->debug("Insertando copy de la aplicacion publica $apl, version $aplPublicas{$apl}");
                    $copyPublicas .= qq!
                        <copy todir="$destpasedir\\$subAplicacion\\PAC" overwrite="true">
                            <fileset basedir="$stawindirpublico\\$apl\\$aplPublicas{$apl}">
                                <include name="**/*"/>
                            </fileset>
                        </copy>                     
                    !
                }
            }

        }
    }
    else {

        # ESTAMOS FRENTE A UNA APLICACIÓN WEB DESARROLLADA EN WEB DEVELOPER. SOLAMENTE GENERAMOS LOS COPYS
        $log->debug("No se ha identificado ninguna solución .NET.  Tratando aplicación WEB");
        my @globalasaFiles = `cd "$buildhome"; find . -name "global.asa"`;
        my $asa;

        foreach $asa (@globalasaFiles) {
            chop $asa;
            my $asaPath = $asa;
            $asaPath =~ s/(.*)\/(.*?)$/$1/g;
            foreach (@webDirs) {
                $copys .= qq{
                    <copy todir="$destpasedir\\$subAplicacion\\SW\\$_">
                        <fileset basedir="$asaPath/$dirBase$_">
                            <include name="**/*"/>
                            <exclude name="*.pdb"/>
                        </fileset>
                    </copy>                     
                }
            }
            $copys .= qq{
                <copy todir="$destpasedir\\$subAplicacion\\SW">
                    <fileset basedir="$asaPath">
                        <include name="Global.asax"/>
                        <include name="*.config"/>                          
                        <include name="global.asa"/>
                        <include name="default.html"/>
                        <include name="default.htm"/>
                    </fileset>
                </copy>                     
            };
            $dirsCopia{"SW"} = 1;
        }

        #$framework = "IIS";
        $esIIS = "Si";

        #INFAUMX ENERO 2010
        # my ($versFramework) = getInfSub( $CAM, $subAplicacion, "VERSION_FRAMEWORK" );
        my $versFramework = $inf->get_inf( { sub_apl => $subAplicacion }, [ { column_name => 'NET_VERS_FRAMEWORK' } ] );
        _log "my \$versFramework = \$inf->get_inf({sub_apl => $subAplicacion}, [{column_name => 'NET_VERS_FRAMEWORK'}]);\n" . "versFramework: $versFramework";
        $log->debug("Versión de Framework detectada para $CAM y $subAplicacion es $versFramework ");

        $framework = "net-" . $versFramework;
        if ( $framework eq "net-" ) {

            # infaumx enero 2010
            my $ultverframework = $self->ultverframework;
            $framework = $ultverframework;
            $log->warn("No se ha encontrado la versión del framework con la que se tiene que compilar. Por favor, actualice el formulario. Por defecto, se procede a compilar con $framework");
        }

        #FIN

    }

    ## VAMOS A GENERAR EL FICHERO DE BUILD
    my $templates = $self->templates;
    _log "templates: $templates";
    open( BUILD, "<$templates/default.build" ) || _throw("No he podido abrir el fichero default.build");
    local $/;
    my $buildFile = <BUILD>;    # Línea a línea
    $log->debug( "Contenido de la plantilla de build", $buildFile );
    close BUILD;

    # my $buildxml = qq|$buildFile|;

      my $buildxml = qq¿$buildFile¿;
          eval '$buildxml = qq¿' . $buildFile . '¿';    # Sustituimos las variables de la plantilla

    open( BUILDXML, ">$buildhome/${CAM}_${subAplicacion}.build" )
        or die "No he podido crear el fichero de build '$buildhome/${CAM}_${subAplicacion}.build': $!";
    print BUILDXML $buildxml;
    close BUILDXML;
    $log->info( "Fichero '<b>${CAM}_${subAplicacion}.build</b>' generado.", $buildxml );

    return ( $framework, "${CAM}_${subAplicacion}.build", \@prjFiles, %dirsCopia );
}

sub restoreNET {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );
    my ( $EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subAplicacion ) = @_;

    $log->debug("restoreNet con estos datos: $EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subAplicacion ");

    #_throw "No se ha podido recuperar un backup corrector de la aplicación";
    my $localdir = $PaseDir . "/restore";
    mkdir $localdir;

    #print "He creado el directorio local $localdir\n";

    my %BACKUPS = get_backups( $EnvironmentName, $Entorno, $Sufijo, $localdir, $subAplicacion );
    if (%BACKUPS) {
        print "Tengo ficheros de backup\n";
    }
    my $cnt = 0;

    if ( keys %BACKUPS eq 0 ) {
        $log->error("Restore: no hay backups disponibles para marcha atrás en la aplicación $EnvironmentName($subAplicacion)->$Entorno");
        _throw "Restore: no hay backups disponibles para marcha atrás en la aplicación $EnvironmentName($subAplicacion)->$Entorno";
    }

    foreach my $localfilename ( keys %BACKUPS ) {
        $log->debug("Tratando el fichero $localfilename\n");
        $cnt++;
        my ( $bakPase, $localfile, $tipo, $rootPath ) = @{ $BACKUPS{$localfilename} };
        if ( $localfile && -e $localfile ) {
            $log->debug("El fichero $localfilename existe\n");

            # COMPROBAMOS SI ES DE TIPO COA , PUES EL RESTORE SE REALIZA DISTINO AL SER APACHE

            if ( $localfilename eq "COA.tar" ) {
                $log->debug("El fichero $localfilename es de tipo COA de Clickonce-APACHE\n");
                my $CAM = $EnvironmentName;

                ## BUSCAMOS LA RED EN LA QUE HAY QUE DISTRIBUIR
                my $subMasPrefijo = "";

                my $cam = $self->cam;
                if ( uc( ${cam} ) eq uc( ${subAplicacion} ) ) {
                    $subMasPrefijo = uc( ${cam} );
                }
                else {
                    ##$subMasPrefijo = uc("${cam}_${subAplicacion}");
                    $subMasPrefijo = uc("${subAplicacion}");
                }

                #                my ( $esLN, $esW3 ) = getInfSub( $CAM, $subMasPrefijo, "LN_WAS", "W3_WAS" );
                my @dist_nets = map {m/\$\[(.+)\]/} @{ $inf->get_inf( { sub_apl => $subMasPrefijo }, [ { column_name => 'JAVA_SUBAPL_RED' } ] ) };
                my $prj = $self->prj;

                #
                #                if ( $esLN eq "No" && $esW3 eq "No" ) {
                #                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha especificado la red (Red Interna o Internet) en el formulario de infraestructura");
                #                    _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                #                }
                #
                #                if ( $esLN eq "Si" && $esW3 eq "Si" ) {
                #                    $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache y se ha especificado ambas redes (Red Interna e Internet) en el formulario de infraestructura");
                #                    _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                #                }
                #                my $PaseRed;
                #
                #                if ( $esLN eq "Si" ) {
                #                    $PaseRed = "LN";
                #                    $log->info("La aplicación se distribuirá en Red Interna");
                #                }
                #                else {
                #                    $PaseRed = "W3";
                #                    $log->info("La aplicación se distribuirá en Internet");
                #                }
                ## RECUPERO EL SERVIDOR DE DESTINO

                for my $PaseRed (@dist_nets) {

                    # my ( $servidorVar, $nombreServer ) = getInfUnixServer( $CAM, $Entorno, "HTTP", $PaseRed );
                    my ( $servidorVar, $nombreServer ) = $inf->get_inf_unix_server( { ent => $Entorno, red => $PaseRed, tipo => 'HTTP' } );
                    _log "my (\$servidorVar, \$nombreServer) = \$inf->get_inf_unix_server({ent => $Entorno, red => $PaseRed, tipo => 'HTTP'});\n" . "servidorVar: $servidorVar\n" . "nombreServer: $nombreServer";

                    $log->debug("Servidor recuperado de la infraestructura=$servidorVar");

                    if ( !$servidorVar ) {
                        $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha encontrado el servidor HTTP en la infraestructura AIX");
                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                    }

                    ## TRADUCIMOS LA VARIABLE DEL SERVIDOR
                    # my $servidor = infResolveVars( $servidorVar, $CAM, $Entorno );
                    my $resolver = BaselinerX::Ktecho::Inf::Resolver->new( { cam => $CAM, entorno => $Entorno, sub_apl => 'foo' } );
                    my $servidor = $resolver->get_solved_value($servidorVar);
                    _log "servidor: $servidor";

                    ## RECUPERAMOS EL DIRECTORIO DE DESTINO
                    # my $directorio = getInfUnixServerDir( $CAM, $Entorno, $nombreServer, $PaseRed );
                    my $directorio = $inf->get_inf_unix_server_dir( { entorno => $Entorno, server => $nombreServer, red => $PaseRed } );
                    _log "my \$directorio = \$inf->get_inf_unix_server_dir({entorno => $Entorno, server => $nombreServer, red => $PaseRed});\n" . "directorio: $directorio";

                    if ( !$directorio ) {
                        $log->error("El proyecto $prj está catalogado como distribución <b>clickonce</b> en Apache pero no se ha encontrado directorio de aplicación en el servidor $servidor en la infraestructura AIX");
                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                    }
                    $directorio = "$directorio/" . uc($subAplicacion);
                    ## BUSCAMOS EL PUERTO HARAX DEL DESTINO
                    # my ($puerto) = getUnixServerInfo( $servidor, "HARAX_PORT" );
                    my $puerto = $inf->get_unix_server_info( { server => $servidor }, qw/HARAX_PORT/ );

                    if ( !$puerto ) {
                        $log->error("No se ha encontrado el puerto de conexión a la máquina $servidor en los datos de infraestructura");
                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                    }

                    $log->info("Abriendo conexión con agente en $servidor:$puerto");

                    # my $UNIXharax = Harax->open( $servidor, $puerto );
                    my $UNIXharax = $balix_pool->conn_port( $servidor, $puerto );

                    if ( !$UNIXharax ) {
                        $log->error("No he podido establecer conexión con el servidor $servidor en el puerto $puerto");
                        _throw "Error al configurar distribución clickonce.  Revise los datos de infraestructura";
                    }

                    ## BORRAMOS TODAS LAS VERSIONES ANTERIORES PARA RESTAURAR LA COPIA
                    ## ($RC,$RET) = $UNIXharax->execute(qq{cd "$rootPath"; rm -Rf *});
                    ## if ($RC ne 0) {
                    ##  $log->error("Error al boorar las versiones anteriores erroneas del $rootPath ",$RET);
                    ##  _throw "Error al borrar las versiones anteriores erroneas de la ruta destino";
                    ## } else {
                    ## $log->debug("Borradas las veriones anteriores erroneas del destino $rootPath/*",$RET);
                    ## }
                    ## ENVIAMOS EL FICHERO COA.TAR RECUPERADO  AL SERVIDOR DESTINO

                    my ( $RC, $RET ) = $UNIXharax->sendFile( "$localfile", "$rootPath/COA.tar" );

                    if ( $RC ne 0 ) {
                        $log->error( "Error al enviar el fichero $localfile al destino $rootPath " . "\n$RET" );
                        _throw "Error al enviar el fichero $localfile al servidor destino";
                    }
                    else {
                        $log->debug( "Enviado el fichero $localfile al al destino $rootPath/COA.tar (RC=$RC)" . "\n$RET" );
                    }

                    # COMPROBAMOS DE QUE EL FICHERO TAR ESTA EL SERVIDOR DESTINO
                    ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$rootPath"; ls -rt *});
                    $log->debug( "El contenido de $rootPath  " . "\n$RET" );

                    # DESCOMPRIMIMOS EL FICHERO TAR EN EL SERVIDOR DESTINO

                    ## ($RC,$RET) = $UNIXharax->execute("cd /D \"$rootPath\" & tar xvf \"$rootPath/$localfilename\"");

                    ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
                    my $tarExecutable;
                    my $tardestinosaix = $self->tardestinosaix;
                    ( $RC, $RET ) = $UNIXharax->execute(qq! ls '$tardestinosaix' !);
                    if ( $RC ne 0 ) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
                        $log->debug( "Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina." . "\n$RET" );
                        $tarExecutable = "tar";
                    }
                    else {
                        $log->debug( "Esta máquina dispone de tar especial de IBM. Lo usamos." . "\n$RET" );
                        $tarExecutable = $tardestinosaix;
                    }

                    ( $RC, $RET ) = $UNIXharax->execute(qq{cd "$rootPath"; $tarExecutable xvf "$rootPath/COA.tar"});

                    if ( $RC ne 0 ) {
                        $log->error( "Error al descomprimir el fichero \"$rootPath/$localfilename\" en el servidor destino" . "\n$RET" );
                        _throw "Error al descomprimir el fichero \"$rootPath/$localfilename\" en el servidor destino";
                    }
                    else {
                        $log->debug( "Fichero $rootPath/$localfilename descomprimido" . "\n$RET" );
                    }
                    $log->debug("Fichero $localfilename restaurado correctamente en $rootPath");

                    # BORRAMOS EL FICHERO TAR EN EL SERVIDOR DESTINO
                    ( $RC, $RET ) = $UNIXharax->execute(qq{rm  "$rootPath/COA.tar"});
                    if ( $RC ne 0 ) {
                        $log->error( "Error al borrar el COA.tar del directorio $rootPath" . "\n$RET" );
                    }
                    else {
                        $log->debug( " Borrado COA.tar del directorio destino $rootPath " . "\n$RET" );
                    }
                    $log->debug("Fin del restoreNET. ");
                }
            }
            else {

                ## AQUI TRATAMOS EL RESTO DE RESTORE DE TIPO .NET

                my $stawin     = $self->stawin;
                my $stawinport = $self->stawinport;
                my $stawindir  = $self->stawindir;
                my ( $stamaq, $stapuerto, $stadir ) = ( $stawin, $stawinport, $stawindir );

                # ABRIMOS LA CONEXIÓN CON EL STAGING
                my %param = ();
                $param{OS} = "win";

                # my $balix = Harax->open( $stamaq, $stapuerto, $param{OS} );
                my $balix = $balix_pool->conn_port( $stamaq, $stapuerto );

                if ($balix) {
                    $log->debug("Conexión con $stamaq abierta en $stapuerto\n");
                }
                else {
                    _throw "Conexión con $stamaq ha fallado en $stapuerto\n";
                }

                my $destpasedir = "${stadir}\\${Pase}\\$EnvironmentName\\.NET";
                my ( $RC, $RET ) = $balix->execute("cd /D \"$destpasedir\\restore\"");
                if ( $RC ne 0 ) {
                    my ( $RC, $RET ) = $balix->execute("md \"$destpasedir\\restore\"");
                    if ( $RC ne 0 ) {
                        $log->error( "Error al crear el directorio de restore en el servidor de staging" . "\n$RET" );
                        _throw "Error al enviar el fichero $localfile al servidor de staging";
                    }
                    else {
                        $log->debug("Directorio \"$destpasedir\\restore\" creado en staging\n");
                    }
                }
                else {
                    $log->debug("Directorio \"$destpasedir\\restore\" ya estaba creado en staging\n");
                }

                #Permisos restore

                my $stawindirtemp = $self->stawindirtemp;
                my $tmpdir        = $stawindirtemp . "\\" . $Pase . "Restore";

                # DIRECTORIO TEMPORAL PARA TAR-UNTAR. DESDE AHI SE HARA UN XCOPY A LA UBICACION DE STAGING
                $log->debug("RESTORE: Variable directorio temporal para TAR-UNTAR '$tmpdir'.");
                $log->debug("Creando directorio temporal para RESTORE...");

                # ver si puedo utilizar la subrutina de utils win siendo;
                #Pase = Pase.Restore , $tarfile=$localfile
                $log->debug("Pase=$Pase");
                $log->debug("Directorio temporal en RESTORE para TAR-UNTAR $tmpdir");

                # CREAMOS EL DIRECTORIO TEMPORAL EN CASO DE NO EXISTIR
                $log->info("Creando directorio temporal para restaurar en $tmpdir...");

                my $cmd = qq| mkdir $tmpdir |;
                _log "****************";
                _log "cmd $cmd";
                _log "****************";
                ( $RC, $RET ) = $balix->execute($cmd);

                if ( $RC ne 0 ) {
                    $log->error( "Error en la ejecución de mkdir '$tmpdir' (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la preparación de la aplicación.";
                }
                else {
                    $log->debug("Creado el directorio temporal '$tmpdir' (RC=$RC)");

                    # ENVIAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE AL DIRECTORIO TEMPORAL
                    #my $tmptarfile = "$tmpdir\\${Pase}.tar";
                    my $tmptarfile = "$tmpdir\\$localfilename";
                    $log->debug("tar file=$tmptarfile");
                    ( $RC, $RET ) = $balix->sendFile( $localfile, $tmptarfile );

                    #($RC,$RET) = $balix->sendFile($tarfile, $tmptarfile);
                    #($RC,$RET) = $balix->sendFile("$localfile", "$destpasedir\\restore\\$localfilename");

                    $log->debug("TAR file en temporal (RC=$RC)");

                    # DESCOMPRIMIMOS EL FICHERO TAR EN EL TEMPORAL

                    my $stawintarexe = $self->stawintarexe;
                    ( $RC, $RET ) = $balix->execute("cd /D \"$tmpdir\" & $stawintarexe pxvf $localfilename");

                    if ( $RC ne 0 ) {
                        $log->error( "Error en al descomprimir el archivo TAR (RC=$RC)" . "\n$RET" );
                        _throw "Error durante la preparación de la aplicación.";
                    }
                    else {
                        $log->debug( "UNTAR en temporal '$tmpdir' (RC=$RC)" . "\n$RET" );
                    }

                    # BORRAMOS EL FICHERO TAR EN TEMPORAL Y COPIAMOS EL CONTENIDO DEL TEMPORAL EN EL DIRECTORIO DESTINO DE STAGING
                    if ( $RC eq 0 ) {
                        ( $RC, $RET ) = $balix->execute("del \"$tmptarfile\"");
                        if ( $RC ne 0 ) {
                            $log->error( "Error en la eliminación del tar '$tmptarfile' (RC=$RC)" . "\n$RET" );
                            _throw "Error durante la preparación de la aplicación.";
                        }

                        # HACEMOS UN XCOPY /E /I (/E copia los subdir incluso si están vacíos) (/I destino dir)
                        #HACIA EL DIRECTORIO DESTINO EN STAGING PARA CONSERVAR LA HERENCIA DE PERMISOS
                        #($RC,$RET) = $balix->execute("xcopy /E /I /Y /S /R \"$tmpdir\" \"$destpasedir\"");
                        $log->debug("xcopy /E /I /Y /S /R $tmpdir $destpasedir\\restore");
                        ( $RC, $RET ) = $balix->execute("xcopy /E /I /Y /S /R \"$tmpdir\" \"$destpasedir\\restore\"");

                        if ( $RC ne 0 ) {
                            $log->error( "Error en la ejecución de xcopy /E /I /Y /S /R '$tmpdir' '$destpasedir' (RC=$RC). Se procede a eliminar el contenido del temporal." . "\n$RET" );

                            # BORRAMOS TODO EL CONTENIDO QUE HUBIERA DEL DIRECTORIO TMP
                            ( $RC, $RET ) = $balix->execute("rmdir /s/q \"$tmpdir\"");
                            if ( $RC ne 0 ) {
                                $log->error( "Error en el borrado del directorio temporal o de su contenido '$tmpdir' (RC=$RC)" . "\n$RET" );
                            }
                            else {
                                $log->debug( "Ha ocurrido un error en el xcopy por lo que se ha eliminado el directorio temporal '$tmpdir' y su contenido (RC=$RC)" . "\n$RET" );
                            }
                            _throw "Error durante la preparación de la aplicación.";
                        }
                        else {
                            $log->debug( "Se ha copiado el contenido UNTAR de '$tmpdir' a '$destpasedir' (RC=$RC)" . "\n$RET" );

                            # BORRAMOS TODO EL CONTENIDO DEL DIRECTORIO TMP
                            ( $RC, $RET ) = $balix->execute("rmdir /s/q \"$tmpdir\"");
                            if ( $RC ne 0 ) {
                                $log->error( "Error en el borrado del directorio temporal o de su contenido '$tmpdir' (RC=$RC)" . "\n$RET" );
                                _throw "Error durante la preparación de la aplicación.";
                            }
                            else {
                                $log->debug( "Se ha eliminado el directorio temporal '$tmpdir' y su contenido (RC=$RC)" . "\n$RET" );
                            }
                        }
                    }
                }

                # end - Permisos restore

                # COPIAMOS EL CONTENIDO DEL TAR EN EL SERVIDOR DESTINO
                #($RC,$RET) = $balix->execute("xcopy /E /Y /S /K /R \"$destpasedir\\restore\\*.*\" \"$rootPath\"");
                ( $RC, $RET ) = $balix->execute("xcopy /E /Y /S /R \"$destpasedir\\restore\\*.*\" \"$rootPath\"");
                $log->debug("Comando de copia: xcopy /E /Y /S /R \"$destpasedir\\restore\\*.*\" \"$rootPath\"");
                if ( $RC ne 0 ) {
                    $log->error( "Error al restaurar el contenido del fichero $localfilename en $rootPath" . "\n$RET" );
                    _throw "Error al restaurar el contenido del fichero $localfilename en $rootPath";
                }
                else {
                    $log->info( "Fichero $localfilename restaurado correctamente en $rootPath" . "\n$RET" );
                }
            }
        }
        else {
            ##fichero no existe, señal de que el fichero restore no estaba en DISTBAK
            _throw "Restore: no existe un fichero de backup para $EnvironmentName->$Entorno.";
        }
    }
}

sub netBackup {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );

    my ( $balix, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno ) = @_;
    my $ficheroTar = "$tipoBackup.tar";
    $log->debug("Haciendo backup de tipo $tipoBackup");
    $log->debug("directorioGuardar=$directorioGuardar, dirLocal=$dirLocal,  tipoBackup=$tipoBackup, subAplicacion=$subAplicacion,  EnvironmentName=$EnvironmentName, Entorno=$Entorno");
    my ( $RC, $RET ) = $balix->execute("md \"$dirLocal\\backup\\$tipoBackup\"");
    if ( $RC eq 0 ) {
        $log->debug( "Subdirectorio creado: \"$dirLocal\\backup\\$tipoBackup\"" . "\n$RET" );
    }
    else {
        $log->warn( "Error al crear el directorio de backup ($dirLocal\\backup\\$tipoBackup\) en el servidor de compilación. (RC=$RC)" . "\n$RET" );
        _throw "Error al crear el directorio de backup ($dirLocal\\backup\\$tipoBackup\) en el servidor de compilación. (RC=$RC)";
    }
    ( $RC, $RET ) = $balix->execute("xcopy /E /Y /S /K /R \"$directorioGuardar\\*.*\" \"$dirLocal\\backup\\$tipoBackup\"");
    if ( $RC eq 0 ) {
        $log->debug( "Copiado el contenido del directorio \"$directorioGuardar\\*.*\"" . "\n$RET" );
    }
    else {
        $log->warn( "Error al copiar el contenido del directorio de destino ($directorioGuardar\\*.*)" . "\n$RET" );
        _throw "Error al copiar el contenido del directorio de destino ($directorioGuardar\\*.*). (RC=$RC)";
    }
    my $stawintarexe = $self->stawintarexe;
    $log->debug("Construyendo el tar... cd /D \"$dirLocal\\backup\\$tipoBackup\" & $stawintarexe cvf ..\\$ficheroTar *");
    ( $RC, $RET ) = $balix->execute("cd /D \"$dirLocal\\backup\\$tipoBackup\" & $stawintarexe cvf ..\\$ficheroTar *");

    if ( $RC eq 0 ) {
        $log->debug( "Fichero $ficheroTar generado corretamente" . "\n$RET" );
    }
    else {
        $log->warn( "Error al generar el fichero de copia de seguridad $ficheroTar. (RC=$RC)" . "\n$RET" );
        _throw "Error al generar el fichero de copia de seguridad $ficheroTar. (RC=$RC)";
    }

    ( $RC, $RET ) = $balix->execute("rd /S /Q \"$dirLocal\\backup\\$tipoBackup\"");

    if ( $RC eq 0 ) {
        $log->debug( "Directorio \"$dirLocal\\backup\\$tipoBackup\" borrado" . "\n$RET" );
    }
    else {
        $log->warn( "Error al eliminar el directorio de backup ($dirLocal\\backup\\$tipoBackup\) en el servidor de compilación. (RC=$RC)" . "\n$RET" );
        _throw "Error al eliminar el directorio de backup ($dirLocal\\backup\\$tipoBackup\) en el servidor de compilación. (RC=$RC)";
    }

    ( $RC, $RET ) = $balix->getFile( "$dirLocal\\backup\\$ficheroTar", "$buildhome/$ficheroTar", "win" );
    if ( $RC eq 0 ) {
        $log->debug( "Fichero de backup ($ficheroTar) recuperado" . "\n$RET" );
    }
    else {
        $log->warn( "Error al recuperar el fichero de backup ($ficheroTar). (RC=$RC)" . "\n$RET" );
        _throw "Error al recuperar el fichero de backup ($ficheroTar). (RC=$RC)";
    }

    try {
        my ( $idBack, $dataSize ) = store_backup( $EnvironmentName, $Entorno, $subAplicacion, ".NET", $Pase, $tipoBackup, "$buildhome/$ficheroTar", $directorioGuardar );

        # $log->infoext "Backup realizado (Fichero:$ficheroTar contiene <b>$dataSize KB</b>)", $idBack;
        $log->info( "Backup realizado (Fichero:$ficheroTar contiene <b>$dataSize KB</b>)", $idBack );
    }
    catch {
        _throw "Error al guardar el fichero de backup en la base de datos: " . shift();
    }
}

sub netBackupCOA {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );
    my ( $RC, $RET );
    my ( $UNIXharax, $directorioGuardar, $dirLocal, $tipoBackup, $subAplicacion, $buildhome, $Pase, $EnvironmentName, $Entorno ) = @_;
    my $ficheroTar = "$tipoBackup.tar";

    $log->debug("Haciendo backup de tipo $tipoBackup");

    ## CREO EL DIRECTORIO DE BACKUP POR SI NO EXITE
    $RET = `mkdir "$dirLocal"`;

    ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
    my $tarExecutable;

    my $tardestinosaix = $self->tardestinosaix;
    ( $RC, $RET ) = $UNIXharax->execute(qq! ls '$tardestinosaix' !);
    if ( $RC ne 0 ) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
        $log->debug( "Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina." . "\n$RET" );
        $tarExecutable = "tar";
    }
    else {
        $log->debug( "Esta máquina dispone de tar especial de IBM. Lo usamos." . "\n$RET" );
        $tarExecutable = $tardestinosaix;
    }

## EMPAQUETO EN UN TAR EL CONTENIDO DEL DIRECTORIO DE DESTINO
    my $temp_harax = $self->temp_harax;
    $log->debug( "Comando de empaquetado del directorio: " . qq!cd "$directorioGuardar"; $tarExecutable cvf "$temp_harax/${Pase}-$ficheroTar"! );
    ( $RC, $RET ) = $UNIXharax->execute(qq!cd "$directorioGuardar"; $tarExecutable cvf "$temp_harax/${Pase}-$ficheroTar" *!);
    if ( $RC eq 0 ) {
        $log->debug( "Empaquetado el directorio de clickonce $directorioGuardar " . "\n$RET" );
    }
    else {
        $log->warn( "Error al generar el fichero de copia de seguridad ${Pase}-$ficheroTar (RC=$RC)" . "\n$RET" );
        _throw "Error al generar el fichero de copia de seguridad ${Pase}-$ficheroTar (RC=$RC)";
    }
## RECUPERO EL FICHERO TAR QUE ACABO DE GENERAR
    ( $RC, $RET ) = $UNIXharax->getFile( "$temp_harax/${Pase}-$ficheroTar", "$dirLocal/$ficheroTar" );
    if ( $RC ne 0 ) {
        $log->error( "Error transferir el fichero $temp_harax/${Pase}-$ficheroTar (RC=$RC)" . "\n$RET" );
        _throw "Error al generar copia del contenido del directorio clickonce";
    }

## BORRO EL TAR TEMPORAL
    ( $RC, $RET ) = $UNIXharax->execute(qq!rm "$temp_harax/${Pase}-$ficheroTar"!);
    if ( $RC ne 0 ) {
        $log->error( "Error borrar el fichero $temp_harax/${Pase}-$ficheroTar (RC=$RC)" . "\n$RET" );
        _throw "Error al generar copia del contenido del directorio clickonce";
    }

    try {
        my ( $idBack, $dataSize ) = store_backup( $EnvironmentName, $Entorno, $subAplicacion, ".NET", $Pase, $tipoBackup, "$dirLocal/$ficheroTar", $directorioGuardar );

        # $log->infoext "Backup realizado (Fichero:$ficheroTar contiene <b>$dataSize KB</b>)", $idBack;
        $log->info( "Backup realizado (Fichero:$ficheroTar contiene <b>$dataSize KB</b>)", $idBack );
    }
    catch {
        _throw "Error al guardar el fichero de backup en la base de datos: " . shift();
    }
}

sub ObtenerCertificadoDigital {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );

    ## LA PUBLICACIÓN SE FIRMARÁ CON EL CERTIFICADO SIGUIENTE Y SU HUELLA DIGITAL
    my $stawincert           = $self->stawincert;
    my $certificadoClickOnce = "$stawincert";
    my $stawincerthuella     = $self->stawincerthuella;
    my $huellaDigital        = "$stawincerthuella";

    $log->debug("El certificado para la publicación es $certificadoClickOnce");
    $log->debug("Su huella digital es $huellaDigital");

    return ( $certificadoClickOnce, $huellaDigital );
}

sub RegistrarPublicacionClickOnce {
    my $self            = shift;
    my $log             = $self->log;
    my $inf             = BaselinerX::Model::InfUtil->new( cam => $self->cam );
    my $stawinobtfecexp = $self->stawinobtfecexp;

    my ( $CAM, $subAplicacion, $Entorno, $certificadoClickOnce, $Pase, $balix ) = @_;

    ## OBTENEMOS LA FECHA DE EXPIRACIÓN DEL CERTIFICADO DIGITAL
    my $ComandoObtenerFecha = "$stawinobtfecexp \"$certificadoClickOnce\"";
    $log->debug( "Obteniendo fecha de expiración del certificado digital...", $ComandoObtenerFecha );
    my ( $RC, $RET ) = $balix->execute($ComandoObtenerFecha);

    if ( $RC ne 0 ) {
        $log->warn( "Error al obtener la fecha de expiración del certificado $certificadoClickOnce (RC=$RC) " . "\n$RET" );
    }
    else {
        $log->debug("Fecha de expiración del certificado $RET (RC=$RC)");
        my $FechaExpiracion = $RET;

        $FechaExpiracion =~ s/[\r|\n|C]//g;

        ## GUARDAMOS EN LA BASE DE DATOS LA FECHA DE EXPIRACIÓN DEL CERTIFICADO DIGITAL
        my $ffffecha = ahoralog();
        my $sql      = qq{
                      BEGIN
                         dist_registar_publicacion ('$CAM',
                                                    '$subAplicacion',
                                                    '$Entorno',
                                                    TO_DATE ('$ffffecha',
                                                             'YYYYMMDDHH24MISS'
                                                            ),
                                                    TO_DATE ('$FechaExpiracion',
                                                             'DD/MM/YYYY HH24:MI:SS'
                                                            ),
                                                    '$Pase'
                                                   );
                      END;
        };
        my $har            = BaselinerX::CA::Harvest::DB->new;
        my $filasAfectadas = $har->db->do($sql);

        if ( $filasAfectadas < 1 ) {
            $log->warn( "No se pudo registrar en la base de datos la publicación ClickOnce y la fecha de expiración del certificado", $DBI::err );
        }
    }
}

# EL COMANDO DEL NO BORRA LOS SUBDIRECTORIOS DE $ENV{IISWEBDIRS)
# IMPORTANTE: NO PODEMOS BORRAR LOS $ENV{IISWEBDIRS) YA QUE TIENEN DEFINIDOS PERMISOS
sub BorrarSubdirectorios {
    my $self = shift;
    my $log  = $self->log;
    my $inf  = BaselinerX::Model::InfUtil->new( cam => $self->cam );

    my ( $maquinaDestino, $directorioDestino, $dirAplicacion, $balix ) = @_;

    $log->debug("Inicio borrado subdirectorios...");

    my @webDirs    = ();
    my $iiswebdirs = $self->iiswebdirs;
    @webDirs = split( ",", $iiswebdirs );

    my $DirectorioBorrado = "";
    my $ComandoBorrado    = "";
    my ( $RC, $RET );

    foreach (@webDirs) {
        $DirectorioBorrado = "\\\\$maquinaDestino\\$directorioDestino\\$dirAplicacion\\$_";
        $ComandoBorrado    = "For /D %i In ($DirectorioBorrado\\*) Do RmDir %i /s /q";

        $log->debug("Comando de borrado de subdirectorios de $_: $ComandoBorrado");

        ( $RC, $RET ) = $balix->execute($ComandoBorrado);
        if ( $RC ne 0 ) {
            $log->error( "Error al borrar subdirectorios en $DirectorioBorrado (RC=$RC)" . "\n$RET" );
            _throw "Error durante el borrado de subdirectorios en $DirectorioBorrado.";
        }
        else {
            $log->debug( "Subdirectorios borrados de $_ (RC=$RC)" . "\n$RET" );
        }
    }
    $log->debug("Fin borrado subdirectorios.");
}

sub doUntarAndRestorePermission {
    my $self = shift;
    my $log  = $self->log;
    my ( $Pase, $harax, $tarfile, $destpasedir ) = @_;

    # DIRECTORIO TEMPORAL PARA TAR-UNTAR. DESDE AHI SE HARA UN XCOPY A LA UBICACION DE STAGING
    my $tmpdir = $self->stawindirtemp . "\\" . $Pase;
    $log->debug("Variable directorio temporal para TAR-UNTAR '$tmpdir'.");
    $log->debug("Directorio temporal para TAR-UNTAR '$tmpdir'");

    # CREAMOS EL DIRECTORIO TEMPORAL EN CASO DE NO EXISTIR
    $log->info("Creando directorio temporal en $tmpdir...");
    my $cmd = qq| mkdir $tmpdir |;
    _log "cmd: $cmd";
    my ( $RC, $RET ) = $harax->execute($cmd);
    if ( $RC > 2 ) {
        $log->error( "Error en la ejecución de mkdir '$tmpdir' (RC=$RC)" . "\n$RET" );
        _throw "Error durante la preparación de la aplicación.";
    }
    else {
        $log->debug("Creado el directorio temporal '$tmpdir' (RC=$RC)");

        # ENVIAMOS EL FICHERO TAR CON EL CONTENIDO DEL PASE AL DIRECTORIO TEMPORAL
        my $tmptarfile = "$tmpdir\\${Pase}.tar";
        ( $RC, $RET ) = $harax->sendFile( $tarfile, $tmptarfile );
        $log->debug("TAR file en temporal (RC=$RC)");

        # DESCOMPRIMIMOS EL FICHERO TAR EN EL TEMPORAL
        my $stawintarexe = $self->stawintarexe;
        ( $RC, $RET ) = $harax->execute("cd /D \"$tmpdir\" & $stawintarexe pxvf ${Pase}.tar");
        if ( $RC ne 0 ) {
            $log->error( "Error en al descomprimir el archivo TAR (RC=$RC)" . "\n$RET" );
            _throw "Error durante la preparación de la aplicación.";
        }
        else {
            $log->debug( "UNTAR en temporal '$tmpdir' (RC=$RC)" . "\n$RET" );
        }

        # BORRAMOS EL FICHERO TAR EN TEMPORAL Y COPIAMOS EL CONTENIDO DEL TEMPORAL EN EL DIRECTORIO DESTINO DE STAGING
        if ( $RC eq 0 ) {
            ( $RC, $RET ) = $harax->execute("del \"$tmptarfile\"");
            if ( $RC ne 0 ) {
                $log->error( "Error en la eliminación del tar '$tmptarfile' (RC=$RC)" . "\n$RET" );
                _throw "Error durante la preparación de la aplicación.";
            }

            # HACEMOS UN XCOPY /E /I (/E copia los subdir incluso si están vacíos) (/I destino dir)
            #HACIA EL DIRECTORIO DESTINO EN STAGING PARA CONSERVAR LA HERENCIA DE PERMISOS
            #($RC,$RET) = $harax->execute("xcopy \"$tmpdir\" \"$destpasedir\" /e /i");
            ( $RC, $RET ) = $harax->execute("xcopy /E /I /Y /S /R \"$tmpdir\" \"$destpasedir\"");
            if ( $RC ne 0 ) {
                $log->error( "Error en la ejecución de xcopy /E /I /Y /S /R '$tmpdir' '$destpasedir' (RC=$RC). Se procede a eliminar el contenido del temporal." . "\n$RET" );

                # BORRAMOS TODO EL CONTENIDO QUE HUBIERA DEL DIRECTORIO TMP
                ( $RC, $RET ) = $harax->execute("rmdir /s/q \"$tmpdir\"");
                if ( $RC ne 0 ) {
                    $log->error( "Error en el borrado del directorio temporal o de su contenido '$tmpdir' (RC=$RC)" . "\n$RET" );
                }
                else {
                    $log->debug( "Ha ocurrido un error en el xcopy por lo que se ha eliminado el directorio temporal '$tmpdir' y su contenido (RC=$RC)" . "\n$RET" );
                }
                _throw "Error durante la preparación de la aplicación.";
            }
            else {
                $log->debug( "Se ha copiado el contenido UNTAR de '$tmpdir' a '$destpasedir' (RC=$RC)" . "\n$RET" );

                # BORRAMOS TODO EL CONTENIDO DEL DIRECTORIO TMP
                ( $RC, $RET ) = $harax->execute("rmdir /s/q \"$tmpdir\"");
                if ( $RC ne 0 ) {
                    $log->error( "Error en el borrado del directorio temporal o de su contenido '$tmpdir' (RC=$RC)" . "\n$RET" );
                    _throw "Error durante la preparación de la aplicación.";
                }
                else {
                    $log->debug( "Se ha eliminado el directorio temporal '$tmpdir' y su contenido (RC=$RC)" . "\n$RET" );
                }
            }
        }
    }
}

1;

