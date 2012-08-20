package BaselinerX::Controller::IntegracionUSD;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;

    warn "********************";

    # Hashes y arrays de incidencias
    my %incident_USD          = ();
    my %harvest_incident_USD  = ();
    my @incidents_USD         = ();
    my @harvest_incidents_USD = ();

    # Variables para acoger los campos del proyecto en HSP
    my $cam_USD               = q{};
    my $code_USD              = q{};
    my $description_USD       = q{};
    my $type_USD              = q{};
    my $activate_USD          = q{};
    my $state_USD             = q{};
    my $class_USD             = q{};
    my $applicant_surname_USD = q{};
    my $applicant_name_USD    = q{};
    my $affected_surname_USD  = q{};
    my $affected_name_USD     = q{};
    my $priority_USD          = q{};
    my $impact_USD            = q{};
    my $analyst_USD           = q{};

    # Variables para acoger los campos del proyecto en Harvest
    my $harvest_cam_USD               = q{};
    my $harvest_code_USD              = q{};
    my $harvest_description_USD       = q{};
    my $harvest_type_USD              = q{};
    my $harvest_activate_USD          = q{};
    my $harvest_state_USD             = q{};
    my $harvest_class_USD             = q{};
    my $harvest_applicant_surname_USD = q{};
    my $harvest_applicant_name_USD    = q{};
    my $harvest_affected_surname_USD  = q{};
    my $harvest_affected_name_USD     = q{};
    my $harvest_priority_USD          = q{};
    my $harvest_impact_USD            = q{};
    my $harvest_analyst_USD           = q{};

    # Contadores
    my $total_incident_USD         = 0;
    my $total_harvest_activate_USD = 0;
    my $cont_USD                   = 0;
    my $harvest_cont_USD           = 0;
    my $inserted_total             = 0;
    my $updated_total              = 0;
    my $deleted_total              = 0;

    # Booleanos
    my $modificado = 0;

    # Variables generales
    my $sql     = q{};
    my $log     = q{};
    my $retorno = q{};

    my $link_USD       = 'BDE_SCM_USD@USD';    #XXX HARD-CODED XXX
    my $frecuencia_USD = 3600;                 #XXX HARD-CODED XXX

    while (1) {
        warn "inicio bucle";
        print BaselinerX::Comm::Balix->ahora() . " - Iniciando la carga de incidencias USD\n";
        try {
            # Reads incidents from Harvest...
            %harvest_incident_USD = $c->model('IntegracionUSD')->_harvest_incidents();
            warn "tengo hash 1";

            # Reads incidents from USD...
            %incident_USD = $c->model('IntegracionUSD')->_USD_incidents($link_USD);
            warn "tengo hash 2";

            #Construimos las listas para recorrer e inicializamos contadores
            $total_incident_USD         = keys %incident_USD;
            $total_harvest_activate_USD = keys %harvest_incident_USD;
            @incidents_USD              = sort( keys %incident_USD );
            @harvest_incidents_USD      = sort( keys %harvest_incident_USD );
            
            use Data::Dumper;
            print \@incidents_USD;
            print \@harvest_incidents_USD;

            my $data_read_USD = {
                incidents_USD         => \@incidents_USD,
                incident_USD          => \%incident_USD,
                cont_USD              => $cont_USD,
                code_USD              => $code_USD,
                cam_USD               => $cam_USD,
                description_USD       => $description_USD,
                type_USD              => $type_USD,
                activate_USD          => $activate_USD,
                state_USD             => $state_USD,
                class_USD             => $class_USD,
                applicant_surname_USD => $applicant_surname_USD,
                applicant_name_USD    => $applicant_name_USD,
                affected_surname_USD  => $affected_surname_USD,
                affected_name_USD     => $affected_name_USD,
                priority_USD          => $priority_USD,
                impact_USD            => $impact_USD,
                analyst_USD           => $analyst_USD,
                total_incident_USD    => $total_incident_USD
            };

            my $args_read_USD = $c->model('IntegracionUSD')->read_USD($data_read_USD);

            @incidents_USD         = @{ $args_read_USD->{incidents_USD} };
            %incident_USD          = %{ $args_read_USD->{incident_USD} };
            $cont_USD              = $args_read_USD->{cont_USD};
            $code_USD              = $args_read_USD->{code_USD};
            $cam_USD               = $args_read_USD->{cam_USD};
            $description_USD       = $args_read_USD->{description_USD};
            $type_USD              = $args_read_USD->{type_USD};
            $activate_USD          = $args_read_USD->{activate_USD};
            $state_USD             = $args_read_USD->{state_USD};
            $class_USD             = $args_read_USD->{class_USD};
            $applicant_surname_USD = $args_read_USD->{applicant_surname_USD};
            $applicant_name_USD    = $args_read_USD->{applicant_name_USD};
            $affected_surname_USD  = $args_read_USD->{affected_surname_USD};
            $affected_name_USD     = $args_read_USD->{affected_name_USD};
            $priority_USD          = $args_read_USD->{priority_USD};
            $impact_USD            = $args_read_USD->{impact_USD};
            $analyst_USD           = $args_read_USD->{analyst_USD};
            $total_incident_USD    = $args_read_USD->{total_incident_USD};

            my $data_read_harvest_USD = {
                harvest_incidents_USD         => \@harvest_incidents_USD,
                harvest_incident_USD          => \%harvest_incident_USD,
                harvest_cont_USD              => $harvest_cont_USD,
                harvest_cam_USD               => $harvest_cam_USD,
                harvest_description_USD       => $harvest_description_USD,
                harvest_type_USD              => $harvest_type_USD,
                harvest_activate_USD          => $harvest_activate_USD,
                harvest_state_USD             => $harvest_state_USD,
                harvest_class_USD             => $harvest_class_USD,
                harvest_applicant_surname_USD => $harvest_applicant_surname_USD,
                harvest_applicant_name_USD    => $harvest_applicant_name_USD,
                harvest_affected_surname_USD  => $harvest_affected_surname_USD,
                harvest_affected_name_USD     => $harvest_affected_name_USD,
                harvest_priority_USD          => $harvest_priority_USD,
                harvest_impact_USD            => $harvest_impact_USD,
                harvest_analyst_USD           => $harvest_analyst_USD,
                harvest_code_USD              => $harvest_code_USD,
                total_harvest_activate_USD    => $total_harvest_activate_USD,
            };

            my $args_read_harvest_USD = $c->model('IntegracionUSD')->read_harvest_USD($data_read_harvest_USD);

            @harvest_incidents_USD         = @{ $args_read_harvest_USD->{harvest_incidents_USD} };
            %harvest_incident_USD          = %{ $args_read_harvest_USD->{harvest_incident_USD} };
            $harvest_cont_USD              = $args_read_harvest_USD->{harvest_cont_USD};
            $harvest_cam_USD               = $args_read_harvest_USD->{harvest_cam_USD};
            $harvest_description_USD       = $args_read_harvest_USD->{harvest_description_USD};
            $harvest_type_USD              = $args_read_harvest_USD->{harvest_type_USD};
            $harvest_activate_USD          = $args_read_harvest_USD->{harvest_activate_USD};
            $harvest_state_USD             = $args_read_harvest_USD->{harvest_state_USD};
            $harvest_class_USD             = $args_read_harvest_USD->{harvest_class_USD};
            $harvest_applicant_surname_USD = $args_read_harvest_USD->{harvest_applicant_surname_USD};
            $harvest_applicant_name_USD    = $args_read_harvest_USD->{harvest_applicant_name_USD};
            $harvest_affected_surname_USD  = $args_read_harvest_USD->{harvest_affected_surname_USD};
            $harvest_affected_name_USD     = $args_read_harvest_USD->{harvest_affected_name_USD};
            $harvest_priority_USD          = $args_read_harvest_USD->{harvest_priority_USD};
            $harvest_impact_USD            = $args_read_harvest_USD->{harvest_impact_USD};
            $harvest_analyst_USD           = $args_read_harvest_USD->{harvest_analyst_USD};
            $harvest_code_USD              = $args_read_harvest_USD->{harvest_code_USD};
            $total_harvest_activate_USD    = $args_read_harvest_USD->{total_harvest_activate_USD};

            while ($cont_USD < $total_incident_USD
                or $harvest_cont_USD < $total_harvest_activate_USD )
            {
                warn "inicio bucle 2";
                while ( $harvest_code_USD lt $code_USD ) {
                    warn "inicio bucle 3";
                    $c->model('IntegracionUSD')->delete_intincidencias($harvest_cont_USD);
                    $deleted_total++;

                    # Reads Harvest USD
                    $data_read_harvest_USD = {
                        harvest_incidents_USD         => \@harvest_incidents_USD,
                        harvest_incident_USD          => \%harvest_incident_USD,
                        harvest_cont_USD              => $harvest_cont_USD,
                        harvest_cam_USD               => $harvest_cam_USD,
                        harvest_description_USD       => $harvest_description_USD,
                        harvest_type_USD              => $harvest_type_USD,
                        harvest_activate_USD          => $harvest_activate_USD,
                        harvest_state_USD             => $harvest_state_USD,
                        harvest_class_USD             => $harvest_class_USD,
                        harvest_applicant_surname_USD => $harvest_applicant_surname_USD,
                        harvest_applicant_name_USD    => $harvest_applicant_name_USD,
                        harvest_affected_surname_USD  => $harvest_affected_surname_USD,
                        harvest_affected_name_USD     => $harvest_affected_name_USD,
                        harvest_priority_USD          => $harvest_priority_USD,
                        harvest_impact_USD            => $harvest_impact_USD,
                        harvest_analyst_USD           => $harvest_analyst_USD,
                        harvest_code_USD              => $harvest_code_USD,
                        total_harvest_activate_USD    => $total_harvest_activate_USD,
                    };

                    $args_read_harvest_USD = $c->model('IntegracionUSD')->read_harvest_USD($data_read_harvest_USD);

                    @harvest_incidents_USD         = @{ $args_read_harvest_USD->{harvest_incidents_USD} };
                    %harvest_incident_USD          = %{ $args_read_harvest_USD->{harvest_incident_USD} };
                    $harvest_cont_USD              = $args_read_harvest_USD->{harvest_cont_USD};
                    $harvest_cam_USD               = $args_read_harvest_USD->{harvest_cam_USD};
                    $harvest_description_USD       = $args_read_harvest_USD->{harvest_description_USD};
                    $harvest_type_USD              = $args_read_harvest_USD->{harvest_type_USD};
                    $harvest_activate_USD          = $args_read_harvest_USD->{harvest_activate_USD};
                    $harvest_state_USD             = $args_read_harvest_USD->{harvest_state_USD};
                    $harvest_class_USD             = $args_read_harvest_USD->{harvest_class_USD};
                    $harvest_applicant_surname_USD = $args_read_harvest_USD->{harvest_applicant_surname_USD};
                    $harvest_applicant_name_USD    = $args_read_harvest_USD->{harvest_applicant_name_USD};
                    $harvest_affected_surname_USD  = $args_read_harvest_USD->{harvest_affected_surname_USD};
                    $harvest_affected_name_USD     = $args_read_harvest_USD->{harvest_affected_name_USD};
                    $harvest_priority_USD          = $args_read_harvest_USD->{harvest_priority_USD};
                    $harvest_impact_USD            = $args_read_harvest_USD->{harvest_impact_USD};
                    $harvest_analyst_USD           = $args_read_harvest_USD->{harvest_analyst_USD};
                    $harvest_code_USD              = $args_read_harvest_USD->{harvest_code_USD};
                    $total_harvest_activate_USD    = $args_read_harvest_USD->{total_harvest_activate_USD};
                }
                warn "salgo bucle 3";

                while ( $harvest_code_USD gt $code_USD ) {
                    warn "inicio bucle 4";
                    $c->model('IntegracionUSD')->insert_intincidencias(
                        {   code_USD              => $code_USD,
                            cam_USD               => $cam_USD,
                            description_USD       => $description_USD,
                            type_USD              => $type_USD,
                            activate_USD          => $activate_USD,
                            state_USD             => $state_USD,
                            class_USD             => $class_USD,
                            applicant_surname_USD => $applicant_surname_USD,
                            applicant_name_USD    => $applicant_name_USD,
                            affected_surname_USD  => $affected_surname_USD,
                            affected_name_USD     => $affected_name_USD,
                            priority_USD          => $priority_USD,
                            impact_USD            => $impact_USD,
                            analyst_USD           => $analyst_USD,
                        }
                    );

                    #print "Movimientos menor: $harvest_code_USD > $code_USD\n";
                    $inserted_total++;

                    # Reads USD
                    $data_read_USD = {
                        incidents_USD         => \@incidents_USD,
                        incident_USD          => \%incident_USD,
                        cont_USD              => $cont_USD,
                        code_USD              => $code_USD,
                        cam_USD               => $cam_USD,
                        description_USD       => $description_USD,
                        type_USD              => $type_USD,
                        activate_USD          => $activate_USD,
                        state_USD             => $state_USD,
                        class_USD             => $class_USD,
                        applicant_surname_USD => $applicant_surname_USD,
                        applicant_name_USD    => $applicant_name_USD,
                        affected_surname_USD  => $affected_surname_USD,
                        affected_name_USD     => $affected_name_USD,
                        priority_USD          => $priority_USD,
                        impact_USD            => $impact_USD,
                        analyst_USD           => $analyst_USD,
                        total_incident_USD    => $total_incident_USD
                    };

                    $args_read_USD = $c->model('IntegracionUSD')->read_USD($data_read_USD);

                    @incidents_USD         = @{ $args_read_USD->{incidents_USD} };
                    %incident_USD          = %{ $args_read_USD->{incident_USD} };
                    $cont_USD              = $args_read_USD->{cont_USD};
                    $code_USD              = $args_read_USD->{code_USD};
                    $cam_USD               = $args_read_USD->{cam_USD};
                    $description_USD       = $args_read_USD->{description_USD};
                    $type_USD              = $args_read_USD->{type_USD};
                    $activate_USD          = $args_read_USD->{activate_USD};
                    $state_USD             = $args_read_USD->{state_USD};
                    $class_USD             = $args_read_USD->{class_USD};
                    $applicant_surname_USD = $args_read_USD->{applicant_surname_USD};
                    $applicant_name_USD    = $args_read_USD->{applicant_name_USD};
                    $affected_surname_USD  = $args_read_USD->{affected_surname_USD};
                    $affected_name_USD     = $args_read_USD->{affected_name_USD};
                    $priority_USD          = $args_read_USD->{priority_USD};
                    $impact_USD            = $args_read_USD->{impact_USD};
                    $analyst_USD           = $args_read_USD->{analyst_USD};
                    $total_incident_USD    = $args_read_USD->{total_incident_USD};
                }
                warn "salgo bucle 4";

                while ( $harvest_code_USD eq $code_USD
                    and $harvest_code_USD ne "99999999999999999999999999" )
                {
                    warn "inicio bucle 5";
                    my $update_text = q{};

                    if ( $cam_USD ne $harvest_cam_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_CAM='$cam_USD' ";
                    }

                    if ( $description_USD ne $harvest_description_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_DESCRIPCION='$description_USD' ";
                    }

                    if ( $type_USD ne $harvest_type_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_TIPO='$type_USD' ";
                    }

                    if ( $activate_USD ne $harvest_activate_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_ACTIVA='$activate_USD' ";
                    }

                    if ( $state_USD ne $harvest_state_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_ESTADO='$state_USD' ";
                    }

                    if ( $class_USD ne $harvest_class_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_CLASE='$class_USD' ";
                    }

                    if ( $applicant_surname_USD ne $harvest_applicant_surname_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_APELLIDOS_SOL='$applicant_surname_USD' ";
                    }

                    if ( $applicant_name_USD ne $harvest_applicant_name_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_NOMBRE_SOL='$applicant_name_USD' ";
                    }

                    if ( $affected_surname_USD ne $harvest_affected_surname_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_APELLIDOS_AFE='$affected_surname_USD' ";
                    }

                    if ( $affected_name_USD ne $harvest_affected_name_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_NOMBRE_AFE='$affected_name_USD' ";
                    }

                    if ( $priority_USD ne $harvest_priority_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_PRIORIDAD='$priority_USD' ";
                    }

                    if ( $impact_USD ne $harvest_impact_USD ) {
                        $update_text .= ',' if $update_text;
                        $update_text .= "INC_IMPACTO='$impact_USD' ";
                    }

#                    if ( $analyst_USD ne $harvest_analyst_USD ) {
#                        $update_text .= ',' if $update_text;
#                        $update_text .= "INC_ANALISTA='$analyst_USD' ";
#                    }

                    if ($update_text) {
                        $c->model('IntegracionUSD')
                            ->update_intincidencias( $update_text, $harvest_code_USD );
                        $updated_total++;
                    }

                    # Reads USD
                    $data_read_USD = {
                        incidents_USD         => \@incidents_USD,
                        incident_USD          => \%incident_USD,
                        cont_USD              => $cont_USD,
                        code_USD              => $code_USD,
                        cam_USD               => $cam_USD,
                        description_USD       => $description_USD,
                        type_USD              => $type_USD,
                        activate_USD          => $activate_USD,
                        state_USD             => $state_USD,
                        class_USD             => $class_USD,
                        applicant_surname_USD => $applicant_surname_USD,
                        applicant_name_USD    => $applicant_name_USD,
                        affected_surname_USD  => $affected_surname_USD,
                        affected_name_USD     => $affected_name_USD,
                        priority_USD          => $priority_USD,
                        impact_USD            => $impact_USD,
                        analyst_USD           => $analyst_USD,
                        total_incident_USD    => $total_incident_USD
                    };

                    $args_read_USD = $c->model('IntegracionUSD')->read_USD($data_read_USD);

                    @incidents_USD         = @{ $args_read_USD->{incidents_USD} };
                    %incident_USD          = %{ $args_read_USD->{incident_USD} };
                    $cont_USD              = $args_read_USD->{cont_USD};
                    $code_USD              = $args_read_USD->{code_USD};
                    $cam_USD               = $args_read_USD->{cam_USD};
                    $description_USD       = $args_read_USD->{description_USD};
                    $type_USD              = $args_read_USD->{type_USD};
                    $activate_USD          = $args_read_USD->{activate_USD};
                    $state_USD             = $args_read_USD->{state_USD};
                    $class_USD             = $args_read_USD->{class_USD};
                    $applicant_surname_USD = $args_read_USD->{applicant_surname_USD};
                    $applicant_name_USD    = $args_read_USD->{applicant_name_USD};
                    $affected_surname_USD  = $args_read_USD->{affected_surname_USD};
                    $affected_name_USD     = $args_read_USD->{affected_name_USD};
                    $priority_USD          = $args_read_USD->{priority_USD};
                    $impact_USD            = $args_read_USD->{impact_USD};
                    $analyst_USD           = $args_read_USD->{analyst_USD};
                    $total_incident_USD    = $args_read_USD->{total_incident_USD};

                    # Reads Harvest USD
                    $data_read_harvest_USD = {
                        harvest_incidents_USD         => \@harvest_incidents_USD,
                        harvest_incident_USD          => \%harvest_incident_USD,
                        harvest_cont_USD              => $harvest_cont_USD,
                        harvest_cam_USD               => $harvest_cam_USD,
                        harvest_description_USD       => $harvest_description_USD,
                        harvest_type_USD              => $harvest_type_USD,
                        harvest_activate_USD          => $harvest_activate_USD,
                        harvest_state_USD             => $harvest_state_USD,
                        harvest_class_USD             => $harvest_class_USD,
                        harvest_applicant_surname_USD => $harvest_applicant_surname_USD,
                        harvest_applicant_name_USD    => $harvest_applicant_name_USD,
                        harvest_affected_surname_USD  => $harvest_affected_surname_USD,
                        harvest_affected_name_USD     => $harvest_affected_name_USD,
                        harvest_priority_USD          => $harvest_priority_USD,
                        harvest_impact_USD            => $harvest_impact_USD,
                        harvest_analyst_USD           => $harvest_analyst_USD,
                        harvest_code_USD              => $harvest_code_USD,
                        total_harvest_activate_USD    => $total_harvest_activate_USD,
                    };

                    $args_read_harvest_USD = $c->model('IntegracionUSD')->read_harvest_USD($data_read_harvest_USD);

                    @harvest_incidents_USD         = @{ $args_read_harvest_USD->{harvest_incidents_USD} };
                    %harvest_incident_USD          = %{ $args_read_harvest_USD->{harvest_incident_USD} };
                    $harvest_cont_USD              = $args_read_harvest_USD->{harvest_cont_USD};
                    $harvest_cam_USD               = $args_read_harvest_USD->{harvest_cam_USD};
                    $harvest_description_USD       = $args_read_harvest_USD->{harvest_description_USD};
                    $harvest_type_USD              = $args_read_harvest_USD->{harvest_type_USD};
                    $harvest_activate_USD          = $args_read_harvest_USD->{harvest_activate_USD};
                    $harvest_state_USD             = $args_read_harvest_USD->{harvest_state_USD};
                    $harvest_class_USD             = $args_read_harvest_USD->{harvest_class_USD};
                    $harvest_applicant_surname_USD = $args_read_harvest_USD->{harvest_applicant_surname_USD};
                    $harvest_applicant_name_USD    = $args_read_harvest_USD->{harvest_applicant_name_USD};
                    $harvest_affected_surname_USD  = $args_read_harvest_USD->{harvest_affected_surname_USD};
                    $harvest_affected_name_USD     = $args_read_harvest_USD->{harvest_affected_name_USD};
                    $harvest_priority_USD          = $args_read_harvest_USD->{harvest_priority_USD};
                    $harvest_impact_USD            = $args_read_harvest_USD->{harvest_impact_USD};
                    $harvest_analyst_USD           = $args_read_harvest_USD->{harvest_analyst_USD};
                    $harvest_code_USD              = $args_read_harvest_USD->{harvest_code_USD};
                    $total_harvest_activate_USD    = $args_read_harvest_USD->{total_harvest_activate_USD};


                    warn "************************************************************************";
                    warn "harvest_cont_USD              => $harvest_cont_USD";
                    warn "harvest_cam_USD               => $harvest_cam_USD";
                    warn "harvest_description_USD       => $harvest_description_USD";
                    warn "harvest_type_USD              => $harvest_type_USD";
                    warn "harvest_activate_USD          => $harvest_activate_USD";
                    warn "harvest_state_USD             => $harvest_state_USD";
                    warn "harvest_class_USD             => $harvest_class_USD";
                    warn "harvest_applicant_surname_USD => $harvest_applicant_surname_USD";
                    warn "harvest_applicant_name_USD    => $harvest_applicant_name_USD";
                    warn "harvest_affected_surname_USD  => $harvest_affected_surname_USD";
                    warn "harvest_affected_name_USD     => $harvest_affected_name_USD";
                    warn "harvest_priority_USD          => $harvest_priority_USD";
                    warn "harvest_impact_USD            => $harvest_impact_USD";
                    warn "harvest_analyst_USD           => $harvest_analyst_USD";
                    warn "harvest_code_USD              => $harvest_code_USD";
                    warn "total_harvest_activate_USD    => $total_harvest_activate_USD";
                    warn "************************************************************************";
                    warn BaselinerX::Comm::Balix->ahora();
                    warn "************************************************************************";
                }
                warn "salgo bucle 5";
            }
            warn "salgo bucle 2";

            $log = $c->model('IntegracionUSD')->mini_log(
                {   inserted_total => $inserted_total,
                    updated_total  => $updated_total,
                    deleted_total  => $deleted_total
                }
            );
        }
        catch {
            $log .=
                  BaselinerX::Comm::Balix->ahora()
                . " - Error durante la carga de incidencias USD: "
                . shift(), "\n";
        };

        print "$log";
        sleep $frecuencia_USD;
    }

    return;
}

1;
