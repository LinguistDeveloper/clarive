package BaselinerX::Model::Form::RsProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
use Switch;
BEGIN { extends 'Catalyst::Model' }

sub rs_delete_bde_paquete {
    my ( $self, $args_ref ) = @_;
    my $cam      = $args_ref->{cam};
    my $item     = $args_ref->{item};
    my $fullname = $args_ref->{fullname};
    my $har_db   = BaselinerX::Ktecho::Harvest::DB->new;

    $har_db->db->do(
        qq/
            DELETE FROM bde_paquete_rs 
            WHERE  rs_env = '$cam' 
                AND rs_elemento = '$item' 
                AND rs_fullname = '$fullname'  
        /
    );

    return;
}

sub rs_insert_bde_paquete {
    my ( $self, $args_ref ) = @_;
    my $cam      = $args_ref->{cam};
    my $item     = $args_ref->{item};
    my $fullname = $args_ref->{fullname};
    my $har_db   = BaselinerX::Ktecho::Harvest::DB->new;

    $har_db->db->do( "
        INSERT INTO bde_paquete_rs 
                    (rs_env, 
                    rs_elemento, 
                    rs_fullname) 
        VALUES     ('$cam', 
                    '$item', 
                    '$fullname')  
        " );

    return;
}

sub rs_get_entornos {
    my ( $self, $fid ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->array_hash( "
        SELECT e.environmentname AS env 
        FROM   harform f, 
            harpackage p, 
            harenvironment e, 
            harassocpkg a 
        WHERE  f.formobjid = a.formobjid 
            AND a.assocpkgid = p.packageobjid 
            AND p.envobjid = e.envobjid 
        " );
    #AND Trim(f.formname) = '$fid'  
}

sub rs_get_elementos {
    my ( $self, $cam ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->do( "
        SELECT DISTINCT '$cam'      cam, 
                        pathfullname 
                        || '\\' 
                        || itemname item 
        FROM   harversions v, 
            haritemname n, 
            harpathfullname pa, 
            harversions vp 
        WHERE  v.itemtype = 1 
            AND n.nameobjid = v.itemnameid 
            AND v.pathversionid = vp.versionobjid 
            AND vp.itemobjid = pa.itemobjid 
            AND pa.pathfullnameupper LIKE '\\' 
                                            || '$cam' 
                                            || '\\RS%' 
        GROUP  BY pathfullname 
        || '\\' 
        || itemname 
        ORDER  BY 2  
   " );
}

sub rs_get_envs {
    my ( $self, $cam ) = @_;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->array_hash( "
        SELECT DISTINCT rs_env                             AS env, 
                        Replace(rs_elemento, '\\', '\\\\') AS item, 
                        Replace(rs_fullname, '\\', '\\\\') AS fullname 
        FROM   bde_paquete_rs 
        WHERE  rs_env = '$cam' 
        ORDER  BY 2  
        " );
}

1;
