package BaselinerX::Ktecho::Inf::DB;
use Moose;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Compress::Zlib;
use Try::Tiny;
use strict;
use warnings;

sub db {
    my $self = shift;
    return Baseliner::Core::DBI->new( { model => 'Inf' } );
}

sub set_inf_scm_status {
    my ( $self, $args_ref ) = @_;
    my $cam      = $args_ref->{cam};
    my $status   = $args_ref->{status};
    my $inf_data = $args_ref->{inf_data};

    $self->db->do( "
        UPDATE $inf_data d 
        SET    d.scm_apl_crear = '$status' 
        WHERE  Upper(d.cam) = '$cam' 
               AND d.id = (SELECT Max(d2.id) 
                           FROM   $inf_data d2 
                           WHERE  Upper(d2.cam) = Upper(d.cam))  
    " );

    $self->db->do( "
        UPDATE $inf_data d 
        SET    d.readonly = readonly 
                             || '|#SCM_APL_CREAR#|#SCM_APL_PUBLICA#|#SCM_APL_SISTEMAS#' 
        WHERE  Upper(d.cam) = '$cam' 
               AND d.id = (SELECT Max(d2.id) 
                           FROM   $inf_data d2 
                           WHERE  Upper(d2.cam) = Upper(d.cam))  
    " );

    return;
}

#get_last_version : retorna el id de la última versión del form de inf. de un cam
sub get_last_version {
    my ( $self, $cam, $inf_data ) = @_;
    my ( $max_id, $cnt ) = $self->db( "
                                SELECT Max(id), 
                                       COUNT(*) 
                                FROM   $inf_data 
                                WHERE  cam = '$cam'  
                                " );

    # ¿¿¿ $cnt para qué ???
    return $max_id;
}

# Retorna un array de campos de la última versión de un form de inf. de un cam
sub get_inf {
    my ( $self, $args_ref ) = @_;

    my @fields  = _array( $args_ref->{fields} );
    my $cam_uc  = $args_ref->{cam_uc}  || q{};
    my $env_id  = $args_ref->{env_id}  || q{};
    my $red_id  = $args_ref->{red_id}  || q{};
    my $sub_apl = $args_ref->{sub_apl} || q{};

    my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');
    my $inf_data   = $config_bde->{inf_data};

    #    my $id = $self->get_last_version( $cam, $inf_data );    # Id de la fila a utilizar
    #    return () if ( !$id );
    #    $self->db->array( "
    #        SELECT " . join( ',', @fields ) . "
    #        FROM   $inf_data
    #        WHERE  id = $id
    #        " );

    my $sql = qq(
            SELECT column_name, valor
            FROM   $inf_data
            WHERE  column_name IN ( '" . join( q/', '/, @fields ) . "' )
                AND cam = $cam_uc
                AND ident = $env_id
                AND idred = $red_id
                AND idform = (SELECT MAX (idform)
                                FROM   inf_data
                                WHERE  cam = $cam_uc)
            );

    $sql .= "AND sub_aplicacion = $sub_apl" if $sub_apl;

    my %hash = $self->db->hash($sql);

    # Puede enviar los valores desordenados así que fuerzo el mismo orden que el dado en @fields...
    my $count = $[;
    my @sorted;

    push( @sorted, $hash{ $fields[ $count++ ] }[0] ) foreach (@fields);

    return \@sorted;
}

# Carga las variables de infraestructura en un Hash
sub inf_load_vars {
    my $self = shift;

    return $self->db->hash( "
                SELECT variable, 
                    valor 
                FROM   infvar  
                " );
}

sub inf_resolve_vars {
    my ( $self, $args_ref ) = @_;

    my $str  = $args_ref->{str};
    my $cam  = $args_ref->{cam};
    my $env  = $args_ref->{env};
    my %args = ();

    my %inf_variables = $self->inf_load_vars();

    foreach ( 0, 1 ) {
        %args = (
            'str'           => $str,
            'cam'           => $cam,
            'env'           => $env,
            'tipo'          => $_,
            'inf_variables' => \%inf_variables
        );
        $str = $self->inf_resolve_vars_internal( \%args );
    }
    return $str;
}

sub inf_resolve_vars_internal {
    my ( $self, $args_ref ) = @_;

    my $str           = $args_ref->{str};
    my $cam           = $args_ref->{cam};
    my $env           = $args_ref->{env};
    my $tipo          = $args_ref->{tipo};
    my %inf_variables = %{ $args_ref->{inf_variables} };

    $cam = lc($cam);

    my $cam_uc = uc($cam);
    my $emq    = q{};
    my $eaix   = q{};

    $env = lc( substr( $env, 0, 1 ) );

    my $env_uc = uc($env);

    if ( $cam ne q// ) {
        $str =~ s/\$\{cam\}/$cam/g;
        $str =~ s/\$\{cam_uc\}/$cam_uc/g;
    }
    if ( $env ne q// ) {
        $str =~ s/\$\{env\}/$env/g;
        $str =~ s/\$\{env_uc\}/$env_uc/g;
    }

    ## Sustitución de las variables entorno de AIX y MQ
    if ( $env_uc eq "T" ) {
        $str =~ s/\$\{eaix\}/t/g;
        $str =~ s/\$\{EAIX\}/T/g;

        $str =~ s/\$\{emq\}/p/g;
        $str =~ s/\$\{EMQ\}/P/g;
    }
    elsif ( $env_uc eq "A" ) {
        $str =~ s/\$\{eaix\}/a/g;
        $str =~ s/\$\{EAIX\}/A/g;

        $str =~ s/\$\{emq\}/a/g;
        $str =~ s/\$\{EMQ\}/A/g;
    }
    elsif ( $env_uc eq "P" ) {
        $str =~ s/\$\{eaix\}//g;
        $str =~ s/\$\{EAIX\}//g;

        $str =~ s/\$\{emq\}/e/g;
        $str =~ s/\$\{EMQ\}/E/g;
    }

    my ( $pos1,     $pos2 )      = ();
    my ( $var_name, $var_value ) = ();
    my $varstart = '${';
    my $varend   = '}';

    if ( $tipo eq "1" ) {
        $varstart = '$[';
        $varend   = ']';
    }

    if ( ( $pos1 = index( $str, $varstart ) ) > -1 ) {

        #es var
        $pos2 = index( $str, $varend );
        if ( $pos2 < 0 ) {
            return "$str";
        }
        $var_name = substr( $str, $pos1, $pos2 - $pos1 + 1 );

        #print "Vamos a buscar la variable $var_name\n";
        foreach my $key ( keys %inf_variables ) {

            #print "A ver si es la variable $key\n";
            if ( $key eq $var_name ) {
                $var_value = @{ $inf_variables{$key} }[0];

                #print "El valor encontrado para $key es $var_value\n";
                last;
            }
        }
        my $value = substr( $str, 0, $pos1 ) . $var_value . substr( $str, $pos2 + 1 );
        if ( index( $value, $varstart ) > -1 ) {
            my %args = ( 'value' => $value, 'cam' => $cam, 'env' => $env );
            return $self->inf_resolve_vars( \%args );
        }
        else {
            return $value;
        }
    }
    else {
        return $str;
    }
}

sub get_inf_subred {
    my ( $self, $args_ref ) = @_;

    # TODO: Falta saber de dónde sale $ENV{DEBUG}, y revisar lo de LN y W3 que
    # ya no se usan en Fase 2.

    my $cam_uc  = $args_ref->{cam_uc};
    my $env     = $args_ref->{env};
    my $sub_apl = $args_ref->{sub_apl};
    my $red     = $args_ref->{red};

    my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');

    #FIXME
    my $debug = $config_bde->{debug};

    my $log = Catalyst::Log->new;
    $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    my ( $red_ln, $red_w3 ) = $self->get_inf(
        'cam_uc'  => $cam_uc,
        'sub_apl' => $sub_apl,
        'fields'  => "LN_WAS,W3_WAS"
    );
    #TODO 

    if    ( $red_ln =~ m/S/i ) { $red = "LN"; }
    elsif ( $red_w3 =~ m/S/i ) { $red = "W3"; }
    else {
        throw distException "No se ha definido el tipo de red para aplicación-sub_aplicación "
            . "$cam_uc->$sub_apl en el formulario de infraestructura (campo WAS_RED)";
    }

    $log->debug( "RED de la sub_aplicación '$sub_apl': <b>$red</b> (Red Interna=$red_ln, Internet"
            . "=$red_w3)" ) if ($debug);

    return $red;
}

sub inf_es_ias {
    my ( $self, $args_ref ) = @_;
    my $env_name = $args_ref->{env_name};
    my $sub_apl  = $args_ref->{sub_apl};

    my ( $cam, $cam_uc ) = get_cam_uc($env_name);
    my $java_tech = $self->get_inf( $cam_uc, $sub_apl, "java_appl_tech" );

    return ( $java_tech =~ m/IAS/i ? 1 : 0 );
}

# get_unix_server_info :  retorna  un  array  de  campos  con  los datos de un
# servidor Unix
sub get_unix_server_info {
    my ( $self, $server, $fields_ref ) = @_;

    my @fields = _array($fields_ref);

    return $self->db->array( "
        SELECT " . join( ',', @fields )
        . " FROM   inf_server_unix 
            WHERE  Upper(Trim(server)) = Upper(Trim('$server'))  
        ");
}

# get_inf_unix_server:  devuelve  el nombre  del servidor  AIX del  tipo $tipo
# (ORACLE,HTTP,WAS)  de la  infraestructura de la  aplicación para  el entorno
# $ent (TEST, ANTE, PROD) y para el CAM $cam
sub get_inf_unix_server {
    my ( $self, $args_ref ) = @_;
    my $cam  = $args_ref->{cam};
    my $ent  = $args_ref->{ent};
    my $tipo = $args_ref->{tipo};
    my $red  = $args_ref->{red};

    my @resultado        = ();
    my $server_plus_type = q{};

    print "\nBuscando servidor de tipo $tipo para $cam en el entorno $ent\n";

    my $columna = $self->get_inf( $cam, "${ent}_${red}_aix_server" );

    print "Columna ${ent}_${red}_aix_server = $columna\n";

    my @servers = split( /\|/, $columna );

    foreach my $server (@servers) {
        $server =~ /^(.*?)\((.*?)\)/;

        my $server_name = $1;
        my $server_type = $2;

        $server_name = $self->inf_resolve_vars( $server_name, $cam, $ent );

        print "Evaluando servidor $server_name de tipo $server_type\n";

        if ( $server_type eq $tipo ) {
            @resultado = ( $server_name, $server );
            last;
        }
    }

    return @resultado;
}

# $self->get_inf_destinos : destino de distrib. unix 
sub get_inf_destinos {
    my ( $self, $args_ref ) = @_;

    my $log = Catalyst::Log->new;
    $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    my $cam_uc  = $args_ref->{cam_uc};
    my $env     = $args_ref->{env};
    my $sub_apl = $args_ref->{sub_apl};

    my $config_bde  = Baseliner->model('ConfigStore')->get('config.bde');
    my $debug       = $config_bde->{debug};
    my $staunixport = $config_bde->{staunixport};

    my %destinos = ();

    my $es_ias = $self->inf_es_ias( $cam_uc, $sub_apl );

    my $red = $self->$self->get_inf_subred( cam_uc => $cam_uc, env => $env, sub_apl => $sub_apl );
    my $red_txt = ( uc($red) eq "LN" ? "red Interna" : "Internet" );

    $log->debug("red ($cam_uc,$env,$sub_apl) = $red\n") if ($debug);

    my $cam = lc($cam_uc);
    my $e   = substr( lc($env), 0, 1 );

    $destinos{sub_apl} = $sub_apl;
    $destinos{maq} = $self->inf_resolve_vars( $self->get_inf( $cam_uc, "${env}_${red}_was_server" ) );

    $destinos{server_cluster} =
        $self->inf_resolve_vars( $self->get_unix_server_info( $destinos{maq}, "server_cluster" ) );

    if ( !$destinos{maq} ) {
        throw distException "No tengo el servidor WAS para el env $env ($red_txt) en el formulario"
            . " de Infraestructura (campo ${env}_${red}_was_server, pestaña AIX)";
    }

    $destinos{puerto} = $staunixport;
    $destinos{red}    = $red;

    my $user_auth = $self->get_inf( $cam_uc, "${env}_${red}_aix_ufun_auth" );
    my @AUTH = split /\|/, $user_auth;

    foreach my $auth (@AUTH) {
        my ( $serv, $usr, $grp ) = split( /\;/, $auth );
        $serv = $self->inf_resolve_vars( $serv, $cam_uc, $env );
        $log->info("AUTH: $serv:$usr:$grp") if ($debug);
        if ( uc($serv) eq uc( $destinos{maq} ) ) {
            ## se desactiva el Bypass a peticion de BDE el 22/02/2010
            ##	$usr="vtsct" if($usr=~/vpsct/);
            ##	$grp="gtsct" if($grp=~/gpsct/);
            $destinos{user}  = $usr;
            $destinos{group} = $grp;
        }
    }

    if ( !$destinos{user} or !$destinos{group} ) {
        throw distException "No tengo el usuario destino para el servidor $destinos{maq} en el "
            . "formulario de Infraestructura (campo ${env}_${red}_aix_ufun_auth)";
    }

    $destinos{was_user}  = 'vpwas';
    $destinos{was_group} = 'gpwas';

    my ($dest_script) = $self->get_inf( $cam_uc, $sub_apl, "${env}_script_despliegue" );

    if ($dest_script) {
        $destinos{script} = $self->inf_resolve_vars( $dest_script, $cam_uc, $env );
    }
    else {
        $destinos{script} = "/home/aps/was/scripts/gen/${cam_uc}/j2eeTools${cam_uc}.sh";
    }

    # Temporal para EAR
    $destinos{home} = lc("/tmp");

    #  Se cambia para extraer el dato por sub_apl . q74313 30/08/2010
    my $hay_reinicio = $self->get_inf( $cam_uc, $sub_apl, "was_restart" );  ## start-stopApplication
    $destinos{reinicio} = ( $hay_reinicio =~ m/Si/i ? 1 : 0 );

    # Parámetro de reinicio servidor WEB web en update_ear
    $hay_reinicio = $self->get_inf( $cam_uc, $sub_apl, "was_webrestart" );
    $destinos{reinicio_web} = ( $hay_reinicio =~ m/Si/i ? 1 : 0 );

    # DM Version
    $destinos{was_ver} = $self->get_inf( $cam_uc, $sub_apl, "${env}_was_server_dmgr_version" );

    if ( $destinos{was_ver} eq q// ) {
        $log->warn( "Aviso: Falta rellenar la versión de DMGR de WAS en el formulario de " 
            . "Infraestructura del cam_uc-> $cam_uc en la pestaña de la sub_apl-> $sub_apl-> "
            . "Versión de DMGR de la aplicación)"
        );
    }

    $destinos{was_ver} =~ s/^(.*?)\.(.*?)$/$1$2/g;
    $destinos{was_ver} =~ s/0//g;
    $destinos{was_ver} = "6" if ( $destinos{was_ver} eq q// );

	# Server Version
    $destinos{was_server_ver} = $self->get_inf( $cam_uc, $sub_apl, "${env}_was_server_version" );

    if ( $destinos{was_server_ver} eq q// ) {
        $log->warn( "Aviso: Falta rellenar la versión de WAS en el formulario de Infraestructura "
                . "de $cam_uc (pestaña [$sub_apl]-Servidor WAS-Información Avanzada-Versión de WAS)"
        );
    }

    $destinos{was_server_ver} =~ s/^(.*?)\.(.*?)$/$1$2/g;
    $destinos{was_server_ver} =~ s/0//g;
    $destinos{was_server_ver} = "6" if ( $destinos{was_server_ver} eq q// );
	
    # HTTP
    $destinos{htp_puerto} = $destinos{puerto};
    $destinos{htpuser}    = "v${e}${cam}";
    $destinos{htpgroup}   = "g${e}${cam}";

    my ( $servidor_var, $nombre_con_var ) = $self->get_inf_unix_server(
        cam_uc => $cam_uc,
        env    => $env,
        tipo   => 'HTTP',
        red    => $red
    );

    #( $destinos{htp_maq} )=$self->get_inf($cam_uc,$sub_apl,"${env}_${red}_WAS_VERSION" );
    $destinos{htp_maq} = $servidor_var;

    $destinos{htp_server_cluster} =
        $self->inf_resolve_vars( $self->get_unix_server_info( $destinos{htp_maq}, "server_cluster" ) );

    # home/aps/htp/$cam
    $destinos{htp_dir} = $self->get_inf_unix_serverDir( $cam_uc, $env, $nombre_con_var, $red );

	## IAS CONFIG
	##my ($servConfig,$dirConfig,$sizeConfig) = $self->get_infTipo($cam_uc,"(WAS)","${env}_${red}_AIX_CONFIG_DIRS");
	#$destinos{config_dir}="/home/grp/was/j2eeaps/$sub_apl/config"; 
    $destinos{tech}             = $self->get_inf( $cam_uc, $sub_apl, "java_appl_tech" );
    $destinos{config_dir}       = $self->get_inf( $cam_uc, $sub_apl, "was_config_path" );
    $destinos{waslogdir}        = $self->get_inf( $cam_uc, $sub_apl, "${env}_was_log_path" );
    $destinos{was_context_root} = $self->get_inf( $cam_uc, $sub_apl, "was_context_root" );

    if ( $destinos{was_context_root} eq q// ) {
        $log->warn( "Campo del formulario de infraestructura 'Context-root' vacío. Utilizando el "
                . "nombre de sub_aplicación '$sub_apl'." );
        $destinos{was_context_root} = $sub_apl;
    }

    ## gdf 58340, cam SAC, ahora hace falta concatenar el context-root
    $destinos{htp_dir} .= "/" . $destinos{was_context_root};

    ## quita dobles barras
    $destinos{htp_dir} =~ s{//}{/}g;
	
    # Este flag indica si debemos distribuir o no en el servidor.  No se puede
    # distribuye si no está instalado el agente harax, por ejemplo.

    $destinos{desplegar_flag} = $self->get_unix_server_info( $destinos{htp_maq}, "desplegar_flag" );
	
    $log->debug( "Destino de despliegue para $cam_uc->$sub_apl ($env): $destinos{maq}:"
            . "$destinos{puerto} ($destinos{user}:$destinos{group}). Script=$destinos{script}. "
            . "Versión de WAS=$destinos{was_ver}. Home=$destinos{home}.  WasUser=$destinos{was_user}"
            . ":$destinos{was_group}. HTTP=$destinos{htp_maq}($destinos{htp_puerto}):"
            . "$destinos{htp_dir}. Context-root: $destinos{was_context_root} "
            . ( $destinos{reinicio} eq 1 ? "- Con Reinicio WAS. " : q// )
            . ( $es_ias ? " IASConfig=$destinos{config_dir}. " : q// )
            . "Flag desplegar =$destinos{desplegar_flag}",
        YAML::Dump( \%destinos )
    );

    return \%destinos;
}

1;
