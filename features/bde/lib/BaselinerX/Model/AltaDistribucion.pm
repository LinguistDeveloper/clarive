package BaselinerX::Model::AltaDistribucion;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use Catalyst::Log;
use v5.10;
use strict;
use warnings;
use Try::Tiny;
use Catalyst '-Log=info,debug,error,warn';
BEGIN { extends 'Catalyst::Model' }

sub set_variables_iniciales {
    my $self = @_;
    
    return {
        ret                 => 0,
        es_repeticion       => 0,
        es_backout_pre_emer => 0,
        modo_alta_pase      => "Y",
        pase_entorno        => q//
    };
}

sub get_start_date {
    my ( $self, $init_start_date ) = @_;
    my $db   = Baseliner::Core::DBI->new( { model => 'Harvest' } );

    return $db->value( "
        SELECT To_char(To_date('$init_start_date', 'YYYYMMDDHH24MISS'), 
               'DD/MM/YYYY HH24:MI') 
        FROM   dual  
        " );
}

sub get_packages_pase_r {
    my ( $self, $env_name, $entorno ) = @_;
    my $db = Baseliner::Core::DBI->new( { model => 'Harvest' } );

    return $db->array(
        qq/
            SELECT DISTINCT p.packagename 
            FROM   distpase d, 
                harpackage p, 
                harenvironment e, 
                dist_paquete_pase pp 
            WHERE  pp.pase = d.pas_codigo 
                AND pp.packageobjid = p.packageobjid 
                AND p.envobjid = e.envobjid 
                AND e.environmentname = '$env_name' 
                AND d.pas_tipo = '$entorno' 
                AND To_number(Substr(d.pas_codigo, 7)) = (SELECT MAX(To_number(Substr(d2.pas_codigo, 7))) 
                                                            FROM   distpase d2, 
                                                                    bde_paquete fp2, 
                                                                    harassocpkg a2, 
                                                                    harpackage p2, 
                                                                    harenvironment e2, 
                                                                    dist_paquete_pase pp2 
                                                            WHERE  pp2.pase = d2.pas_codigo 
                                                                    AND pp2.packageobjid = p2.packageobjid 
                                                                    AND p2.envobjid = e2.envobjid 
                                                                    AND e2.environmentname LIKE '$env_name' 
                                                                    AND d2.pas_tipo = '$entorno')  
        /
    );
}

sub get_packages_pase_be {
    my ( $self, $env_id, $env_name ) = @_;
    my $db = Baseliner::Core::DBI->new( { model => 'Harvest' } );

    return $db->array(
        qq/
            SELECT p.packagename 
            FROM   harpackage p, 
                harstate s, 
                harenvironment e 
            WHERE  p.envobjid = $env_id 
                AND p.stateobjid = s.stateobjid 
                AND p.envobjid = e.envobjid 
                AND s.statename = 'Preproducción' 
                AND e.environmentname LIKE '$env_name' 
                AND Upper(e.environmentname) NOT LIKE '%DOCUMENTACIÓN'  
        /
    );
}

sub get_tipo_red {
    my ( $self, $env_name ) = @_;
    my $red;

    $red = "LN" if ( $env_name =~ m/red Interna/i );
    $red = "W3" if ( $env_name =~ m/Internet/i );

    return $red;
}

sub get_ciclo {
    my ( $self, $package_id ) = @_;

    my $db = Baseliner::Core::DBI->new( { model => 'Harvest' } );

    return $db->array(
        qq/
            SELECT p.formobjid, 
                TRIM(paq_tipo), 
                Substr(paq_ciclo, 1, 1) 
            FROM   bde_paquete p, 
                harassocpkg a, 
                harform hf, 
                harpackage hp 
            WHERE  p.formobjid = a.formobjid 
                AND a.formobjid = hf.formobjid 
                AND a.assocpkgid = hp.packageobjid 
                AND hf.formname = hp.packagename 
                AND a.assocpkgid = $package_id
        /
    );
}

#===  FUNCTION  ================================================================
#         NAME:  crea_pase
#      PURPOSE:  To create a 'pase'
#   PARAMETERS:  Tons of them
#      RETURNS:  $c_pase 
#                   0 = Todo OK: UPDATE en BDE_PAQUETE con el código del pase.
#                   1 = Dies con código y mensaje de error.
#  DESCRIPTION:  Crea un nuevo pase.
#     COMMENTS:  Necesario:
#                   - Que estén informados los destinos correspondientes.
#                   - Que los destinos tengan los datos necesarios.
#===============================================================================
sub crea_pase {
    my ( $self, $args_ref ) = @_;
    my $pase_entorno        = $args_ref->{pase_entorno};
    my $state_name          = $args_ref->{state_name};
    my $env_name            = $args_ref->{env_name};
    my $tipo_pase           = $args_ref->{tipo_pase};
    my $init_start_date     = $args_ref->{init_start_date};
    my $modo_alta_pase      = $args_ref->{modo_alta_pase};
    my $user_name           = $args_ref->{user_name};
    my $red                 = $args_ref->{red};
    my $previous_state_name = $args_ref->{previous_state_name};
    my $end_start_date      = $args_ref->{end_start_date};
    my $fecha_log           = $args_ref->{fecha_log};

    my $log = Catalyst::Log->new;
    $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    my $inf_db = BaselinerX::Ktecho::INF::DB->new;

    my $seq = $inf_db->db->value( "
                  SELECT distpasedesa.nextval 
                  FROM   dual  
                  " );

    if ( !$pase_entorno ) {
        print "\t\t>>>>Error al crear el pase: no se ha podido identificar el entorno del pase para"
            . "el estado '$state_name'\n";
        exit 19;
    }

    my ( $cam, $cam_uc ) = get_cam_uc($env_name);
    my ($inf_entornos) = $inf_db->get_inf( $cam_uc, "MAIN_ENTORNOS" );
    if ( ( !( $inf_entornos =~ m/ANTE/i ) && ( $pase_entorno =~ /ANTE/ ) ) ) {
        print "\n\t\t>>>>>>>>>>>>>>>> ERROR: esta aplicación $cam_uc no tiene distribución a "
            . "Preproducción (ANTE).\nModifique los entornos disponibles para $cam_uc en el "
            . "formulario de infraestructura (General->Información Adicional) o genere un pase "
            . "directamente a Producción.";
        exit 76;
    }

    my $c_pase = sprintf( "%s.%s%010d", $tipo_pase, $pase_entorno, $seq );

    # Creamos un nuevo pase para atender la petición.
    if ( $init_start_date eq "now" ) {
        my %values = (
            'pas_codigo'     => $c_pase,
            'pas_tipo'       => $pase_entorno,
            'pas_desde'      => "TO_DATE('" . ahora_log() . "','YYYYMMDDHH24MISS')",
            'pas_hasta'      => "TO_DATE('" . ahora_log() . "','YYYYMMDDHH24MISS') + 1/24",
            'pas_estado'     => $modo_alta_pase,
            'pas_usuario'    => $user_name,
            'pas_aplicacion' => $env_name,
            'pas_statename'  => $state_name,
            'pas_red'        => $red,
            'pa_from'        => $previous_state_name
        );

        my $new_pase = Baseliner->model('Bali::Distpase')->create( \%values );

=begin  BlockComment  # Query Original

        INSERT INTO distpase 
                    (pas_codigo, 
                     pas_tipo, 
                     pas_desde, 
                     pas_hasta, 
                     pas_estado, 
                     pas_usuario, 
                     pas_aplicacion, 
                     pas_statename, 
                     pas_red, 
                     pas_from) 
        VALUES      ('$c_pase', 
                     '" . $pase_entorno . "', 
                     To_date('" . ahora_log() . "', 'YYYYMMDDHH24MISS'), 
                     To_date('" . ahora_log() . "', 'YYYYMMDDHH24MISS') + 1 / 24, 
                     '$modo_alta_pase', 
                     '$user_name', 
                     '$env_name', 
                     '$state_name', 
                     '$red', 
                     '$previous_state_name' )  

=end    BlockComment 

=cut

    }
    else {
        my %values = (
            'pas_codigo'     => $c_pase,
            'pas_tipo'       => $pase_entorno,
            'pas_desde'      => "To_date('$init_start_date', 'YYYYMMDDHH24MISS')",
            'pas_hasta'      => "To_date('$end_start_date', 'YYYYMMDDHH24MISS')",
            'pas_estado'     => $modo_alta_pase,
            'pas_usuario'    => $user_name,
            'pas_aplicacion' => $env_name,
            'pas_statename'  => $state_name,
            'pas_red'        => $red,
            'pas_from'       => $previous_state_name
        );

        my $new_pase = Baseliner->model('Bali::Distpase')->create( \%values );
        
=begin  BlockComment  # Query Original

INSERT INTO distpase 
            (pas_codigo, 
             pas_tipo, 
             pas_desde, 
             pas_hasta, 
             pas_estado, 
             pas_usuario, 
             pas_aplicacion, 
             pas_statename, 
             pas_red, 
             pas_from) 
VALUES      ('$c_pase', 
             '"             . $pase_entorno             . "', 
             To_date('$init_start_date', 'YYYYMMDDHH24MISS'), 
             To_date('$end_start_date', 'YYYYMMDDHH24MISS'), 
             '$modo_alta_pase', 
             '$user_name', 
             '$env_name', 
             '$state_name', 
             '$red', 
             '$previous_state_name' )            

=end    BlockComment

=cut

    }

    # Rodrigo: insertamos la creacion del pase en log
    #TODO logstart( $c_pase, "DIS" );
    if ( $init_start_date eq "now" ) {
        $log->info("Pase creado por el usuario $user_name para ejecución inmediata.");
    }
    else {
        $log->info( "Pase planificado por el usuario <b>$user_name</b> para su ejecución el "
                . "<b>$fecha_log</b>" );
    }
    #TODO ocommit;

    return $c_pase;
}

sub actualizar_paquete {
    my ( $self, $args_ref ) = @_;
    my $form_id    = $args_ref->{form_id};
    my $paquete    = $args_ref->{paquete};
    my $pase_id    = $args_ref->{pase_id};
    my $har_db     = BaselinerX::Ktecho::Harvest::DB->new;
    my $package_id = $har_db->get_package_id($paquete);

    # Actualizamos el código de pase en la petición.
    my %where  = ( 'formobjid'  => $form_id );
    my %values = ( 'pas_codigo' => $pase_id );
    my $update_row = Baseliner->model('Bali::Bdepaquete')->search(%where);
    $update_row->update( \%values );

    %values = ( 'packageobjid' => $package_id, 'paquete' => $paquete, 'pase' => $pase_id );
    my $new_paquete_pase = Baseliner->model('Bali::Distpaquetepase')->create( \%values );

    #TODO ocommit;

    return;
}

sub update_motivo_distpase {
    my ( $self, $pase_id, $motivos_pase ) = @_;

    my %where  = ( 'pas_codigo'  => $pase_id );
    my %values = ( 'pas_motivos' => $motivos_pase );
    my $update_row = Baseliner->model('Bali:Distpase')->search(%where);
    $update_row->update( \%values );

    return $update_row;
}


#===  FUNCTION  ================================================================
#         NAME:  datos_paquete
#      PURPOSE:  To validate whether the packet is assigned to a pass.
#                Ideal scenario: Not assigned.
#   PARAMETERS:  ????
#      RETURNS:  0 = OK.
#                1 = Error message.
#===============================================================================
sub datos_paquete {
    my ( $self, $args_ref ) = @_;

    # Gets variable values from args_ref...
    my $package_id          = $args_ref->{package_id};
    my $package_name        = $args_ref->{package_name};
    my $tipo_pase           = $args_ref->{tipo_pase};
    my $es_repeticion       = $args_ref->{es_repeticion};
    my $state_name          = $args_ref->{state_name};
    my $env_name            = $args_ref->{env_name};
    my $previous_state_name = $args_ref->{previous_state_name};

    my @q_res;    # Esto estaba en el código antiguo, pero no se usa... ¿?
    my $pas_estado;

    my $query = qq/
        SELECT p.formobjid, 
               TRIM(paq_tipo), 
               Substr(paq_ciclo, 1, 1) 
        FROM   bde_paquete p, 
               harassocpkg a, 
               harform hf, 
               harpackage hp 
        WHERE  p.formobjid = a.formobjid 
               AND a.formobjid = hf.formobjid 
               AND a.assocpkgid = hp.packageobjid 
               AND hf.formname = hp.packagename 
               AND a.assocpkgid = $package_id  
    /;

    my $retorno = 0;

    # Estancia de DB Harvest...
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my ( $form_id, $c_pase, $ciclo_vida ) = $har_db->db->array($query);
    
    # Devuelve el pase más reciente del paquete...
    my ($t_pase) = $har_db->db->array(
        qq/
            SELECT pase 
            FROM   dist_paquete_pase pp, 
                    distpase d 
            WHERE  pp.packageobjid = $package_id 
                    AND d.pas_codigo = pp.pase 
            ORDER  BY pas_hasta DESC  
        /
    );

    if ( $har_db->get_package_num_items($package_id) == 0 ) {
        $retorno++;
        print "\t\tEl paquete $package_name no contiene ningún elemento\n";
    }

    my $n_estado = $har_db->db->value(
        qq/
            SELECT statename 
            FROM   harstate s, 
                    harpackage pk 
            WHERE  s.stateobjid = pk.stateobjid 
                    AND pk.packageobjid = $package_id  
        /
    );

    if ($c_pase) {
        $pas_estado = $har_db->db->value(
            qq/
                SELECT pas_estado 
                FROM   distpase 
                WHERE  pas_codigo = '$c_pase'  
            /
        );

        # Si es null, es pq se ha borrado el pase
        if ( ( $pas_estado ne q// ) and ( $pas_estado !~ /[FPELTCKWX]/ ) ) {
            $retorno++;
            print "El paquete $package_name está asociado a otro pase ($c_pase) no finalizado"
                . " ($pas_estado)\n";
        }
    }

    if (   ( $tipo_pase eq 'N' )
        && ( !$es_repeticion )
        && ( $state_name eq "Preproducción" || $state_name eq "Producción" ) )
    {
        # Chequeo de aprobadores deshabilitado
        if (0) {
            my @acciones = $har_db->db->array(
                qq/
                    SELECT TRIM(ACTION) 
                    FROM   harapprovehist h, 
                            harstate s, 
                            harenvironment e 
                    WHERE  h.packageobjid = $package_id 
                            AND h.stateobjid = s.stateobjid 
                            AND TRIM(s.statename) = TRIM('$n_estado') 
                            AND h.envobjid = e.envobjid 
                            AND TRIM(e.environmentname) LIKE TRIM('$env_name') 
                            AND TRIM(e.environmentname) NOT LIKE '%Documentación' 
                    ORDER  BY execdtime DESC  
                /
            );

            my ($accion) = @acciones;
            if ( $accion !~ m/Approved/i ) {
                $retorno++;
                print "\t\tEl paquete $package_name no está aprobado\n (Ultima accion: '$accion')";

                # print "\nacciones registradas:\n".join("\n",@acciones)
            }
        }
    }

    # Chequeo si es un paquete de aplicación pública (Tiene que tener un package group 'release'
    # asociado.
    #TODO Esto viene de infraestructura.
    my $inf_db = BaselinerX::Ktecho::INF::DB->new;
    if ( $inf_db->inf_es_publica($env_name) ) {
        my $cnt = $har_db->get_package_groups($package_name);
        if ( $cnt < 1 ) {
            $retorno++;
            print "\t\tEl paquete $package_name no está asociado a un grupo de paquetes (release "
                . "de aplicación publica $env_name).\n";
        }
        elsif ( $cnt > 1 ) {
            $retorno++;
            print "\t\tEl paquete $package_name está asociado a más de un grupo de paquetes "
                . "(release de aplicación publica $env_name).\n";
        }
    }

    # $n_estado = "Desarrollo" if($n_estado eq "Pruebas");	## permite distribuir desde Pruebas
    my $tiene_ante = aplTieneAnte($env_name);

    print "\n\nTiene ante: $tiene_ante\n\n";
    print "\n\nCiclo de vida: $ciclo_vida\n\n";

    if ( $previous_state_name ne $n_estado ) {
        if ( ( $ciclo_vida eq "R" ) || ( ( $ciclo_vida eq "E" ) && ( $tiene_ante eq "No" ) ) ) {
            ##si no es CV Rápido, hay que coincidir estados
        }
        else {
            $retorno++;
            print "\n\t ERROR DE ESTADO: El Paquete '$package_name' no está en el estado "
                . "$previous_state_name, sino en $n_estado. Refresque la aplicación.";
        }
    }

    # Si no es CV Rápido, hay que coincidir estados
    if ( ( uc($state_name) =~ /PREP/ ) && ( $ciclo_vida eq "R" ) && ( $tipo_pase ne "B" ) ) {
        $retorno++;
        print "\n\t ERROR: El Paquete '$package_name' es de ciclo RÁPIDO y no se distribuye a "
            . "Preproducción. Cambie el tipo de Ciclo de Vida en el formulario. ";
    }

    return $retorno;
}

1;
