#===============================================================================
#
#         FILE:  AltaDistribucion.pm
#
#  DESCRIPTION:  - Verifica si los formularios de petición están correctamente
#                  cumplimentados.
#                - Crea un nuevo pase para atender la petición de distribución.
#
#        FILES:  AltaDistribucion.pm
#         BUGS:  ---
#        NOTES:  Migración de UDP/AltaDistribucion.pm
#      VERSION:  1.0
#      CREATED:  14/02/2011 10:19:58
#     REVISION:  ---
#===============================================================================

package BaselinerX::Controller::AltaDistribucion;
use strict;
use warnings;
use 5.010;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
#use BaselinerX::Ktecho::CommonVar;
BEGIN { extends 'Catalyst::Controller' }

sub start : Local {
    my ( $self, $c ) = @_;

    my %estado_entorno = (
        'Desarrollo'            => 'TEST',
        'Pruebas'               => 'TEST',
        'Preproducción'         => 'ANTE',
        'Producción'            => 'PROD',
        'Emergencia'            => 'PROD',
        'Producción Emergencia' => 'PROD',
        'Desarrollo Correctivo' => 'TEST',
        'Producción Correctivo' => 'PROD'
    );

    #TODO oconn 1;

    # my @ARGV = ();

    #FIXME Borrar: ¿Esto de dónde sale?
    # my %estado_entorno = ();
    # my $env_start_date;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my %args = ();

    # XXX Borrar luego XXX 
    my $tipo_pase           = 'N';
    my $user_name           = 'q74613x';
    my $env_name            = 'CSM';
    my $state_name          = 'Desarrollo';
    my $previous_state_name = 'Desarrollo';
    my $init_start_date     = 'now';
    my $end_start_date      = 'now';

    # Comentado por pruebas...
#    my $tipo_pase           = shift @ARGV;
#    my $user_name           = shift @ARGV;
#    my $env_name            = shift @ARGV;
#    my $previous_state_name = shift @ARGV;
#    my $state_name          = shift @ARGV;
#    my $init_start_date     = shift @ARGV;
#    my $end_start_date      = shift @ARGV;

    my $form_id;
    my $package_id;
    my $pase_id;
    my $red;
    my $pase_dir;
    my @packages = ('SCM.N-000002 pruebas de BASELINER ERIC');

    my $args_ref            = $c->model('AltaDistribucion')->set_variables_iniciales();
    my $ret                 = $args_ref->{ret};
    my $es_repeticion       = $args_ref->{es_repeticion};
    my $es_backout_pre_emer = $args_ref->{es_backout_pre_emer};
    my $modo_alta_pase      = $args_ref->{modo_alta_pase};
    my $pase_entorno        = $args_ref->{pase_entorno};

    my %dependencias = ();

    if ( substr( $tipo_pase, 0, 1 ) eq "B" ) {
        $pase_entorno = $estado_entorno{$previous_state_name};
    }
    else {
        $pase_entorno = $estado_entorno{$state_name};
    }

    my $fecha_log;

    if ( $init_start_date ne "now" ) {
        $fecha_log = $c->model('AltaDistribucion')->get_start_date($init_start_date);
    }

    #TODO 
#    if ( $env_start_date ne q//) {
#        if ( $env_start_date < ahora_log() ) {
#            die "ERROR: la fecha/hora 'hasta' ($env_start_date) ya ha pasado (ahora: "
#                . ahora_log()
#                . "). No se ha creado el pase.";
#        }
#    }

    if ( length($tipo_pase) == 2 && $tipo_pase ne "BE" ) {
        if ( substr( $tipo_pase, 1, 1 ) eq "U" ) {
            $modo_alta_pase = "G";
        }
        $tipo_pase = substr( $tipo_pase, 0, 1 );
    }

    if ( $tipo_pase eq "R" ) {    # es una repetición
        $tipo_pase     = "N";
        $es_repeticion = 1;

        my $entorno = $estado_entorno{$state_name};

        if ( $entorno eq q// ) {
            die "ERROR: no he podido determinar el nombre del entorno del pase para el estado "
                . "'$state_name'\n\n";
        }

        @packages = $c->model('AltaDistribucion')->get_packages_pase_r( $env_name, $entorno );

        if ( @packages < 1 ) {
            die "ERROR: no encuentro paquetes asignados al último pase realizado en el entorno "
                . "'$entorno'.\n\n";
        }
    }
    elsif ( $tipo_pase eq "BE" ) {
        $tipo_pase           = "B";
        $es_backout_pre_emer = 1;

        my $env_id = $har_db->get_project_id($env_name);

        @packages = $c->model('AltaDistribucion')->get_packages_pase_be( $env_id, $env_name );

        if ( @packages < 1 ) {
            print "AltaDistribucion: AVISO: no hay paquetes en Preproducción de la aplicación "
                . "$env_name para hacer backout.\n";
            exit 1;
        }
    }
    else {
        #XXX
        @packages = ('SCM.N-000002 pruebas de BASELINER ERIC');
    }

    #print "Environment name: $env_name\nEstado previo: $previous_state_name\nEstado: $state_name"
    #    . "\nTipo de pase: $tipo_pase\nPaquetes:"
    #    . join( "\n", @packages ) . "\n";

    if ( ( $state_name ne "Desarrollo" ) and ( $previous_state_name ne $state_name ) ) {
        %dependencias = get_package_dependencies( $env_name, $tipo_pase, \@packages );
        if (%dependencias) {
            print "AltaDistribucion: AVISO: Los paquetes seleccionados para el pase tienen "
                . "dependencias que no están incluidas en el pase\n";

            my $mensaje = list_package_dependencies( $env_name, $tipo_pase, \@packages );
            print $mensaje;

            exit 1;
        }
    }

    if ( $env_name =~ /\%/ ) {
        my ($first_package) = @packages;
        $env_name = $har_db->get_package_info($first_package);
    }

    # Tipo de red
    $red = $c->model('AltaDistribucion')->get_tipo_red($env_name);

    if (   ( $state_name eq "Preproducción" || $state_name eq "Producción" )
        && ( $es_backout_pre_emer eq 0 ) ) {
        my @projects = $har_db->get_packages_projects(\@packages);

        foreach (@projects) {
            %args = ( 'env_name' => $_, 'state_name' => $state_name, 'packages' => \@packages );
            my @emer_packages = $har_db->hay_emergencia( \%args );

            if (@emer_packages) {
                print "\nHay paquetes de emergencia.\n No se puede crear un pase a Preproducción o "
                    . "Producción que no los incluya\n";
                print "Paquetes: \n" . join( "\n", @emer_packages );

                $ret = 1;
            }
        }
    }

    # verifico si los paquetes están en el estado que tienen que estar - fromstate
    check_package_state_do_or_die( $env_name, $previous_state_name, @packages );

    if ( $ret eq 0 ) {
        my $estado_est;

        # Averiguo el ciclo que es para saber si es el estado OK y motrarlo bien.
        foreach my $package_name (@packages) {
            my $id_package = $har_db->get_package_id($package_name);

            my ( $nome_1, $nome_2, $ciclo_v ) =
                $c->model('AltaDistribucion')->get_ciclo($id_package);

            if ( ( $ciclo_v eq "R" ) && ( $state_name eq "Producción" ) ) {
                $estado_est = "Producción";
                say "el valor de estado_est es : $estado_est";
                say "OK. Paquetes están en su estado correspondiente: 'Pruebas'.";
            }
            elsif ( ( $ciclo_v eq "R" ) && ( $state_name eq "Preproducción" ) ) {
                $estado_est = "Pruebas";
                say "el valor de estado_est es : $estado_est";
                say "OK. Paquetes están en su estado correspondiente: 'Producción'.";
            }
            else {
                $estado_est = $state_name;
                say "OK. Paquetes están en su estado correspondiente: '$state_name'.";
            }
        }

        print "user_name: $user_name\nenv_name: $env_name\nstate_name: $estado_est\n";
        print "Iniciando proceso de distribución en pases \n";

        my $ret_global = -1;

        foreach my $package_name (@packages) {
            $ret_global = 0 if ( $ret_global eq -1 );    # Para confirmar que tenemos paquetes.
            $ret = 0;
            print "\nProcesando paquete $package_name\n";

            $package_id = $har_db->get_package_id($package_name);
            
            # Recupera los datos del paquete.
            %args = (
                'package_id'          => $package_id,
                'package_name'        => $package_name,
                'tipo_pase'           => $tipo_pase,
                'es_repeticion'       => $es_repeticion,
                'state_name'          => $state_name,
                'env_name'            => $env_name,
                'previous_state_name' => $previous_state_name
            );
            $ret += $c->model('AltaDistribucion')->datos_paquete( \%args );

            if ( $ret ne 0 ) {
                print "\n El paquete $package_name contiene errores. Corríjalos y vuelva a "
                    . "solicitar la distribución\n";
                $ret_global++;
                next;
            }
        }

        # Todas las validaciones se han realizado con éxito. El paquete se distribuirá.

        if ( $ret_global eq 0 ) {
            %args = (
                'pase_entorno'        => $pase_entorno,
                'state_name'          => $state_name,
                'env_name'            => $env_name,
                'tipo_pase'           => $tipo_pase,
                'init_start_date'     => $init_start_date,
                'modo_alta_pase'      => $modo_alta_pase,
                'user_name'           => $user_name,
                'red'                 => $red,
                'previous_state_name' => $previous_state_name,
                'end_start_date'      => $end_start_date,
                'fecha_log'           => $fecha_log
            );
            $pase_id = $c->model('AltaDistribucion')->crea_pase( \%args );

            foreach (@packages) {
                $package_id = $har_db->get_package_id($_);
                $form_id    = $har_db->get_form_id($package_id);
                %args = ( 'form_id' => $form_id, 'paquete' => $_, 'pase_id' => $pase_id );
                $c->modle('AltaDistribucion')->actualizar_paquete( \%args );
            }

            #TODO logstart( $pase_id, "DIS" );

            # Ya comentado de antes...
            # loginfo "Paquetes Harvest asignados al pase:"
            #     . "<br><img src='images/package.gif' border=0><b>"
            #     . join( "<br><img src='images/package.gif' border=0>", @packages ) . "</b>";

            $c->log->info("Paquetes Harvest asignados al pase:");

            my $motivos_pase = "<UL>";

            my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');
            my $hardist    = $config_bde->{hardist};
            my $har_db     = BaselinerX::Ktecho::Harvest::DB->new;

            foreach (@packages) {
                my ( $tipo_cambio, $detalle_cambio ) = $har_db->get_paquete_motivo($_);

                $c->log->info( "<img src='$hardist/images/package.gif' border=0><b>$_</b> "
                        . "($tipo_cambio: $detalle_cambio)" );
                j
                $motivos_pase .= "<LI><b>$_</b> <br>$tipo_cambio: $detalle_cambio</LI>\n";
            }
            $motivos_pase .= "</UL>";

=begin  BlockComment  # Código antiguo, lo dejo ahí por si acaso.

            # Escapamos las comillas simples para que no pete al hacer el siguiente UPDATE sobre el
            # Oracle.
            $motivos_pase =~ s{'}{´}g;

            odo "UPDATE DISTPASE SET PAS_MOTIVOS = '$motivos_pase' WHERE PAS_CODIGO = '$pase_id'";

=end    BlockComment

=cut

            my $update_row =
                $c->model('AltaDistribucion')->update_motivo_distpase( $pase_id, $motivos_pase );

            my @natures = $har_db->get_naturalezas_pase($pase_id);

            #TODO ocommit;

            print "\nPaquetes asignados al Pase $pase_id\n";
            $c->log->debug( "Naturalezas detectadas para el pase: " . join( ",", @natures ) );

            foreach (@natures) {
                $har_db->set_naturaleza( $pase_id, $_ );
                if ( /\.NET/i or /FICH/i or /RS/i or /BIZT/i )
                { 
                    # Las subaplicaciones java no son necesariamente el nombre de la carpeta. Y fich
                    # tampoco. En FICH hay que informar si es de tipo UNIX o WIN para filtrar
                    # permisos de RPT.
                    my @sub_apl = $har_db->get_pase_sub_apl( $pase_id, $_ );

                    foreach (@sub_apl) {
                        $har_db->set_sub_apl( $pase_id, $_ );
                    }
                }

            }

            my $inf_db = BaselinerX::Ktecho::INF::DB->new;

            if ( $pase_entorno =~ /PROD/ && !$inf_db->inf_es_publica($env_name) ) {
                my @pase_aplicaciones = $har_db->get_pass_projects($pase_id);
                try {
                    if ( $tipo_pase eq "N" ) {
                        $tipo_pase = "Normal";
                    }
                    elsif ( $tipo_pase eq "B" ) {
                        $tipo_pase = "Marcha atrás";
                    }
                    else {

                        $tipo_pase = "Emergencia";
                    }
                    close STDOUT;

=begin  BlockComment  # Nada de mandar mails ahora!  

                    envia_correo_pase(
                        PASE       => $pase_id,
                        TIPO       => $tipo_pase,
                        USUARIO    => $user_name,
                        ENTORNO    => $pase_entorno,
                        natures    => [@natures],
                        MSG        => "Aplicación $pase_aplicaciones[0] - Pase planificado",
                        ACCION     => " ha sido planificado para el $fecha_log",
                        APLICACION => $pase_aplicaciones[0],
                        ALONE      => 1
                    );

=end    BlockComment

=cut

                    open(STDOUT);
                }
                catch {
                    $c->log->warn("No se ha podido enviar el correo de inicio de pase: $_[0]");
                };
            }
        }
        else {
            print "\n\t¡No se han seleccionado paquetes!\n" if ( $ret_global eq -1 );
            print "Pase no creado.\n";

            $ret = 1;
        }
    }
    #TODO oclose;

    exit $ret;
}

1;
