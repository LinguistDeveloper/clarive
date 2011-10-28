package BaselinerX::Model::Form::OraProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
use Switch;
BEGIN { extends 'Catalyst::Model' }

sub get_envs {
    my ( $self, $args_ref ) = @_;

    my $fid      = $args_ref->{fid};
    my $inf_data = $args_ref->{inf_data};
    my $inf_form = $args_ref->{inf_form};
    my $har_db   = BaselinerX::Ktecho::Harvest::DB->new;

    return $har_db->db->array( "
            SELECT DISTINCT Trim(environmentname) environmentname, 
                            cam                   cam 
            FROM   harstate s, 
                harpackage p, 
                harassocpkg a, 
                harenvironment e, 
                $inf_data d, 
                bde_paquete f, 
                harform ff 
            WHERE  ff.formname   = '$fid' 
                AND f.formobjid  = ff.formobjid 
                AND f.formobjid  = a.formobjid 
                AND a.assocpkgid = p.packageobjid 
                AND p.stateobjid = s.stateobjid 
                AND e.envobjid = p.envobjid 
                AND d.idform = (SELECT MAX(idf.idform) 
                                FROM   $inf_form idf 
                                WHERE  idf.cam = Substr(environmentname, 0, 3))  
        " );
}

sub insert_bde_paquete {
    my ( $self, $args_ref ) = @_;
    my $accion      = $args_ref->{accion};
    my $env         = $args_ref->{env};
    my $fullname    = $args_ref->{fullname}    || q//;
    my $param_name  = $args_ref->{param_name}  || q//;
    my $param_value = $args_ref->{param_value} || q//;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql;

    if ( $accion eq 'AC' ) {
        $sql = qq/
            INSERT INTO bde_paquete_oracle 
                        (ora_prj, 
                        ora_fullname, 
                        ora_redes) 
            VALUES     ('$env', 
                        '$fullname', 
                        '')  
        /;
    }
    elsif ( $accion eq 'AO' ) {
        $sql = qq/
            INSERT INTO bde_paquete_oracle_owner 
                        (ora_prj, 
                        ora_campo_name, 
                        ora_campo_value) 
            VALUES     ('$env', 
                        '$param_name', 
                        '$param_value')  
        /;
    }

    $har_db->db->do($sql);

    return;
}

sub update_bde_paquete {
    my ( $self, $args_ref ) = @_;

    my $red      = $args_ref->{red};
    my $env      = $args_ref->{env};
    my $fullname = $args_ref->{fullname};
    my $opcion   = $args_ref->{opcion};
    my $har_db   = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql;

    if ( $opcion eq '+' ) {
        $sql = qq/
            UPDATE bde_paquete_oracle 
            SET    ora_redes = CASE 
                                WHEN Nvl(Length(ora_redes), 0) > 0 THEN ora_redes 
                                                                        || '|' 
                                                                        || '$red' 
                                ELSE ora_redes 
                                    || '$red' 
                            END 
            WHERE  ora_prj = '$env' 
                AND ora_fullname = '$fullname'  
        /;
    }
    else {
        $sql = qq/
            UPDATE bde_paquete_oracle 
            SET    ora_redes = CASE 
                                WHEN Instr(ora_redes, '$red|') > 0 THEN Replace(ora_redes, '$red|', '') 
                                WHEN Instr(ora_redes, '|$red') > 0 THEN Replace(ora_redes, '|$red', '') 
                                ELSE Replace(ora_redes, '$red', '') 
                            END 
            WHERE  ora_prj = '$env' 
                AND ora_fullname = '$fullname'  
        /;
    }

    $har_db->db->do($sql);

    return;
}

sub delete_bde_paquete {
    my ( $self, $args_ref ) = @_;
    my $accion     = $args_ref->{accion};
    my $fullname   = $args_ref->{fullname} || q//;
    my $env        = $args_ref->{env};
    my $param_name = $args_ref->{param_name} || q//;
    my $har_db     = BaselinerX::Ktecho::Harvest::DB->new;
    my $sql;

    if ( $accion eq 'D' ) {
        $sql = qq/
            DELETE FROM bde_paquete_oracle 
            WHERE  ora_fullname = '$fullname' 
                AND ora_prj = '$env'  
        /;
    }
    elsif ($accion eq 'AO' ) {
        $sql = qq/
            DELETE FROM bde_paquete_oracle_owner 
            WHERE  ora_prj = '$env' 
                AND ora_campo_name = '$param_name'  
        /;
    }

    $har_db->db->do($sql);

    return;
}

sub get_hash {
    my ( $self, $cam ) = @_;

    my $sql = "
        SELECT Substr(idmv.mv_valor, 0, 1) env, 
            id2.idred                   red, 
            idmv2.mv_valor              valor,
            id4.valor                   instancia
        FROM   inf_data id, 
            inf_data id2, 
            inf_data id3,
            inf_data id4, 
            inf_data_mv idmv, 
            inf_data_mv idmv2 
        WHERE  id.column_name = 'MAIN_ENTORNOS' 
            AND id.cam = '$cam' 
            AND id.idform = (SELECT MAX(IF.idform) 
                                FROM   inf_form IF 
                                WHERE  IF.cam = id.cam) 
            AND id2.idform = id.idform 
            AND id2.column_name = 'TEC_ORACLE' 
            AND id2.valor = 'Si' 
            AND id.valor = '@#' 
                            || idmv.id 
            AND id3.idred = id2.idred 
            AND id3.ident = Substr(idmv.mv_valor, 0, 1) 
            AND id3.cam = id.cam 
            AND id3.idform = id.idform 
            AND id3.column_name = 'ORA_OWNER' 
            AND id3.valor = '@#' 
                            || idmv2.id
            AND id4.cam = id.cam
            AND id4.valor is not null
            AND id4.column_name = 'ORA_INST'
            AND id4.idform = id.idform
            and id4.idred = id2.idred
        ORDER  BY 1, 
                    2,
                    3
    ";

    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );

    # Lo consigo en formato array of hashes...
    my @AoH = $inf_db->db->array_hash($sql);

    undef my %hash;

    my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
        {   cam     => 'SCT',
            sub_apl => 'soy una sub_apl',
            entorno => 'T'
        }
    );

    my $valor;

    # Lo paso a hash y de paso resuelvo el valor de la instancia
    for my $ref (@AoH) {
        if ( $ref->{instancia} =~ m/([\$\[|\$\{].*?[\]|\}])/x ) {
            $valor = $1;

            while ( $valor =~ m/([\$\[|\$\{].*?[\]|\}])/x ) {
                my $value = $resolver->get_solved_value($valor);
                $valor =~ s/([\$\[|\$\{].*?[\]|\}])/$value/;
            }

            $ref->{instancia} = $valor;
        }

        $hash{ $ref->{env} }{ $ref->{red} }{ $ref->{valor} } = $ref->{instancia};
    }

    # Para recorrer el hash se usaría algo así...
    # ENTORNO:
    #     foreach my $entorno ( keys %hash ) {
    #     RED:
    #         foreach my $red ( keys %{ $hash{$entorno} } ) {
    #         OWNER:
    #             foreach my $owner ( keys %{ $hash{$entorno}{$red} } ) {
    #             INSTANCIA:
    #                 print "$entorno :: $red :: $owner :: $hash{$entorno}{$red}{$owner}\n";
    #             }
    #         }
    #     }

    return \%hash;
}

sub get_data_hash {
    my ( $self, $cam ) = @_;

    my $sql = "
        SELECT Substr(idmv.mv_valor, 0, 1) env, 
            id2.idred                   red, 
            idmv2.mv_valor              valor 
        FROM   inf_data id, 
            inf_data id2, 
            inf_data id3, 
            inf_data_mv idmv, 
            inf_data_mv idmv2 
        WHERE  id.column_name = 'MAIN_ENTORNOS' 
            AND id.cam = '$cam' 
            AND id.idform = (SELECT MAX(IF.idform) 
                                FROM   inf_form IF 
                                WHERE  IF.cam = id.cam) 
            AND id2.idform = id.idform 
            AND id2.column_name = 'TEC_ORACLE' 
            AND id2.valor = 'Si' 
            AND id.valor = '@#' 
                            || idmv.id 
            AND id3.idred = id2.idred 
            AND id3.ident = Substr(idmv.mv_valor, 0, 1) 
            AND id3.cam = id.cam 
            AND id3.idform = id.idform 
            AND id3.column_name = 'ORA_OWNER' 
            AND id3.valor = '@#' 
                            || idmv2.id 
        ORDER  BY 1, 
                  2  
    ";

    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );

    # Lo consigo en formato array of hashes...
    my @AoH = $inf_db->db->array_hash($sql);

    undef my %data_hash;

    # Lo convierto a un hash of hashes of arrays (lol) ...
    for my $ref (@AoH) {
        push @{ $data_hash{ $ref->{env} }{ $ref->{red} } }, $ref->{valor};
    }

    # Y ordeno los arrays en orden alfabético
    foreach my $value ( keys %data_hash ) {
        foreach my $value2 ( keys %{ $data_hash{$value} } ) {
            @{ $data_hash{$value}{$value2} } = sort @{ $data_hash{$value}{$value2} };
        }
    }

    # Resultado: $ENTORNO => $RED => @OWNERS
    # $VAR1 = {
    #     'A' => {
    #         'W' => [ 'wasct1' ],
    #         'I' => [ 'wasct1' ]
    #     },
    #     'T' => {
    #         'W' => [ 'wtsct1' ],
    #         'I' => [ 'wtsct1' ]
    #     },
    #     'P' => {
    #         'W' => [ 'wpsct1', 'wtsct1' ],
    #         'I' => [ 'wpsct1', 'wtsct1' ]
    #     }
    # };

    return \%data_hash;
}

sub _has_env {
    my ( $self, $hash_ref ) = @_;
    my %hash = %{$hash_ref};

    # Si tiene keys a primer nivel, devuelvo 1
    return keys %hash ? 1 : 0;
}

sub _has_red {
    my ( $self, $hash_ref ) = @_;
    my %hash = %{$hash_ref};

    # Por cada entorno visualizo las redes
    foreach ( keys %hash ) {

        # En el momento en el que encuentre alguna red en el entorno...
        if ( keys %{ $hash{$_} } ) {

            # ... tengo redes y me piro
            return 1;
        }
    }

    # De lo contrario... no hay redes
    return 0;
}

sub get_entornos_redes {
    my ($self, $cam) = @_;
    my $query = qq/
        SELECT mv.mv_valor entorno, 
            id2.idred   red 
        FROM   inf_data id, 
            inf_data id2, 
            inf_data_mv mv 
        WHERE  id.column_name = 'MAIN_ENTORNOS' 
            AND id.cam = '$cam'
            AND id.valor = '@#' 
                            || mv.id 
            AND id.idform = (SELECT MAX(IF.idform) 
                                FROM   inf_form IF 
                                WHERE  IF.cam = id.cam) 
            AND id2.column_name = 'TEC_ORACLE' 
            AND id2.cam = id.cam 
            AND id2.idform = id.idform 
        ORDER  BY 1  
    /;

    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );
    return $inf_db->db->array_hash($query);
}

sub get_has_entornos_redes {
    my ( $self, $array_ref ) = @_;
    my @data = @{$array_ref};
    my $has_entornos;
    my $has_redes;

    for my $ref (@data) {
        if ( $ref->{entorno} ) {
            $has_entornos = 1;
        }
        if ( $ref->{red} ) {
            $has_redes = 1;
        }
    }

    return ( { has_entornos => $has_entornos, has_redes => $has_redes } );
}

sub get_entornos {
    my ( $self, $cam ) = @_;

    my $sql = qq/
        SELECT distinct mv.mv_valor entorno
        FROM   inf_data id, 
            inf_data id2, 
            inf_data_mv mv 
        WHERE  id.column_name = 'MAIN_ENTORNOS' 
            AND id.cam = '$cam'
            AND id.valor = '@#' 
                            || mv.id 
            AND id.idform = (SELECT MAX(IF.idform) 
                                FROM   inf_form IF 
                                WHERE  IF.cam = id.cam) 
            AND id2.column_name = 'TEC_ORACLE' 
            AND id2.cam = id.cam 
            AND id2.idform = id.idform
    /;

    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );
    return $inf_db->db->array_hash($sql);
}

sub get_redes {
    my ( $self, $cam ) = @_;

    my $sql = qq/
        SELECT distinct id2.idred value
        FROM   inf_data id, 
            inf_data id2, 
            inf_data_mv mv 
        WHERE  id.column_name = 'MAIN_ENTORNOS' 
            AND id.cam = '$cam'
            AND id.valor = '@#' 
                            || mv.id 
            AND id.idform = (SELECT MAX(IF.idform) 
                                FROM   inf_form IF 
                                WHERE  IF.cam = id.cam) 
            AND id2.column_name = 'TEC_ORACLE' 
            AND id2.cam = id.cam 
            AND id2.idform = id.idform 
    /;

    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );
    my @data = $inf_db->db->array_hash($sql);

    for my $ref (@data) {
        $ref->{show} = ( $ref->{value} eq 'I' ) ? 'Interna'
                     : ( $ref->{value} eq 'W' ) ? 'Internet'
                     :                            'General'
                     ;
    }

    return \@data;
}

sub get_owners {
    my ( $self, $p ) = @_;

    my $cam       = $p->{cam};
    my $i_red     = $p->{i_red};
    my $i_entorno = $p->{i_entorno};

    my $sql = qq/
    SELECT mv.mv_valor owner
    FROM   inf_data id, 
        inf_data_mv mv 
    WHERE  id.column_name = 'ORA_OWNER' 
        AND id.cam = '$cam' 
        AND id.idform = (SELECT MAX(IF.idform) 
                            FROM   inf_form IF 
                            WHERE  IF.cam = id.cam) 
        AND id.idred = substr('$i_red', 0, 1)
        AND id.ident = substr('$i_entorno', 0, 1)
        AND id.valor = '@#' 
                        || mv.id 
        AND mv.idform = id.idform
    /;

    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );
    my @data = $inf_db->db->array_hash($sql);
    return \@data;
}

sub get_instancias {
    my ( $self, $env, $cam ) = @_;
    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );

    my $sql = qq/
        SELECT DISTINCT sid instancia
        FROM   inf_instance 
        WHERE  env LIKE '%$env%'  
    /;

    my @data = $inf_db->db->array_hash($sql);
    return \@data;
}

sub get_configurar_estancias_table {
    my ( $self, $cam ) = @_;
    my $sql = qq/
        SELECT entorno, 
            red,
            propietario owner, 
            instancia oracle
        FROM   inf_cam_orainst 
        WHERE  cam = '$cam'
        ORDER BY 1,
                2,
                3
    /;

    my $inf_db   = BaselinerX::Model::InfUtil->new( { cam => $cam } );
    my @data     = $inf_db->db->array_hash($sql);
    my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
        {   cam     => $cam,
            sub_apl => 'yadda',
            entorno => 'yadda'
        }
    );

    for my $ref (@data) {
        $ref->{red} = ( $ref->{red} eq 'LN' ) ? 'Interna'
                    : ( $ref->{red} eq 'I' )  ? 'Interna'
                    : ( $ref->{red} eq 'W3' ) ? 'Internet'
                    : ( $ref->{red} eq 'W' )  ? 'Internet'
                    :                           'General'
                    ;

        $ref->{red_real} = ( $ref->{red} eq 'Interna' )  ? 'I'
                         : ( $ref->{red} eq 'Internet' ) ? 'W'
                         :                                 'G'
                         ;

        $ref->{oracle_real} = $ref->{oracle};
        $ref->{oracle}      = $resolver->get_solved_value( $ref->{oracle_real} );
    }

    return \@data;
}

sub get_folders {
    my ( $self, $cam ) = @_;
    my $sql = qq/
        SELECT pathfullname folder
        FROM   harpathfullname 
        WHERE  pathfullnameupper LIKE '\\$cam\\ORACLE%'      
    /;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    return $har_db->db->array_hash($sql);
}

sub get_entornos_filtered {
    my ( $self, $cam, $entorno ) = @_;

    # Creo la query...
    my $sql = qq/
        SELECT instancia,
            propietario
        FROM   inf_cam_orainst
        WHERE  cam = '$cam'
            AND entorno = '$entorno'
    /;

    # Inicio la instancia a de InfUtil para el CAM dado...
    my $inf_db = BaselinerX::Model::InfUtil->new( { cam => $cam } );

    # Cargo la tabla sin resolver en un array...
    my @data = $inf_db->db->array_hash($sql);

    # Instancio el resolvedor de variables para...
    my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
        {   entorno => $entorno,
            cam     => $cam,
            sub_apl => 'somevalue'
        }
    );

    FORMAT:
    for my $ref (@data) {
        # Guardo la instancia sin resolver para poder hacer inserts...
        $ref->{instancia_real} = "$ref->{propietario} en $ref->{instancia}";

        # Resuelvo...
        $ref->{instancia} = $resolver->get_solved_value( $ref->{instancia} );
        $ref->{value}     = "$ref->{propietario} en $ref->{instancia}";

        # Borro porque no las voy a usar ya...
        delete $ref->{propietario};
        delete $ref->{instancia};
    }

    return \@data;
}

sub get_tabla_config_despliegue {
    my ( $self, $cam ) = @_;
    my $sql = qq{
        SELECT CASE 
                WHEN ora_entorno = 'TEST' THEN 1 
                WHEN ora_entorno = 'ANTE' THEN 2 
                ELSE 3 
            END                      orden, 
            ora_entorno entorno, 
            ora_redes red, 
            Nvl(ora_desplegar, 'No') desplegar, 
            ora_fullname carpeta, 
            ora_instancia instancia
        FROM   bde_paquete_oracle 
        WHERE  ora_prj = '$cam' 
        ORDER  BY 1, 
                2, 
                3  
    };

    my $har_db          = BaselinerX::Ktecho::Harvest::DB->new;
    my @array_of_hashes = $har_db->db->array_hash($sql);

    for my $ref (@array_of_hashes) {
        $ref->{red} = ( $ref->{red} eq 'LN' ) ? 'Interna'
                    : ( $ref->{red} eq 'I'  ) ? 'Interna'
                    : ( $ref->{red} eq 'W3' ) ? 'Internet'
                    : ( $ref->{red} eq 'W'  ) ? 'Internet'
                    :                           'General'
                    ;

        $ref->{red_real} = ( $ref->{red} eq 'Interna' )  ? 'I'
                         : ( $ref->{red} eq 'Internet' ) ? 'W'
                         :                                 'G'
                         ;

        my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
            {   entorno => 'yadda',
                cam     => $cam,
                sub_apl => 'yadda'
            }
        );

        $ref->{instancia_real} = $ref->{instancia};
        $ref->{instancia}      = $resolver->get_solved_value( $ref->{instancia_real} );
        if ( $ref->{instancia} =~ m/_(.+)_(.+)/xi ) {
            $ref->{instancia} = "$1 en $2";
        }
    }

    return @array_of_hashes;
}

sub get_entorno {
    return [ { entorno => 'TEST' }, { entorno => 'ANTE' }, { entorno => 'PROD' } ];
}

sub add_despliegue {
    my ( $self, $cam, $p ) = @_;

    $p->{ora_prj} = $cam;
    if ( $p->{del_instancia} =~ m/(.+)\sen\s(.+)/xi ) {
        $p->{ora_instancia} = "LN_$1_$2";
    }
    delete $p->{del_instancia};
    delete $p->{cam};

    _log "add_despliegue => " . Data::Dumper::Dumper $p;

    my $rs = Baseliner->model('Harvest::BdePaqueteOracle')->create($p);

    return;
}

sub add_instancia {
    my ( $self, $p ) = @_;

    my $rs =
        Baseliner->model('Inf::Infvar')
        ->search( { valor => $p->{instancia} }, { columns => [qw/variable/] } );
    rs_hashref($rs);
    $p->{instancia} = $rs->next->{variable};

    _log "Dump => " . Data::Dumper::Dumper $p;

    my $new_row = Baseliner->model('Inf::InfCamOrainst')->create($p);

    return;
}

sub delete_des {
    my ( $self, $p ) = @_;

    my ( $propietario, $instancia ) = $p->{ora_instancia} =~ m/(.+)\sen\s(.+)/xi;

    $p->{ora_redes} =
        ( $p->{ora_redes} eq 'Internet' ) ? 'W' : ( $p->{ora_redes} eq 'Interna' ) ? 'I' : 'G';

    my $rs =
        Baseliner->model('Inf::Infvar')
        ->search( { valor => $instancia }, { columns => [qw/variable/] } );
    rs_hashref($rs);

    my $non_solved = $rs->next->{variable};

    $p->{ora_instancia} = "LN_${propietario}_${non_solved}";

    my $row = Baseliner->model('Harvest::BdePaqueteOracle')->search($p);
    $row->delete;

    return;
}

sub delete_ins {
    my ( $self, $p ) = @_;

    $p->{red} = ( $p->{red} eq 'Internet' ) ? 'W'
              : ( $p->{red} eq 'Interna' )  ? 'I'
              :                               'G'
              ;    # Modifico red a [ I / W / G ]

    # Capturo valor sin resolver...
    my $rs =
        Baseliner->model('Inf::Infvar')
        ->search( { valor => $p->{instancia} }, { columns => [qw/variable/] } );
    rs_hashref($rs);
    $p->{instancia} = $rs->next->{variable};

    open my $f, '>', 'C:\file.txt';
    print $f Data::Dumper::Dumper $p;

    my $row = Baseliner->model('Inf::InfCamOrainst')->search($p);
    $row->delete;

    return;
}

1;
