package BaselinerX::Model::Form::NetProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
use Switch;
BEGIN { extends 'Catalyst::Model' }

sub net_delete_bde_paquete {
    my ($self, $args_ref ) = @_;

    my $fullname     = $args_ref->{fullname};
    my $cam          = $args_ref->{cam};
    my $project_type = $args_ref->{project_type};
    my $har_db       = BaselinerX::Ktecho::Harvest::DB->new;

    $har_db->db->do(
        qq/
            DELETE FROM bde_paquete_proyectos_net 
            WHERE  prj_fullname = '$fullname' 
                AND prj_env  = '$cam' 
                AND prj_tipo = '$project_type'  
        /
    );

    return;
}

sub net_insert_bde_paquete {
    my ( $self, $args_ref ) = @_;

    my $cam           = $args_ref->{cam};
    my $fullname      = $args_ref->{fullname};
    my $project_type  = $args_ref->{project_type};
    my $subaplicacion = $args_ref->{subaplicacion};
    my $item          = $args_ref->{item};
    my $har_db        = BaselinerX::Ktecho::Harvest::DB->new;

    $har_db->db->do(
        qq/
            INSERT INTO bde_paquete_proyectos_net 
                        (prj_env, 
                        prj_fullname, 
                        prj_tipo, 
                        prj_subaplicacion, 
                        prj_proyecto) 
            VALUES     ('$cam', 
                        '$fullname', 
                        '$project_type', 
                        '$subaplicacion', 
                        '$item')  
        /
    );

    return;
}

sub net_get_cams {
    my ( $self, $fid ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $sql = qq/
        SELECT DISTINCT e.environmentname                                                                                            AS env, 
                        pa.pathfullname 
                        || '\\' 
                        || i.itemname                                                                                                AS fullname, 
                        i.itemname                                                                                                   AS item, 
                        Substr(pa.pathfullname 
                            || '\\', Instr(pa.pathfullname 
                                            || '\\', '\\', 1, 3) + 1, Instr(pa.pathfullname 
                                                                            || '\\', '\\', 1, 4) - Instr(pa.pathfullname 
                                                                                                        || '\\', '\\', 1, 3) - 1) AS subaplicacion 
        FROM   harform f, 
            haritems i, 
            harpathfullname pa, 
            harpackage p, 
            harpackage pe, 
            harenvironment e, 
            harversions v, 
            harassocpkg a 
        WHERE  f.formobjid = a.formobjid 
            AND i.parentobjid = pa.itemobjid 
            AND v.itemobjid = i.itemobjid 
            AND v.packageobjid = pe.packageobjid 
            AND a.assocpkgid = p.packageobjid 
            AND p.envobjid = e.envobjid 
            AND pe.envobjid = e.envobjid 
            AND i.itemtype = 1 
            AND Upper(i.itemname) LIKE '%.__PROJ' 
       AND Upper(pa.pathfullname) LIKE '%\\.NET\\%'  
    /;
    #AND Trim(f.formname) = '$fid' 

    return $har_db->db->array_hash($sql);
}

sub net_get_cam_reserva {
    my ( $self, $fid ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $sql = qq/
        SELECT e.environmentname AS ENV 
        FROM HARFORM f, 
                HARPACKAGE p, 
                HARENVIRONMENT e, 
                HARASSOCPKG a 
        WHERE f.formobjid=a.formobjid  
        AND   a.assocpkgid=p.packageobjid 
        AND   p.envobjid = e.envobjid 
        AND   TRIM(f.formname)= '$fid'
    /;

    return $har_db->db->value($sql);
}

sub net_get_project_env {
    my ( $self, $cam ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $sql = qq/
        SELECT DISTINCT prj_env                             AS env, 
                        prj_proyecto                        AS proyecto, 
                        prj_subaplicacion                   AS subaplicacion, 
                        prj_tipo                            AS tipo, 
                        Replace(prj_fullname, '\\', '\\\\') AS fullname 
        FROM   bde_paquete_proyectos_net 
        ORDER BY 1, 2, 3, 4
    /;

    return $har_db->db->array_hash($sql);
}

sub get_tipos_distribucion {
    return [
        { value => 'SL', show => 'Biblioteca Servidor'                },
        { value => 'SW', show => 'Servidor IIS'                       },
        { value => 'CO', show => 'Cliente click-once IIS'             },
        { value => 'CA', show => 'Cliente click-once IBM HTTP Server' },
        { value => 'CR', show => 'Cliente R:'                         },
        { value => 'RS', show => 'Cliente R: Sucursales'              }
    ];
}

sub delete_bde_paquete_proyectos_net {
    my ( $self, $args ) = @_;

    my $rs = Baseliner->model('Form::NetProjects')->search($args);

    rs_hashref($rs);
    my @data = $rs->all;

    use Data::Dumper;

    open my $file, '>', 'C:\netproyects.txt';
    print $file Dumper \@data;

    return;
}

1;
