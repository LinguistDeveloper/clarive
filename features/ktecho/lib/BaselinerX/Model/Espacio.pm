package BaselinerX::Model::Espacio;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub get_data {
    my ( $self, $args_ref ) = @_;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $p_sort  = $args_ref->{sort};
    my $p_dir   = $args_ref->{dir};
    my $p_query = $args_ref->{query};
    my $p_hist  = $args_ref->{hist};

    # my $query = "
    #     SELECT ts, 
    #         To_char(ts, 'DD/MM/YYYY') ts2, 
    #         cam, 
    #         envobjid, 
    #         environmentname, 
    #         envisactive, 
    #         isarchive, 
    #         ( CASE 
    #             WHEN ( items > 0 ) THEN versions / items 
    #             ELSE 0 
    #             END )                   densidad, 
    #         versions, 
    #         repsize, 
    #         items, 
    #         versions_r, 
    #         versions_high, 
    #         versions_prod, 
    #         versions_ante, 
    #         versions_test 
    #     FROM   distespacio de 
    #     WHERE  1 = 1 
    #         AND ts = (SELECT MAX(d.ts) 
    #                     FROM   distespacio d, 
    #                             harenvironment e2 
    #                     WHERE  d.environmentname = de.environmentname 
    #                             AND de.envobjid = e2.envobjid 
    #                             AND e2.isarchive <> 'Y')  
    # ";

    # New query [30 May, 2011 15:06]
    my $query = qq{
        SELECT ts, TO_CHAR (ts, 'DD/MM/YYYY') ts2, cam, envobjid, environmentname,
               envisactive, isarchive,
               (CASE
                   WHEN (items > 0)
                      THEN VERSIONS / items
                   ELSE 0
                END) densidad, VERSIONS, repsize, items, versions_r, versions_high,
               versions_prod, versions_ante, versions_test
          FROM distespacio de
         WHERE ts =
                  (SELECT MAX (d.ts)
                     FROM distespacio d, harenvironment e2
                    WHERE d.environmentname = de.environmentname
                      AND de.envobjid = e2.envobjid
                      AND d.envobjid = e2.envobjid
                      AND e2.isarchive <> 'Y')
    };

    # Filtro por búsqueda de CAM...
    if ($p_query) {
        $query .= " AND upper(trim(de.environmentname)) LIKE upper('$p_query') ";
    }

    # Histórico o no...
    if ($p_hist) {
        $query .= qq/
            AND ts = (SELECT MAX(d.ts) 
                        FROM   distespacio d, 
                                harenvironment e2 
                        WHERE  d.environmentname = de.environmentname 
                                AND de.envobjid = e2.envobjid 
                                AND e2.isarchive <> 'Y')  
        /;
    }

    # Ordeno por valor y dirección ( asc / desc ) 
    if ($p_sort) {
        $query .= " ORDER BY $p_sort $p_dir";
    }
    else {
        $query .= " ORDER BY environmentname";
    }

    return $har_db->db->array_hash($query);
}

sub get_data_path {
    my ( $self, $args_ref ) = @_;
    my $p_project = $args_ref->{project};
    my $p_sort    = $args_ref->{sort};
    my $p_dir     = $args_ref->{dir};
    my $har_db    = BaselinerX::Ktecho::Harvest::DB->new;

    my $query = qq/
        SELECT path, espacio
        FROM   distespacio_paths
        WHERE  environmentname = '$p_project' 
    /;

    if ($p_sort) {
        $query .= "ORDER BY $p_sort $p_dir";
    }
    else {
        $query .= "ORDER BY path";
    }

    return $har_db->db->array_hash($query);
}

sub get_total_compress_size {
    my $self = shift;

    my $sql = " 
        SELECT To_char(SUM(compdatasize) / 1024 / 1024, '999G999G999') total 
        FROM   harversiondata  
    ";

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->value($sql);
}

sub get_total_size {
    my $self = shift;

    my $sql = "
        SELECT To_char(SUM(datasize) / 1024 / 1024, '999G999G999') total 
        FROM   harversiondata  
    ";

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->value($sql);
}

sub get_total_item_size {
    my $self = shift;

    my $sql = "
        SELECT To_char(COUNT(*), '999G999G999') total 
        FROM   haritems  
    ";

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->value($sql);
}

sub get_total_ver_size {
    my $self = shift;

    my $sql = "
        SELECT To_char(COUNT(*), '999G999G999') total 
        FROM   harversiondata  
    ";

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->value($sql);
}

1;
