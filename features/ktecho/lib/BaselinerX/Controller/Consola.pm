package BaselinerX::Controller::Consola;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use BaselinerX::BdeUtils;
use Baseliner::Utils;
use BaselinerX::Ktecho::Utils;
use Switch;
use Try::Tiny;
use YAML;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

sub index : Local {
    my ( $self, $c ) = @_;

    my $env_name = $c->request->parameters->{env_name};
    my $env      = $c->request->parameters->{env};
    my $sub_apl  = $c->request->parameters->{sub_apl};
    my $op       = $c->request->parameters->{operator};
    my $user     = $c->username;
    my %ficheros_creados = ();

    my $log = new_log_form( 'Consola de Aplicaciones J2EE',
                            { format => 1,
                              warn   => 1 } );

    my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');
    my $consola_timeout = $config_bde->{consola_timeout} || 180;

    # Carpeta remota temporal donde estara el fichero.tar
    my $rem_tmp    = $config_bde->{consola_tempdir};

    my $gnutar     = $config_bde->{gnutar};
    my $was_script = $config_bde->{was_script};
    my $dirlocal   = $config_bde->{temp};

    # logstart("HARDIST","INT",1);

    # Hago la purga por si acaso...
    # $c->model('Purga')->purga_consola(1);

#    try {
        local $SIG{ALRM} = sub {
            die $log->("Timeout:\n
                Se ha sobrepasado el tiempo fijado ($consola_timeout) para la operacion");
        };
        alarm $consola_timeout;

        $log->("Inicio de peticion de usuario");

        # Verifica el  estado de preceso (compruebo si no  hay otro proceso de
        # lo mismo en ejecucion).
        my @process_status = `ps -ef|grep consola|grep -v $$|grep -v grep`;

        foreach (@process_status) {
            if (/consola\.pl (\w*) (\w*) (\w*) (\w*) (\w*)/) {
                my ( $cam2, $env2, $sa2, $user2, $op2 ) = ( $1, $2, $3, $4, $5 );

                # print "CC=[$cam2,$env2,$sa2,$user2,$op2]\n";
                if ( ( $env_name eq $cam2 ) && ( $env eq $env2 ) && ( $op eq $op2 ) ) {
                    $log->("Ya se esta ejecutando una operacion $op en $env_name->$env");
                    $log->("** Lanzada por el usuario '$user2' para la subaplicacion '$sa2'");
                    $log->("** Espere algunos instantes y vuelva a intentarlo");
                    exit 1;
                }
            }
        }

        #logprintmode 1;

        my ( $cam, $cam_uc ) = get_cam_uc($env_name);

        my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $env_name } );
        my $red = $inf_db->get_inf_subred( $env, $sub_apl );

        if ( $op eq "LOGWAS" ) {
            my $new_env = ( $env =~ m/^T/xi ) ? 'T'     # Si es TEST...
                        : ( $env =~ m/^A/xi ) ? 'A'     # Si es ANTE...
                        : ( $env =~ m/^P/xi ) ? 'P'     # Si es PROD...
                        :                       'G'     # Si es General...
                        ;
            my %destino = $inf_db->get_inf_destinos($new_env, $sub_apl);

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            ) or $log->("Error al abrir la conexion con agente en $destino{maq}:$destino{puerto}");

            my $path_waslogdir = q{};
            my $dir_waslogdir  = q{};
            my $dest_waslogdir = q{};

            my %path = $inf_db->get_inf(
                { sub_apl => $sub_apl },
                [   {   column_name => 'WAS_LOG_PATH',
                        idred       => $destino{red},
                        ident       => $new_env
                    },
                    {   column_name => 'WAS_DIR_LOG_APPSERVER',
                        idred       => $destino{red},
                        ident       => $new_env
                    }
                ]
            );

            $path_waslogdir = $path{WAS_LOG_PATH};
            $dir_waslogdir  = $path{WAS_DIR_LOG_APPSERVER};
            $dest_waslogdir = "$path_waslogdir/$dir_waslogdir";

            if ( $dir_waslogdir eq q{} ) {
                $log->("*** E R R O R ***\n
                    El campo Directorio de Log del AppServer del formulario esta vacio\n
                    No se puede traer log de WAS, rellene la ruta en el campo del formulario\n
                    *** E R R O R ***") or die $log->("Directorio de log de AppServer Invalido");
            }

            #  Cambio   realizado   por   q74313x   por   creacion  del  campo
            #      ${env}_WAS_DIR_LOG_APprocess_statusERVER       --      eval
            #'$dest_waslogdir="'.$ENV{WASLOGPATH}.'"';
            #"/tmp/log/was/was$destino{was_ver}/".$cam;

            $log->("Accediendo a $destino{maq} : $dest_waslogdir para recoger los LOGS");
            $log->("Ubicacion de ficheros de log de WAS: $dest_waslogdir");

            my $filename_pr = "$op-$sub_apl-$destino{maq}-PR-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";

            $ficheros_creados{$filename_pr}{fichero} = $filename_pr;
            $ficheros_creados{$filename_pr}{maquina} = $destino{maq};
            $ficheros_creados{$filename_pr}{port}    = $destino{puerto};

            my $ret = $c->model('Consola')->get_tar_dir(
                {   balix      => $balix,
                    dir_remoto => $dest_waslogdir,
                    dir_local  => $dirlocal,
                    fichero    => $filename_pr,
                    rem_tmp    => $rem_tmp
                }
            );

            if ($ret) {
                $log->("$dirlocal/$filename_pr transferido con exito");
            }
            else {
                $log->("Error al generar el fichero TAR $filename_pr");
            }
            $balix->end();

            ## JRL Logs de Cluster
            my $filename_sc;
            my $tiene_cluster;

            # tiene cluester asociado , por lo que sigo como siempre ...
            if ( $destino{server_cluster} ) {
                my ($puerto) = $inf_db->get_unix_server_info(
                    {   server  => $destino{server_cluster},
                        sub_apl => $sub_apl,
                        env     => substr( $env, 0, 1 )
                    },
                    qw{ HARAX_PORT }
                );

                $tiene_cluster = {
                    maq    => $destino{server_cluster},
                    puerto => $puerto,
                };
            }
            elsif ( uc($env) =~ /ANTE/i ) {

                # No  Tiene cluster asociado  y el entorno  es ANTE por  lo el
                # servidor  es el mismo que  el primario  , pero  con distinta
                # ruta
                $tiene_cluster = {
                    maq    => $destino{maq},
                    puerto => $destino{puerto},
                };
            }
            else {
                $log->("No tengo cluster");
            }
            if ($tiene_cluster) {
                my ( $maquina, $puerto ) = ( $tiene_cluster->{maq}, $tiene_cluster->{puerto}, );

                my $balix2 = BaselinerX::Comm::Balix->new(
                    host => $maquina,
                    port => $puerto,
                    test => 'hello world',
                    key  => Baseliner->model('ConfigStore')->get('config.harax')->{$puerto}
                ) or $log->("Error al abrir la conexion con agente en $maquina:$puerto");

                alarm 0;    ## reseteamos el timeout
                alarm $consola_timeout;

                # Cambio  realizado  por   q74313x  por  creacion  del  campo
                # ${env}_WAS_DIR_LOG_APprocess_statusER_CLUST --
                # eval '$dest_waslogdir="'.$ENV{WASLOGPATH}.'"';
                # "/tmp/log/was/was$destino{was_ver}/".$cam;

                my $dest_waslogdir_cluster = q{};
                my $dir_waslogdir_cluster  = q{};

                $dir_waslogdir_cluster = $inf_db->get_inf(
                    undef,
                    [   {   column_name => 'WAS_DIR_LOG_APPSER_CLUST',
                            ident       => $env,
                            idred       => $destino{red}
                        }
                    ]
                );

                $dest_waslogdir_cluster = "$path_waslogdir$dir_waslogdir_cluster";

                if ( $dir_waslogdir_cluster eq q{} ) {
                    $log->("*** E R R O R ***\n
                        El campo Directorio de Log del AppServer del cluster del formulario esta
                        vacio\n
                        No se puede traer log del cluster de WAS, rellene la ruta en el campo del
                        formulario\n
                        *** E R R O R ***");
                }
                else {
                    $log->("Accediendo a $maquina : $dest_waslogdir_cluster para recoger los
                        LOGS");
                    $log->("Ubicacion de ficheros de log de WAS: $dest_waslogdir_cluster");

                    $filename_sc = "$op-$sub_apl-$maquina-SC-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";
                    $ficheros_creados{$filename_sc}{fichero} = $filename_sc;
                    $ficheros_creados{$filename_sc}{maquina} = $maquina;
                    $ficheros_creados{$filename_sc}{port}    = $puerto;

                    my $ret = $c->model('Consola')->get_tar_dir(
                        {   dir_remoto => $dest_waslogdir_cluster,
                            balix      => $balix2,
                            dir_local  => $dirlocal,
                            fichero    => $filename_sc,
                            rem_tmp    => $rem_tmp
                        }
                    );

                    if ($ret) {
                        $log->("$dirlocal/$filename_sc transferido con exito");
                    }
                    else {
                        $log->("Error al generar el fichero TAR $filename_sc");
                    }

                    $balix2->end();
                }
            }

            # finalizamos la entrega de logs
            my $tarfile = "$op-$sub_apl-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";

            $ret = `cd $dirlocal ; $gnutar cvf $tarfile $op-$sub_apl*`;

            if ($ret) {
                no strict;
                my $id = $c->model('Consola')->write_bin_log(
                    {   dbh      => $dbh,
                        pase     => "consola-$op",
                        filedir  => $dirlocal,
                        filename => $tarfile,
                        cam      => $env_name
                    }
                );
                $log->("CONSOLAID=$id");
            }
            else {
                $log->("Error creando TAR $tarfile");
            }

            $filename_pr && unlink "$dirlocal/$filename_pr";
            $filename_sc && unlink "$dirlocal/$filename_sc";
            unlink "$dirlocal/$tarfile";
        } # END LOGWAS
        elsif ( $op eq "LOGAPL" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            ) or $log->("Error al abrir la conexion con agente en $destino{maq}:$destino{puerto}");

            my $dest_waslogdir = $destino{was_log_dir};

            # chequeo que no es / o /xxxx
            ( $dest_waslogdir && length($dest_waslogdir) > 5 )
                or die "Directorio de log de aplicacion invalido $dest_waslogdir";

            $log->("Accediendo a $destino{maq} : $dest_waslogdir para recoger los LOGS");
            $log->("Ubicacion de ficheros de log de aplicacion: $dest_waslogdir");

            my $filename_pr = "$op-$sub_apl-$destino{maq}-PR-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";
            $ficheros_creados{$filename_pr}{fichero} = $filename_pr;
            $ficheros_creados{$filename_pr}{maquina} = $destino{maq};
            $ficheros_creados{$filename_pr}{port}    = $destino{puerto};

            # Nota:  directo a 0 por que algunos generan tar gigante --- > los
            # LOGAPL  hay que traerlos  siempre se pone  a 1  , algunos  no se
            # encuentran
            my $ret = $c->model('Consola')->get_tar_dir(
                {   balix      => $balix,
                    directo    => 0,
                    dir_remoto => $dest_waslogdir,
                    dir_local  => $dirlocal,
                    fichero    => $filename_pr,
                    rem_tmp    => $rem_tmp
                }
            );

            if ($ret) {
                $log->("$dirlocal/$filename_pr transferido con exito");
            }
            else {
                $log->("Error al generar el fichero TAR $filename_pr");
            }
            $balix->end();

            ## JRL Logs de Cluster
            my $filename_sc;
            if ( length( $destino{server_cluster} ) > 0 ) {    ## Tiene cluster asociado
                my ($puerto) = $inf_db->get_unix_server_info(
                    {   server  => $destino{server_cluster},
                        sub_apl => $sub_apl,
                        env     => substr( $env, 0, 1 )
                    },
                    qw{ HARAX_PORT }
                );

                my $balix2 = BaselinerX::Comm::Balix->new(
                    host => $destino{server_cluster},
                    port => $puerto,
                    key  => Baseliner->model('ConfigStore')->get('config.harax')->{$puerto}
                );

                $dest_waslogdir = $destino{was_log_dir};

                # chequeo que no es / o /xxxx
                ( $dest_waslogdir && length($dest_waslogdir) > 5 )
                    or die "Directorio de log de aplicacion invalido $dest_waslogdir";

                $log->("Accediendo a $destino{server_cluster} : $dest_waslogdir para recoger los LOGS");
                $log->("Ubicacion de ficheros de log de aplicacion: $dest_waslogdir");

                $filename_sc =
                    "$op-$sub_apl-$destino{server_cluster}-SC-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";
                $ficheros_creados{$filename_sc}{fichero} = $filename_sc;
                $ficheros_creados{$filename_sc}{maquina} = $destino{server_cluster};
                $ficheros_creados{$filename_sc}{port}    = $puerto;

                # Nota:  Directo a 0 por que algunos generan tar gigante --- >
                # los LOGAPL hay que traerlos siempre se pone a 1 , algunos no
                # se encuentran
                my $ret = $c->model('Consola')->get_tar_dir(
                    {   balix      => $balix2,
                        directo    => 0,
                        dir_remoto => $dest_waslogdir,
                        dir_local  => $dirlocal,
                        fichero    => $filename_sc
                    }
                );

                if ($ret) {
                    $log->("$dirlocal/$filename_sc transferido con exito");
                }
                else {
                    $log->("Error al generar el fichero TAR $filename_sc");
                }
                $balix2->end();
            }

            my $tarfile = "$op-$sub_apl-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";
            $ret = `cd $dirlocal ; $gnutar cvf $tarfile $op-$sub_apl*`;
            if ($ret) {
                no strict;
                my $id = $c->model('Consola')->write_bin_log(
                    {   dbh      => $dbh,
                        pase     => "consola-$op",
                        filedir  => $dirlocal,
                        filename => $tarfile,
                        cam      => $env_name
                    }
                );
                $log->("CONSOLAID=$id");
            }
            else {
                $log->("Error creando TAR $tarfile");
            }
            $filename_pr && unlink "$dirlocal/$filename_pr";
            $filename_sc && unlink "$dirlocal/$filename_sc";
            unlink "$dirlocal/$tarfile";
        }
        elsif ( $op eq "CONFIG" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            );
            my $dirrem = $destino{config_dir};

            $log->("Accediendo a $destino{maq} : $dirrem para recoger los fichero de configuracion");
            $log->("Ubicacion de ficheros de config de la aplicacion: $dirrem");

            my $filename_pr = "$op-$sub_apl-$destino{maq}-PR-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";

            $ficheros_creados{$filename_pr}{fichero} = $filename_pr;
            $ficheros_creados{$filename_pr}{maquina} = $destino{maq};
            $ficheros_creados{$filename_pr}{port}    = $destino{puerto};

            # Nota:  directo  a '1',  a los  config hay que  traerlos siempre,
            # algunos son de hace mucho tiempo
            my $ret = $c->model('Consola')->get_tar_dir(
                {   balix      => $balix,
                    directo    => 1,
                    dir_remoto => $dirrem,
                    dir_local  => $dirlocal,
                    fichero    => $filename_pr,
                    rem_tmp    => $rem_tmp
                }
            );

            if ($ret) {
                $log->("$dirlocal/$filename_pr transferido con exito");
            }
            else {
                $log->("Error al generar el fichero TAR $filename_pr");
            }

            $balix->end();

            my $filename_sc;

            # Tiene cluster asociado
            if ( length( $destino{server_cluster} ) > 0 ) {
                my $puerto = $inf_db->get_unix_server_info(
                    {   server  => $destino{server_cluster},
                        sub_apl => $sub_apl,
                        env     => substr( $env, 0, 1 )
                    },
                    qw{ HARAX_PORT }
                );

                my $balix2 = BaselinerX::Comm::Balix->new(
                    host => $destino{server_cluster},
                    port => $puerto,
                    key  => Baseliner->model('ConfigStore')->get('config.harax')->{$puerto}
                );

                my $dirrem = $destino{config_dir};

                $log->("Accediendo a $destino{server_cluster} : $dirrem para recoger los fichero de configuracion");
                $log->("Ubicacion de ficheros de config de la aplicacion: $dirrem");

                $filename_sc =
                    "$op-$sub_apl-$destino{server_cluster}-SC-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";
                $ficheros_creados{$filename_sc}{fichero} = $filename_sc;
                $ficheros_creados{$filename_sc}{maquina} = $destino{server_cluster};
                $ficheros_creados{$filename_sc}{port}    = $puerto;
                # a los config hay que traerlos siempre, algunos son de hace mucho tiempo
                my $ret = $c->model('Consola')->get_tar_dir(
                    {   balix      => $balix2,
                        directo    => 1,
                        dir_remoto => $dirrem,
                        dir_local  => $dirlocal,
                        fichero    => $filename_sc,
                        rem_tmp    => $rem_tmp
                    }
                );
                if ($ret) {
                    $log->("$dirlocal/$filename_sc transferido con exito");
                }
                else {
                    $log->("Error al generar el fichero TAR $filename_sc");
                }
                $balix2->end();
            }

            my $tarfile = "$op-$sub_apl-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";

            $ret = `cd $dirlocal ; $gnutar cvf $tarfile $op-$sub_apl*`;

            if ($ret) {
                no strict;
                my $id = $c->model('Consola')->write_bin_log(
                    {   dbh      => $dbh,
                        pase     => "consola-$op",
                        filedir  => $dirlocal,
                        filename => $tarfile,
                        cam      => $env_name
                    }
                );
                $log->("CONSOLAID=$id");
            }
            else {
                $log->("Error creando TAR $tarfile");
            }

            $filename_pr && unlink "$dirlocal/$filename_pr";
            $filename_sc && unlink "$dirlocal/$filename_sc";
            unlink "$dirlocal/$tarfile";
        }
        elsif ( $op eq "CONFIGLS" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            );
            my $dirrem = $destino{config_dir};
            my $filename_pr;
            $log->("Accediendo a $destino{maq} : $dirrem para sacar listado de los ficheros de configuracion");
            $log->("Ubicacion de ficheros de config de la aplicacion: $dirrem");
            my ( $rc, $ret ) = $balix->executeas( $destino{was_user}, "find -H '$dirrem' -ls " );
            if ( $rc ne 0 ) {
                $log->("Error: no se ha podido realizar el 'ls' del directorio $destino{maq}:$dirrem : $ret ");
            }
            else {
                $filename_pr = "$op-$sub_apl-$destino{maq}-PR-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".html";
                open FF, ">$dirlocal/$filename_pr";
                $log->("$ret");
                print FF "<PRE>$ret";
                close FF;
            }
            $balix->end();

            my $filename_sc;

            # Tiene cluster asociado
            if ( length( $destino{server_cluster} ) > 0 ) {
                my ($puerto) = $inf_db->get_unix_server_info(
                    {   server  => $destino{server_cluster},
                        sub_apl => $sub_apl,
                        env     => substr( $env, 0, 1 )
                    },
                    qw{ HARAX_PORT }
                );
                my $balix2 = BaselinerX::Comm::Balix->new(
                    host => $destino{server_cluster},
                    port => $puerto,
                    key  => Baseliner->model('ConfigStore')->get('config.harax')->{$puerto}
                );
                my $dirrem = $destino{config_dir};

                $log->("Accediendo a $destino{server_cluster} : $dirrem para sacar listado de los ficheros de configuracion");
                $log->("Ubicacion de ficheros de config de la aplicacion: $dirrem");
                my ( $rc, $ret ) =
                    $balix2->executeas( $destino{was_user}, "find -H '$dirrem' -ls " );
                if ( $rc ne 0 ) {
                    $log->("Error: no se ha podido realizar el 'ls' del directorio $destino{server_cluster}:$dirrem: $ret");
                }
                else {
                    $filename_sc =
                          "$op-$sub_apl-$destino{server_cluster}-SC-"
                        . BaselinerX::Comm::Balix->ahora_log() . "-"
                        . $$ . ".html";
                    open FF, ">$dirlocal/$filename_sc";
                    $log->("$ret");
                    print FF "<PRE>$ret";
                    close FF;
                }
                $balix2->end();
            }

            my $tarfile = "$op-$sub_apl-" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".tar";
            $ret     = `cd $dirlocal ; $gnutar cvf $tarfile $op-$sub_apl*`;
            if ($ret) {
                no strict;
                my $id = $c->model('Consola')->write_bin_log(
                    {   dbh      => $dbh,
                        pase     => "consola-$op",
                        filedir  => $dirlocal,
                        filename => $tarfile,
                        cam      => $env_name
                    }
                );
                $log->("CONSOLAID=$id");
            }
            else {
                $log->("Error creando TAR $tarfile");
            }
            $filename_pr && unlink "$dirlocal/$filename_pr";
            $filename_sc && unlink "$dirlocal/$filename_sc";
            unlink "$dirlocal/$tarfile";
        }
        elsif ( ( $op =~ /START|STOP|RESTART/ ) && ( $env eq "PROD" ) ) {
            $log->("CONSOLA: Error: La Operacion $op no esta permitida en entornos de Produccion");
        }
        elsif ( $op eq "START" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            );

            $log->( "Ejecutando $was_script $destino{was_context_root} startApplication $destino{was_ver} en la maquina $destino{maq}");

            my ( $rc, $ret ) =
                $balix->executeas( $destino{was_user},
                "$was_script $destino{was_context_root} startApplication $destino{was_ver}" );

            if ( $rc ne 0 ) {
                # es que estaba caido, no problem
                if ( $rc eq 512 ) {
                    $log->("La aplicacion ya estaba arrancada.: $ret");
                }
                else {
                    $log->("No se ha podido arrancar la aplicacion con
                        $destino{was_user}:'$was_script $destino{was_context_root} startApplication
                        $destino{was_ver}' (rc=$rc): $ret");
                }
            }
            else {
                my $dest_clone = $ret;
                $dest_clone =~ s/.*Server(.*?) *de *(.*?) *en.*/$1-$2/s;    ##););

                my $msg = "Ok. WAS <b>$dest_clone</b> iniciado "
                    . ( $rc eq 2 ? "<b>con warnings</b> " : "" )
                    . " con usuario '$destino{was_user}' (rc=$rc).";

                if   ( $rc eq 2 ) { $log->("$msg: $ret"); }
                else              { $log->("$msg: $ret"); }
            }

            $balix->end();
        }
        elsif ( $op eq "STOP" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            );

            my ( $rc, $ret ) = $balix->executeas( $destino{was_user},
                "$was_script $destino{was_context_root} stopApplication $destino{was_ver}" );

            if ( $rc ne 0 ) {
                # Es que estaba caido, no problem
                if ( $rc eq 512 ) {
                    $log->("La aplicacion ya estaba parada.: $ret");
                }
                else {
                    $log->("No se ha podido parar la aplicacion con $destino{was_user}:'$was_script $destino{was_context_root} stopApplication $destino{was_ver}' (rc=$rc): $ret");
                }
            }
            else {
                my $dest_clone = $ret;
                $dest_clone =~ s/.*Server(.*?) *de *(.*?) *en.*/$1-$2/s;    ##););
                my $msg =
                      "Ok. WAS <b>$dest_clone</b> parado "
                    . ( $rc eq 2 ? "<b>con warnings</b> " : "" )
                    . " con usuario '$destino{was_user}' (rc=$rc).";
                if   ( $rc eq 2 ) { $log->("$msg: $ret"); }
                else              { $log->("$msg: $ret"); }
            }

            $balix->end();
        }
        elsif ( $op eq "RESTART" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new( 
                host => $destino{maq}, 
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            );
            my ( $rc, $ret ) = $balix->executeas( $destino{was_user},
                "$was_script $destino{was_context_root} stopApplication $destino{was_ver}" );
            if ( $rc ne 0 ) {
                if ( $rc eq 512 ) {    # Ta muehto...
                    $log->("La aplicacion ya estaba parada : $ret");
                }
                else {
                    $log->("No se ha podido parar la aplicacion con $destino{was_user}:'$was_script $destino{was_context_root} stopApplication $destino{was_ver}' (rc=$rc): $ret");
                }
            }
            else {
                my $dest_clone = $ret;
                $dest_clone =~ s/.*Server(.*?) *de *(.*?) *en.*/$1-$2/s;
                my $msg = "Ok. WAS <b>$dest_clone</b> parado "
                    . ( $rc eq 2 ? "<b>con warnings</b> " : "" )
                    . " con usuario '$destino{was_user}' (rc=$rc).";
                if   ( $rc eq 2 ) { $log->("$msg: $ret"); }
                else              { $log->("$msg: $ret"); }
            }

            # reseteamos el timeout para que de tiempo a arrancar la aplicacion y no se quede parada
            alarm 0;
            alarm $consola_timeout;

            ( $rc, $ret ) = $balix->executeas( $destino{was_user},
                "$was_script $destino{was_context_root} startApplication $destino{was_ver}" );
            if ( $rc ne 0 ) {
                # es que estaba levantado... no problem !!
                if ( $rc eq 512 ) {    
                    $log->("La aplicacion ya estaba arrancada.: $ret");
                }
                else {
                    $log->("No se ha podido arrancar la aplicacion con $destino{was_user}:'$was_script $destino{was_context_root} startApplication $destino{was_ver}' (rc=$rc): $ret");
                }
            }
            else {
                my $dest_clone = $ret;
                $dest_clone =~ s/.*Server(.*?) *de *(.*?) *en.*/$1-$2/s;
                my $msg = "Ok. WAS <b>$dest_clone</b> iniciado "
                    . ( $rc eq 2 ? "<b>con warnings</b> " : "" )
                    . " con usuario '$destino{was_user}' (rc=$rc).";
                if   ( $rc eq 2 ) { $log->("$msg: $ret"); }
                else              { $log->("$msg: $ret"); }
            }

            $balix->end();
        }
        elsif ( $op eq "INFOWAS" ) {
            my %destino = $inf_db->get_inf_destinos( $env, $sub_apl );

            my $balix = BaselinerX::Comm::Balix->new(
                host => $destino{maq},
                port => $destino{puerto},
                key  => Baseliner->model('ConfigStore')->get('config.harax')->{ $destino{puerto} }
            );

            my ( $rc, $ret ) = $balix->executeas( $destino{was_user},
                "$was_script $destino{was_context_root} infoWAS" );

            if ( $rc ne 0 ) {
                # es que estaba caido, no problem
                if ( $rc eq 512 ) {
                    $log->("Avisos durante la ejecucion de infoWAS: $ret");
                }
                else {
                    $log->(
                        "No se ha podido ejecutar infoWAS para la aplicacion $destino{was_user}:'$was_script $destino{was_context_root} infoWAS $destino{was_ver}' (rc=$rc): $ret"
                    );
                }
            }
            else {
                my $filename = "$op-$sub_apl" . BaselinerX::Comm::Balix->ahora_log() . "-" . $$ . ".html";
                open FF, ">$dirlocal/$filename";
                $log->("$ret");
                print FF "<PRE>$ret";
                close FF;
                no strict;
                my $id = $c->model('Consola')->write_bin_log(
                    {   dbh      => $dbh,
                        pase     => "consola-$op",
                        filedir  => $dirlocal,
                        filename => $filename,
                        cam      => $env_name
                    }
                );
                $log->("CONSOLAID=$id");
                unlink "$dirlocal/$filename";
            }
            $balix->end();
        }
        else {
            $log->("CONSOLA: Operacion no reconocida: $op");
        }
#    }
#    catch {
#        print "Se ha producido un error durante la recuperacion de los ficheros de LOG: $@\n";
#        if ( $@ =~ m/Timeout/i ) {
#            foreach my $f_del ( keys %ficheros_creados ) {
#                print "Borrando $ficheros_creados{$f_del}{fichero} de la maquina"
#                    . "$ficheros_creados{$f_del}{maquina}:$ficheros_creados{$f_del}{port}\n";
#                my $conn = Harax->open( $ficheros_creados{$f_del}{maquina},
#                    $ficheros_creados{$f_del}{port} );
#
#                # Si existe $filename lo borra
#                my ( $rc, $ret ) = $conn->execute( "if [ -f $rem_tmp/$ficheros_creados{$f_del}"
#                        . "{fichero} ]; then rm $rem_tmp/$ficheros_creados{$f_del}{fichero}; fi"
#                );    
#
#                if ( $rc ne 0 ) {
#                    print "Error: no se ha podido borrar $ficheros_creados{$f_del}{fichero} de la "
#                        . "maquina $ficheros_creados{$f_del}{maquina} \n";
#                }
#                else {
#                    print "Borrado con exito $ficheros_creados{$f_del}{fichero} de la maquina"
#                        . "$ficheros_creados{$f_del}{maquina}:$ficheros_creados{$f_del}{port}\n";
#                }
#                $conn->end();
#            }
#        }
#        print "Borrando $dirlocal/$op-$sub_apl-*";
#        unlink <$dirlocal/$op-$sub_apl-*>;
#    };
    #$log->info("Consola: finalizada peticion $params.");

    #exit 0;

    $c->stash->{func}     = $op;
    $c->stash->{log}      = $log->();
    $c->stash->{template} = 'consola.html';
    $c->forward('View::Mason');

    return;
}

1;
