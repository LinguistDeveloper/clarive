package BaselinerX::Model::IntegracionUSD;
use strict;
use warnings;
use 5.010;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Model' }
#:int_cau:

sub _harvest_incidents {
    my $self   = shift;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql    = qq{
        SELECT inc_codigo, 
            inc_cam, 
            inc_descripcion, 
            inc_tipo, 
            inc_activa, 
            inc_estado, 
            inc_clase, 
            inc_apellidos_sol, 
            inc_nombre_sol, 
            inc_apellidos_afe, 
            inc_nombre_afe, 
            inc_prioridad, 
            inc_impacto 
        FROM   intincidencias  
        WHERE inc_activa = 'SI'
    };

    return $har_db->db->hash($sql);
}

sub _USD_incidents {
    my ( $self, $link_USD ) = @_;
    my $descripcion = utf8::upgrade('Descripción');
    my $har_db      = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql         = qq{
        SELECT "Id Incidencia"       AS inc_codigo, 
            "CAM"                    AS inc_cam, 
            $descripcion             AS inc_descripcion, 
            "Tipo incidencia"        AS inc_tipo, 
            "Activa?"                AS inc_activa, 
            "Estado"                 AS inc_estado, 
            "Clase"                  AS inc_clase, 
            "Solicitante apellidos"  AS inc_apellidos_sol, 
            "Solicitante nombre"     AS inc_nombre_sol, 
            "Usr afectado apellidos" AS inc_apellidos_afe, 
            "Usr afectado nombre"    AS inc_nombre_afe, 
            "Prioridad"              AS inc_prioridad, 
            "Impacto"                AS inc_impacto, 
            "Analista Asignado"      AS inc_analista 
        FROM   $link_USD
        WHERE "Activa?" = 'SI'
    };

    return $har_db->db->hash($sql);
}

sub clean_string {
    my ( $self, $string ) = @_;

    $string =~ s/\'//g;

    return $string;
}

sub read_USD {
    my ( $self, $args_ref ) = @_;

    my @incidents_USD         = @{ $args_ref->{incidents_USD} };
    my %incident_USD          = %{ $args_ref->{incident_USD} };
    my $cont_USD              = $args_ref->{cont_USD};
    my $code_USD              = $args_ref->{code_USD};
    my $cam_USD               = $args_ref->{cam_USD};
    my $description_USD       = $args_ref->{description_USD};
    my $type_USD              = $args_ref->{type_USD};
    my $activate_USD          = $args_ref->{activate_USD};
    my $state_USD             = $args_ref->{state_USD};
    my $class_USD             = $args_ref->{class_USD};
    my $applicant_surname_USD = $args_ref->{applicant_surname_USD};
    my $applicant_name_USD    = $args_ref->{applicant_name_USD};
    my $affected_surname_USD  = $args_ref->{affected_surname_USD};
    my $affected_name_USD     = $args_ref->{affected_name_USD};
    my $priority_USD          = $args_ref->{priority_USD};
    my $impact_USD            = $args_ref->{impact_USD};
    my $analyst_USD           = $args_ref->{analyst_US};
    my $total_incident_USD    = $args_ref->{total_incident_USD};

    my $code = $incidents_USD[ $cont_USD++ ];

    if ($code) {
        $code_USD = $code;
        (   $cam_USD,               $description_USD,    $type_USD,
            $activate_USD,          $state_USD,          $class_USD,
            $applicant_surname_USD, $applicant_name_USD, $affected_surname_USD,
            $affected_name_USD,     $priority_USD,       $impact_USD,
            $analyst_USD
        ) = @{ $incident_USD{$code} };
        $description_USD       = $self->clean_string($description_USD);
        $applicant_surname_USD = $self->clean_string($applicant_surname_USD);
        $applicant_name_USD    = $self->clean_string($applicant_name_USD);
        $affected_surname_USD  = $self->clean_string($affected_surname_USD);
        $affected_name_USD     = $self->clean_string($affected_name_USD);
        $analyst_USD           = $self->clean_string($analyst_USD);
    }
    else {
        $code_USD = "99999999999999999999999999";
        $cont_USD = $total_incident_USD;
    }

    return {
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
}

sub read_harvest_USD {
    my ( $self, $args_ref ) = @_;

    my @harvest_incidents_USD         = @{ $args_ref->{harvest_incidents_USD} };
    my %harvest_incident_USD          = %{ $args_ref->{harvest_incident_USD} };
    my $harvest_cont_USD              = $args_ref->{harvest_cont_USD};
    my $harvest_cam_USD               = $args_ref->{harvest_cam_USD};
    my $harvest_description_USD       = $args_ref->{harvest_description_USD};
    my $harvest_type_USD              = $args_ref->{harvest_type_USD};
    my $harvest_activate_USD          = $args_ref->{harvest_activate_USD};
    my $harvest_state_USD             = $args_ref->{harvest_state_USD};
    my $harvest_class_USD             = $args_ref->{harvest_class_USD};
    my $harvest_applicant_surname_USD = $args_ref->{harvest_applicant_surname_USD};
    my $harvest_applicant_name_USD    = $args_ref->{harvest_applicant_name_USD};
    my $harvest_affected_surname_USD  = $args_ref->{harvest_affected_surname_USD};
    my $harvest_affected_name_USD     = $args_ref->{harvest_affected_name_USD};
    my $harvest_priority_USD          = $args_ref->{harvest_priority_USD};
    my $harvest_impact_USD            = $args_ref->{harvest_impact_USD};
    my $harvest_analyst_USD           = $args_ref->{harvest_analyst_USD};
    my $harvest_code_USD              = $args_ref->{harvest_code_USD};
    my $total_harvest_activate_USD    = $args_ref->{total_harvest_activate_USD};

    my $code = $harvest_incidents_USD[ $harvest_cont_USD++ ];

    if ($code) {
        $harvest_code_USD = $code;
        (   $harvest_cam_USD,               $harvest_description_USD,
            $harvest_type_USD,              $harvest_activate_USD,
            $harvest_state_USD,             $harvest_class_USD,
            $harvest_applicant_surname_USD, $harvest_applicant_name_USD,
            $harvest_affected_surname_USD,  $harvest_affected_name_USD,
            $harvest_priority_USD,          $harvest_impact_USD,
            $harvest_analyst_USD
        ) = @{ $harvest_incident_USD{$code} };
        $harvest_description_USD       = $self->clean_string($harvest_description_USD);
        $harvest_applicant_surname_USD = $self->clean_string($harvest_applicant_surname_USD);
        $harvest_applicant_name_USD    = $self->clean_string($harvest_applicant_name_USD);
        $harvest_affected_surname_USD  = $self->clean_string($harvest_affected_surname_USD);
        $harvest_affected_name_USD     = $self->clean_string($harvest_affected_name_USD);
        $harvest_analyst_USD           = $self->clean_string($harvest_analyst_USD);
    }
    else {
        $harvest_code_USD = "99999999999999999999999999";
        $harvest_cont_USD = $total_harvest_activate_USD;
    }

    return {
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
        harvest_code_USD              => $harvest_code_USD
    };
}

sub delete_intincidencias {
    my ( $self, $harvest_code_USD ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql = qq{
        DELETE FROM intincidencias 
        WHERE  inc_codigo = '$harvest_code_USD'  
    };

    $har_db->db->do($sql);
    warn "/////////////////////";
    warn "Estoy borrando la entrada con el codigo $harvest_code_USD";
    warn "/////////////////////";
    return;
}

sub insert_intincidencias {
    my ( $self, $args_ref ) = @_;

    my $row = Baseliner->model('Harvest::Intincidencias')->create(
        {   inc_codigo        => $args_ref->{code_USD},
            inc_cam           => $args_ref->{cam_USD},
            inc_descripcion   => $args_ref->{description_USD},
            inc_tipo          => $args_ref->{type_USD},
            inc_activa        => $args_ref->{activate_USD},
            inc_estado        => $args_ref->{state_USD},
            inc_clase         => $args_ref->{class_USD},
            inc_apellidos_sol => $args_ref->{applicant_surname_USD},
            inc_nombre_sol    => $args_ref->{applicant_name_USD},
            inc_apellidos_afe => $args_ref->{affected_surname_USD},
            inc_nombre_afe    => $args_ref->{affected_name_USD},
            inc_prioridad     => $args_ref->{priority_USD},
            inc_impacto       => $args_ref->{impact_USD},
            inc_analista      => $args_ref->{analyst_USD}
        }
    );

    return;
}

sub update_intincidencias {
    my ( $self, $update_text, $harvest_code_USD ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql    = qq{
        UPDATE intincidencias 
        SET    $update_text
        WHERE  inc_codigo = '$harvest_code_USD'  
    };

    $har_db->db->do($sql);

    return;
}

sub mini_log {
    my ( $self, $args_ref ) = @_;
    my $date = BaselinerX::Comm::Balix->ahora();

    return <<"END_LOG";
$date - Finalizada la carga de incidencias USD
$date - **************************************
$date - **************************************
$date - * INCIDENCIAS INSERTADAS  : $args_ref->{inserted_total}
$date - * INCIDENCIAS MODIFICADAS : $args_ref->{updated_total}
$date - * INCIDENCIAS BORRADAS    : $args_ref->{deleted_total}
$date - **************************************
$date - **************************************
END_LOG
}

1;
