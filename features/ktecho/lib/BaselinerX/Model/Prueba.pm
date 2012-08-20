package BaselinerX::Model::Prueba;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub _msgs {
    my $self = shift;

    return (
        msg_prod    => "No tiene acceso al entorno PROD.",
        msg_control => "<img style='filter: gray' border=0 alt='No tiene acceso al control de "
            . "arranque/parada' src='images/delete.gif' />",
        msg_logs => "<img style='filter: gray' border=0 alt='No tiene acceso a los logs' src="
            . "'images/delete.gif' />",
        msg_config => "<img style='filter: gray' border=0 alt='No tiene acceso al config' src="
            . "'images/delete.gif' />"
    );
}

sub _cam {
    my ($self, $args_ref ) = @_;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $username        = $args_ref->{username};
    my $usuario_potente = $args_ref->{usuario_potente};

    my $inf_data = ( $args_ref->{inf_data} == 'inf_data' ) ? 'inf_data_inf' : $args_ref->{inf_data};

    my $sql = "
        SELECT DISTINCT Substr(environmentname, 1, 3) cam 
        FROM   harenvironment he 
        WHERE  he.envisactive = 'Y' 
            AND Substr(environmentname, 1, 3) IN (SELECT DISTINCT idt4.cam 
                                                    FROM   $inf_data idt4 
                                                    WHERE  column_name = 'TEC_JAVA' 
                                                            AND valor = 'Si' 
                                                            AND idt4.idform = (SELECT MAX(ifi.idform) 
                                                                            FROM   inf_form_inf ifi 
                                                                            WHERE 
                                                                Substr(he.environmentname, 1, 
                                                                3) 
                                                                = ifi.cam))  
        ";

    if ( !$usuario_potente ) {
        $sql .= "
            AND EXISTS (SELECT * 
                        FROM   harusergroup ug, 
                                harusersingroup gg, 
                                haruser u 
                        WHERE 
                Upper(Trim(u.username)) = Upper('$username') 
                AND u.usrobjid = gg.usrobjid 
                AND ug.usrgrpobjid = gg.usrgrpobjid 
                AND Upper(Trim(ug.usergroupname)) = Upper( 
                    Substr(he.environmentname, 1, 3)))  
            ";
    }

    $sql .= " ORDER  BY 1 ";

    return $har_db->db->array($sql);
}

sub _sub_apl {
    my ( $self, $args ) = @_;

    my @cam_array = _array( $args->{cam_array} );
    my $inf_data  = $args->{inf_data};
    my $kk        = 0;
    my @sa        = ();
    my $success_test;
    my $success_ante;
    my $success_prod;

    foreach (@cam_array) {
        my $cam_uc = $_;
        my $inf_db = BaselinerX::Ktecho::INF::DB->new;

        # Averiguo la lista de sub_apl java
        my $sql = "
            SELECT d.subaplicacion, 
                e.descripcion 
            FROM   $inf_data d, 
                inf_entorno e 
            WHERE  d.cam = '$cam_uc' 
                AND d.column_name = 'JAVA_APPL' 
                AND d.ident = e.ident 
            ORDER  BY idform DESC  
                ";

        my @sub_apl_array = $inf_db->db->array($sql);

        my $sub_apls = shift @sub_apl_array if ( !@sub_apl_array );
        my $entornos = shift @sub_apl_array if ( !@sub_apl_array );

        # Ahora sólo hay un entorno, no hace falta hacer esto, pero lo dejo comentado
        # my $tiene_ante = ( $entornos and 'ANTE' ~~ $entornos ) ? 'true' : undef;

        my $tiene_ante = ( ( $entornos == 'ANTE' ) ? 'true' : undef );

        push( @sa, $entornos );

        # Averiguar si se ha concedido el servidor was en cada entorno

        $sql = "
            SELECT env, 
                COUNT(*) 
            FROM   inf_status_hist 
            WHERE  cam = '$cam_uc'
                AND column_name LIKE '%_WAS_SERVER' 
                AND status = 'SUCCESS' 
            GROUP  BY env  
            ";

        my %env_arr_hash = $inf_db->db->array_hash($sql);

        foreach my $value ( keys %env_arr_hash ) {
            if ( $env_arr_hash{$value}[1] ) {
                $success_test = 'true' if ( $env_arr_hash{$value}[0] =~ /T/i );
                $success_ante = 'true' if ( $env_arr_hash{$value}[0] =~ /A/i );
                $success_prod = 'true' if ( $env_arr_hash{$value}[0] =~ /P/i );
            }    # --- end if ---
        }    # --- end foreach ---
    }    # --- end foreach ---

    return (
        sa           => \@sa,
        success_test => $success_test,
        success_ante => $success_ante,
        success_prod => $success_prod
    );
}

1;
