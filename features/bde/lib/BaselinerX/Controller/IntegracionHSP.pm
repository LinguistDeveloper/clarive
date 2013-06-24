package BaselinerX::Controller::IntegracionHSP;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }
#:int_hsp:

sub main : Path {
    my ( $self, $c ) = @_;

    my $log_cata = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    # Hashes y arrays de proyectos
    my %proyecto_hsp      = ();
    my %proyecto_harvest  = ();
    my @proyectos_hsp     = ();
    my @proyectos_harvest = ();

    # Variables para acoger los campos del proyecto en HSP
    my $codigo_hsp       = q{};
    my $descripcion_hsp  = q{};
    my $unidad_hsp       = q{};
    my $responsables_hsp = q{};
    my $tipo_hsp         = q{};

    # Variables para acoger los campos del proyecto en Harvest
    my $harvest_id           = q{};
    my $harvest_desc         = q{};
    my $unidad_harvest       = q{};
    my $responsables_harvest = q{};
    my $harvest_type         = q{};

    # Contadores
    my $num_proyecto_hsp     = 0;
    my $num_proyecto_harvest = 0;
    my $cont_hsp             = 0;
    my $cont_harvest         = 0;
    my $num_inserted         = 0;
    my $num_updated          = 0;
    my $num_deleted          = 0;

    # Booleanos
    my $modificado = 0;

    # Variables generales
    my $sql     = q{};
    my $log     = q{};
    my $retorno = q{};

    my $config_bde     = Baseliner->model('ConfigStore')->get('config.bde');
    my $HSP_LINK       = $config_bde->{hsp_link};
    my $HSP_FRECUENCIA = $config_bde->{hsp_frecuencia};

    my $args_ref;

    while (1) {
        print BaselinerX::Comm::Balix->ahora() . " - Iniciando la carga de proyectos HSP\n";
        try {
            %proyecto_harvest = $c->model('IntegracionHSP')->read_harvest_proyects();
            %proyecto_hsp     = $c->model('IntegracionHSP')->read_hsp_proyects($HSP_LINK);

            #Construimos las listas para recorrer e inicializamos contadores
            $num_proyecto_hsp     = keys %proyecto_hsp;
            $num_proyecto_harvest = keys %proyecto_harvest;

            #print "Numero de proyectos Harvest: $num_proyecto_harvest";
            @proyectos_hsp     = sort( keys %proyecto_hsp );
            @proyectos_harvest = sort( keys %proyecto_harvest );

            $args_ref = $c->model('IntegracionHSP')->leer_hsp(
                {   cont_hsp         => $cont_hsp,
                    codigo_hsp       => $codigo_hsp,
                    descripcion_hsp  => $descripcion_hsp,
                    unidad_hsp       => $unidad_hsp,
                    responsables_hsp => $responsables_hsp,
                    tipo_hsp         => $tipo_hsp,
                    num_proyecto_hsp => $num_proyecto_hsp,
                    proyectos_hsp    => \@proyectos_hsp,
                    proyecto_hsp     => \%proyecto_hsp
                }
            );
            $codigo_hsp       = $args_ref->{codigo_hsp};
            $descripcion_hsp  = $args_ref->{descripcion_hsp};
            $unidad_hsp       = $args_ref->{unidad_hsp};
            $responsables_hsp = $args_ref->{responsables_hsp};
            $tipo_hsp         = $args_ref->{tipo_hsp};
            $cont_hsp         = $args_ref->{cont_hsp};

            $args_ref = $c->model('IntegracionHSP')->leer_harvest(
                {   cont_harvest         => $cont_harvest,
                    harvest_id           => $harvest_id,
                    harvest_desc         => $harvest_desc,
                    unidad_harvest       => $unidad_harvest,
                    responsables_harvest => $responsables_harvest,
                    harvest_type         => $harvest_type,
                    num_proyecto_harvest => $num_proyecto_harvest,
                    proyectos_harvest    => \@proyectos_harvest,
                    proyecto_harvest     => \%proyecto_harvest
                }
            );
            $harvest_id           = $args_ref->{harvest_id};
            $harvest_desc         = $args_ref->{harvest_desc};
            $unidad_harvest       = $args_ref->{unidad_harvest};
            $responsables_harvest = $args_ref->{responsables_harvest};
            $harvest_type         = $args_ref->{harvest_type};
            $cont_harvest         = $args_ref->{cont_harvest};

            while ( $cont_hsp < $num_proyecto_hsp or $cont_harvest < $num_proyecto_harvest ) {
                while ( $harvest_id lt $codigo_hsp ) {
                    $log .= "Código $harvest_id sólo existe en HARVEST\n";
                    $c->model('IntegracionHSP')->update_intproyectos($harvest_id);

                    #print "Movimientos mayor: $harvest_id < $codigo_hsp\n";
                    $num_deleted++;
                    $c->model('IntegracionHSP')->leer_harvest();
                }

                while ( $harvest_id gt $codigo_hsp ) {
                    $log .= "Código $codigo_hsp sólo existe en HSP\n";

                    $c->model('IntegracionHSP')->update_intproyectos_two(
                        {   codigo_hsp       => $codigo_hsp,
                            descripcion_hsp  => $descripcion_hsp,
                            responsables_hsp => $responsables_hsp,
                            tipo_hsp         => $tipo_hsp,
                            unidad_hsp       => $unidad_hsp
                        }
                    );

                    #print "Movimientos menor: $harvest_id > $codigo_hsp\n";
                    $num_inserted++;
                    $args_ref = $c->model('IntegracionHSP')->leer_hsp(
                        {   cont_hsp         => $cont_hsp,
                            codigo_hsp       => $codigo_hsp,
                            descripcion_hsp  => $descripcion_hsp,
                            unidad_hsp       => $unidad_hsp,
                            responsables_hsp => $responsables_hsp,
                            tipo_hsp         => $tipo_hsp,
                            num_proyecto_hsp => $num_proyecto_hsp,
                            proyectos_hsp    => \@proyectos_hsp,
                            proyecto_hsp     => \%proyecto_hsp
                        }
                    );
                    $codigo_hsp       = $args_ref->{codigo_hsp};
                    $descripcion_hsp  = $args_ref->{descripcion_hsp};
                    $unidad_hsp       = $args_ref->{unidad_hsp};
                    $responsables_hsp = $args_ref->{responsables_hsp};
                    $tipo_hsp         = $args_ref->{tipo_hsp};
                    $cont_hsp         = $args_ref->{cont_hsp};
                }

                while ( $harvest_id eq $codigo_hsp and $harvest_id ne "ZZZZZZZZZZZZZZZZZZZZZZ" ) {

                    #$log .= "Código $harvest_id existe en los dos\n";

                    my $updated_text = q{};

                    if ( $descripcion_hsp ne $harvest_desc ) {
                        $updated_text .= "PRO_DESCRIPCION='$descripcion_hsp' ";
                    }

                    if ( $unidad_hsp ne $unidad_harvest ) {
                        if ($updated_text) {
                            $updated_text .= ",";
                        }
                        $updated_text .= "PRO_UNIDAD='$unidad_hsp' ";
                    }

                    if ( $responsables_hsp ne $responsables_harvest ) {
                        if ($updated_text) {
                            $updated_text .= ",";
                        }
                        $updated_text .= "PRO_RESPONSABLES='$responsables_hsp' ";
                    }

                    if ( $tipo_hsp ne $harvest_type ) {
                        if ($updated_text) {
                            $updated_text .= ",";
                        }
                        $updated_text .= "PRO_TIPO=$tipo_hsp ";
                    }

                    if ($updated_text) {
                        $c->model('IntegracionHSP')
                            ->update_intproyectos_upd_text( $updated_text, $harvest_id );
                        $num_updated++;
                    }

                    #print "Movimientos igual: $harvest_id = $codigo_hsp\n";

                    $args_ref = $c->model('IntegracionHSP')->leer_hsp(
                        {   cont_hsp         => $cont_hsp,
                            codigo_hsp       => $codigo_hsp,
                            descripcion_hsp  => $descripcion_hsp,
                            unidad_hsp       => $unidad_hsp,
                            responsables_hsp => $responsables_hsp,
                            tipo_hsp         => $tipo_hsp,
                            num_proyecto_hsp => $num_proyecto_hsp,
                            proyectos_hsp    => \@proyectos_hsp,
                            proyecto_hsp     => \%proyecto_hsp
                        }
                    );
                    $codigo_hsp       = $args_ref->{codigo_hsp};
                    $descripcion_hsp  = $args_ref->{descripcion_hsp};
                    $unidad_hsp       = $args_ref->{unidad_hsp};
                    $responsables_hsp = $args_ref->{responsables_hsp};
                    $tipo_hsp         = $args_ref->{tipo_hsp};
                    $cont_hsp         = $args_ref->{cont_hsp};

                    $args_ref = $c->model('IntegracionHSP')->leer_harvest(
                        {   cont_harvest         => $cont_harvest,
                            harvest_id           => $harvest_id,
                            harvest_desc         => $harvest_desc,
                            unidad_harvest       => $unidad_harvest,
                            responsables_harvest => $responsables_harvest,
                            harvest_type         => $harvest_type,
                            num_proyecto_harvest => $num_proyecto_harvest,
                            proyectos_harvest    => \@proyectos_harvest,
                            proyecto_harvest     => \%proyecto_harvest
                        }
                    );
                    $harvest_id           = $args_ref->{harvest_id};
                    $harvest_desc         = $args_ref->{harvest_desc};
                    $unidad_harvest       = $args_ref->{unidad_harvest};
                    $responsables_harvest = $args_ref->{responsables_harvest};
                    $harvest_type         = $args_ref->{harvest_type};
                    $cont_harvest         = $args_ref->{cont_harvest};

                }
            }

            $log .= $c->model('IntegracionHSP')->build_log(
                {   num_inserted => $num_inserted,
                    num_updated  => $num_updated,
                    num_deleted  => $num_deleted
                }
            );
        }
        catch {
            $log .= BaselinerX::Comm::Balix->ahora()
                . " - Error durante la carga de incidencias HSP: "
                . shift(), "\n";
        };

        print $log;


        warn "OKOKOK";
        warn $log_cata->info($log);

        sleep $HSP_FRECUENCIA;
    }

    return;
}

1;
