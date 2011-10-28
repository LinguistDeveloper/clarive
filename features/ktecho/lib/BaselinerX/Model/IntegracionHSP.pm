package BaselinerX::Model::IntegracionHSP;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub read_harvest_proyects {
    my $self   = shift;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql    = "
        SELECT pro_codigo, 
            pro_descripcion, 
            pro_unidad, 
            pro_responsables, 
            pro_tipo 
        FROM   intproyectos 
        WHERE  pro_activo = '1'  
    ";

    return $har_db->db->hash($sql);
}

sub read_hsp_proyects {
    my ( $self, $HSP_LINK ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql    = "
        SELECT codigo, 
            descripcion, 
            unidad, 
            responsables, 
            tipo 
        FROM   $HSP_LINK  
    ";

    return $har_db->db->hash($sql);
}

sub leer_hsp {
    my ( $self, $args_ref ) = @_;

    if ( $args_ref->{proyectos_hsp} ) {

        my $cont_hsp         = $args_ref->{cont_hsp};
        my $codigo_hsp       = $args_ref->{codigo_hsp};
        my $descripcion_hsp  = $args_ref->{descripcion_hsp};
        my $unidad_hsp       = $args_ref->{unidad_hsp};
        my $responsables_hsp = $args_ref->{responsables_hsp};
        my $tipo_hsp         = $args_ref->{tipo_hsp};
        my $num_proyecto_hsp = $args_ref->{num_proyecto_hsp};
        my @proyectos_hsp    = @{ $args_ref->{proyectos_hsp} };
        my %proyecto_hsp     = %{ $args_ref->{proyecto_hsp} };

        my $codigo = $proyectos_hsp[ $cont_hsp++ ];

        if ($codigo) {
            $codigo_hsp = $codigo;
            ( $descripcion_hsp, $unidad_hsp, $responsables_hsp, $tipo_hsp ) =
                @{ $proyecto_hsp{$codigo} };
            $descripcion_hsp = $self->limpia_cadena($descripcion_hsp);
        }
        else {
            $codigo_hsp = "ZZZZZZZZZZZZZZZZZZZZZZ";
            $cont_hsp   = $num_proyecto_hsp;
        }

        return {
            codigo_hsp       => $codigo_hsp,
            descripcion_hsp  => $descripcion_hsp,
            unidad_hsp       => $unidad_hsp,
            responsables_hsp => $responsables_hsp,
            tipo_hsp         => $tipo_hsp,
            cont_hsp         => $cont_hsp
        };
    }

    return;
}

sub leer_harvest {
    my ( $self, $args_ref ) = @_;

    if ( $args_ref->{proyectos_harvest} ) {
        my $cont_harvest         = $args_ref->{cont_harvest};
        my $harvest_id           = $args_ref->{harvest_id};
        my $harvest_desc         = $args_ref->{harvest_desc};
        my $unidad_harvest       = $args_ref->{unidad_harvest};
        my $responsables_harvest = $args_ref->{responsables_harvest};
        my $harvest_type         = $args_ref->{harvest_type};
        my $num_proyecto_harvest = $args_ref->{num_proyecto_harvest};
        my @proyectos_harvest    = @{ $args_ref->{proyectos_harvest} };
        my %proyecto_harvest     = %{ $args_ref->{proyecto_harvest} };

        my $codigo = $proyectos_harvest[ $cont_harvest++ ];

        #print "Estoy en leer Harvest.  Codigo=*".$codigo."*\n";
        if ( $codigo && $codigo ne q{} ) {
            $harvest_id = $codigo;
            ( $harvest_desc, $unidad_harvest, $responsables_harvest, $harvest_type ) =
                @{ $proyecto_harvest{$codigo} };
            $harvest_desc = $self->limpia_cadena($harvest_desc);
        }
        else {
            $harvest_id   = "ZZZZZZZZZZZZZZZZZZZZZZ";
            $cont_harvest = $num_proyecto_harvest;
        }

        return {
            harvest_id           => $harvest_id,
            harvest_desc         => $harvest_desc,
            unidad_harvest       => $unidad_harvest,
            responsables_harvest => $responsables_harvest,
            harvest_type         => $harvest_type,
            cont_harvest         => $cont_harvest
        };

    }

    return;
}

sub update_intproyectos {
    my ( $self, $harvest_id ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql    = "
        UPDATE intproyectos 
        SET    pro_activo = 0 
        WHERE  pro_codigo = '$harvest_id'  
    ";

    $har_db->db->do($sql);

    warn "update_intproyectos terminado OK";

    return;
}

sub update_intproyectos_two {
    my ( $self, $args_ref ) = @_;

    my $codigo_hsp       = $args_ref->{codigo_hsp};
    my $descripcion_hsp  = $args_ref->{descripcion_hsp};
    my $responsables_hsp = $args_ref->{responsables_hsp};
    my $tipo_hsp         = $args_ref->{tipo_hsp};
    my $unidad_hsp       = $args_ref->{unidad_hsp};

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $sql = "
        INSERT INTO intproyectos 
                    (pro_codigo, 
                    pro_descripcion, 
                    pro_unidad, 
                    pro_responsables, 
                    pro_tipo) 
        VALUES      ('$codigo_hsp', 
                    '$descripcion_hsp', 
                    '$unidad_hsp', 
                    '$responsables_hsp', 
                    $tipo_hsp)  
    ";

    warn "update_intproyectos_two OK";

    $har_db->db->do($sql);

    return;
}

sub update_intproyectos_upd_text {
    my ( $self, $updated_text, $harvest_id ) = @_;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $sql = "
        UPDATE intproyectos
        SET    $updated_text
        WHERE  pro_codigo = '$harvest_id'
    ";

    warn "update_intproyectos_upd_text OK";

    return;
}

sub limpia_cadena {
    my ( $self, $cadena ) = @_;

    $cadena =~ s/\'//gx;

    return $cadena;
}

sub build_log {
    my ( $self, $args_ref ) = @_;

    my $num_inserted = $args_ref->{num_inserted};
    my $num_updated  = $args_ref->{num_updated};
    my $num_deleted  = $args_ref->{num_deleted};
    my $date = BaselinerX::Comm::Balix->ahora();

    # nota: aquí se podría usar Perl6::Form

    return <<"END_LOG";
$date - Finalizada la carga de proyectos HSP
$date - ********************************
$date - ********************************
$date - * PROYECTOS INSERTADOS:  $num_inserted
$date - * PROYECTOS MODIFICADOS: $num_updated
$date - * PROYECTOS BORRADOS:    $num_deleted
$date - ********************************
$date - ********************************
END_LOG
}

1;
