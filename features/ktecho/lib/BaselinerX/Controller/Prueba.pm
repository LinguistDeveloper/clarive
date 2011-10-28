package BaselinerX::Controller::Prueba;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

# creo el "botón" dentro de la pestaña de administrador
register 'menu.admin.pinta' => {
    label    => 'Consola de Aplicaciones J2EE',
    url      => 'prueba/pprueba',
    title    => 'Consola de Aplicaciones J2EE'
};

sub pinta : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    $c->res->headers->header( 'Cache-Control' => 'no-cache, post-check=0, pre-check=0' );
    $c->res->headers->header( 'Pragma'        => 'no-cache'                            );
    $c->res->headers->header( 'Expires'       => 'Tues, 01 Jan 1980 00:00:00 GMT'      );

    # Saca los datos de usuario de la sesion 
    my $username = $c->session->{usuario};
    my $usuario  = BaselinerX::Ktecho::Harvest::Usuario->new();

    if ( !$usuario ) {
        # no tengo login, le echo
        #$c->stash->{args} = ...
        $c->stash->{template} = 'consola_do.html';
        $c->forward('View::Mason');

        return;
    }
    else {
        $username = $usuario->harvest_user($username);
    }

    my $servlet_url     = $c->request->{path} || $c->request->path;
    my $filtro1         = $p->{filtro1};
    my $filtro2         = $p->{filtro2};
    my $interno         = ( $p->{interno} ne 'false' ) ? 'true' : undef;
    my $cam             = $p->{cam};
    my $env             = $p->{env};
    my $sub_apl         = $p->{sub_apl};
    my $usuario_consola = Baseliner::Ktecho::Harvest::UsuarioConsola->new;
    my $usuario_potente = $usuario_consola->{usuario_potente};
    my $show_prod       = 'true';
    my $msg_ref         = $c->model('Prueba')->_msgs();
    my $msg_prod        = $msg_ref->{msg_prod};
    my $msg_control     = $msg_ref->{msg_control};
    my $msg_logs        = $msg_ref->{msg_logs};
    my $msg_config      = $msg_ref->{msg_config};
    my $config_bde      = Baseliner->model('ConfigStore')->get('config.bde');
    my $inf_data        = $config_bde->{inf_data};

    my @cam_array = $c->model('Prueba')->_cam(
        inf_data        => $inf_data,
        username        => $username,
        usuario_potente => $usuario_potente
    );

    # CALL HEADER

    foreach (@cam_array) {
        my $clase = 'par';
        my $columns = ($show_prod) ? 19 : 14;

        my $args_sub_apl = $c->model('Prueba')->_sub_apl(
            cam_array => \@cam_array,
            inf_data  => $inf_data
        );

        my @sa           = _array( $args_sub_apl->{sa} );
        my $success_test = $args_sub_apl->{success_test};
        my $success_ante = $args_sub_apl->{success_ante};
        my $success_prod = $args_sub_apl->{success_prod};

        # CALL BODY
    }

    # CALL FOOTER
}

sub pinta_hash : Local {
    my ( $self, $c ) = @_;

    use Data::Dumper;

    my $sql = qq{
        SELECT DISTINCT Substr(environmentname, 1, 3) cam, 
                        idmv.mv_valor
        FROM   harenvironment he, 
            inf_data_inf idt,
            inf_data_mv_f2 idmv
        WHERE  he.envisactive = 'Y' 
            AND Substr(environmentname, 1, 3) IN (SELECT DISTINCT idt4.cam 
                                                    FROM   inf_data_inf idt4 
                                                    WHERE  column_name = 'TEC_JAVA' 
                                                            AND valor = 'Si' 
                                                            AND idt4.idform = (SELECT MAX(ifi.idform) 
                                                                            FROM   inf_form_inf ifi 
                                                                            WHERE  Substr(he.environmentname, 1, 3) = ifi.cam)) 
            AND idt.idform = (SELECT MAX(ifi.idform) 
                                FROM   inf_form_inf ifi 
                                WHERE  Substr(he.environmentname, 1, 3) = ifi.cam) 
            AND idt.column_name = 'JAVA_APPL'
            AND Substr(environmentname, 1, 3) = idt.cam
            AND idt.valor = '@#' || idmv.id
            AND idt.idform = idmv.idform
        ORDER BY 1
        };

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my @cam = $har_db->db->array_hash($sql) or croak("No puedo con la query.\n");

    # Abro fichero
    my $filename = 'C:\prueba4.txt';
    open my $FILE, '>', $filename or croak("No puedo abrir el fichero $filename.\n");

    # Inicializo el hash que imprimiré en el fichero... 
    my %hash = ();

    for my $href (@cam) {

        # no hace falta condición,  si existe hace  un push y si no crea key y
        # value
        push @{ $hash{ $href->{cam} } }, $href->{mv_valor};
    }

    #  Nota:  newvalue  no  puede  ser  nulo.  En  un  futuro  nos  interesará
    # capturarlo para  poder hacer esta query filtrando  por subaplicación (en
    # inf_data)  y no  por cam,  ya  que ahora  mismo no  existe subaplicación
    # asocuida a estos valores.
    my @cam_env = $har_db->db->array_hash( "
                        SELECT ist.cam, 
                            ist.env 
                        FROM   inf_status_ ist, 
                            inf_peticion_tarea_ ipt 
                        WHERE  ipt.idpeticion = ist.idpeticion 
                            AND ipt.taskname = ist.correlation 
                            AND ipt.status = 'SUCCESS' 
                            AND ist.column_name = 'WAS_SERVER'
                            AND ist.newvalue IS NOT NULL
                        ORDER  BY 1  
                        " );


    # Futuro hash a usar...
    my %envs_in_cam = ();

    for my $href (@cam_env) {

        # Creo un hash donde cam es la key y env el array de entornos
        push @{ $envs_in_cam{ $href->{cam} } }, $href->{env};
    }

    # En mason para  imprimir la tabla voy iterando por el  cam y luego por el
    # entorno.  En lugar de usar  los valores success* de consola.jsp,  lo que
    # haré  será comprobar si  el primer dígito  de cada entorno  del cam dado
    # está contenido  dentro del array de envs_in_cam,  donde  igualaré por la
    # clave.

#    # Si T(EST) /por ejemplo/ está contenido en el array...
#    if ( ( substr $entorno, 0, 1 ) ~~ @{ $envs_in_cam{$key} } ) {
#
#        # Entonces imprimo todo
#    }
#    else {
#
#        # Infraestructura j2EE sin crear
#    }

    $c->stash->{hash}        = \%hash;
    $c->stash->{envs_in_cam} = \%envs_in_cam;
    $c->stash->{template}    = 'mason.html';
    $c->forward('View::Mason');

    return;
}

sub pprueba : Local {
    my ( $self, $c ) = @_;

    # Inicializo  aquí el  hash para hacer  pruebas porque  la query  tarda lo
    # suyo...
    my %hash = (
        'EDW' => [ 'edw_www', 'edwmain' ],
        'AUR' => ['aurmain'],
        'SIX' => [ 'six_www', 'sixmain' ],
        'CAL' => [ 'cal_dos', 'calmain' ],
        'SCT' => [ 'sct_coa', 'sct_edw', 'sct_cta', 'sctj2ee', 'sct_ias' ],
        'HNS' => ['hnsmain'],
        'AAP' => ['aapmain'],
        'CDI' => ['cdi_vpn'],
        'AAD' => ['aadmain'],
    );

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my @cam_env = $har_db->db->array_hash( "
                        SELECT DISTINCT cam, 
                                        env 
                        FROM   inf_status_hist 
                        WHERE  column_name LIKE '%_WAS_SERVER' 
                            AND status = 'SUCCESS' 
                        ORDER  BY 1  
                        " );

    my %envs_in_cam = ();

    for my $href (@cam_env) {
        push @{ $envs_in_cam{ $href->{cam} } }, $href->{env};
    }

    $c->stash->{hash}        = \%hash;
    $c->stash->{envs_in_cam} = \%envs_in_cam;
    $c->stash->{template}    = 'mason.html';
    $c->forward('View::Mason');

    return;
}

sub ppprueba : Local {
    use Data::Dumper;

    my $sql = qq{
        SELECT DISTINCT Substr(environmentname, 1, 3) cam, 
                        idmv.mv_valor
        FROM   harenvironment he, 
            inf_data_inf idt,
            inf_data_mv_f2 idmv
        WHERE  he.envisactive = 'Y' 
            AND Substr(environmentname, 1, 3) IN (SELECT DISTINCT idt4.cam 
                                                    FROM   inf_data_inf idt4 
                                                    WHERE  column_name = 'TEC_JAVA' 
                                                            AND valor = 'Si' 
                                                            AND idt4.idform = (SELECT MAX(ifi.idform) 
                                                                            FROM   inf_form_inf ifi 
                                                                            WHERE  Substr(he.environmentname, 1, 3) = ifi.cam)) 
            AND idt.idform = (SELECT MAX(ifi.idform) 
                                FROM   inf_form_inf ifi 
                                WHERE  Substr(he.environmentname, 1, 3) = ifi.cam) 
            AND idt.column_name = 'JAVA_APPL'
            AND Substr(environmentname, 1, 3) = idt.cam
            AND idt.valor = '@#' || idmv.id
            AND idt.idform = idmv.idform
        ORDER BY 1
        };

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $inf_db = BaselinerX::Ktecho::INF::DB->new;

    my @cam = $har_db->db->array_hash($sql) or croak("No puedo con la query.\n");

    my @cam_env = $inf_db->db->array_hash( "
        SELECT ist.cam, 
            ist.env 
        FROM   inf_status_ ist, 
            inf_peticion_tarea_ ipt 
        WHERE  ipt.idpeticion = ist.idpeticion 
            AND ipt.taskname = ist.correlation 
            AND ipt.status = 'SUCCESS' 
            AND ist.column_name = 'WAS_SERVER'
            AND ist.newvalue IS NOT NULL
        ORDER  BY 1  
        " );

    # Abro fichero
    my $filename = 'C:\1442.txt';
    open my $FILE, '>', $filename or croak("No puedo abrir el fichero $filename.\n");

    # Inicializo el hash que contiene los entornos de cada camp
    my %hash_env = ();

    for my $href (@cam_env) {

        # no hace falta condición,  si existe hace  un push y si no crea key y
        # value
        if ( $href->{env} ~~ @{ $hash_env{ $href->{cam} } } ) {

            #do nothing
        }
        else {
            push @{ $hash_env{ $href->{cam} } }, $href->{env};
        }
    }

    # Inicializo el hash que imprimiré en el fichero...
    my %hash = ();

    for my $href (@cam) {

        # no hace falta condición,  si existe hace  un push y si no crea key y
        # value
        push @{ $hash{ $href->{cam} }{sub_apl} }, $href->{mv_valor};
        push @{ $hash{ $href->{cam} }{entorno} }, @{ $hash_env{$href} };
    }

    print $FILE Dumper \%hash;
}

sub prueba4 : Local {
    my ( $self, $c ) = @_;

    use Data::Dumper;

    my @cam = (
        {   'cam'      => 'AAD',
            'mv_valor' => 'aadmain'
        },
        {   'cam'      => 'AAP',
            'mv_valor' => 'aapmain'
        },
        {   'cam'      => 'CAL',
            'mv_valor' => 'cal_dos'
        },
        {   'cam'      => 'CAL',
            'mv_valor' => 'calmain'
        },
        {   'cam'      => 'CDI',
            'mv_valor' => 'cdi_vpn'
        },
        {   'cam'      => 'EDW',
            'mv_valor' => 'edw_www'
        },
        {   'cam'      => 'EDW',
            'mv_valor' => 'edwmain'
        },
        {   'cam'      => 'SCM',
            'mv_valor' => 'scm_inf'
        },
        {   'cam'      => 'SCM',
            'mv_valor' => 'scm_harweb'
        },
        {   'cam'      => 'SCM',
            'mv_valor' => 'hardist'
        },
        {   'cam'      => 'SCT',
            'mv_valor' => 'sct_coa'
        },
        {   'cam'      => 'SCT',
            'mv_valor' => 'sct_edw'
        },
        {   'cam'      => 'SCT',
            'mv_valor' => 'sct_cta'
        },
        {   'cam'      => 'SCT',
            'mv_valor' => 'sctj2ee'
        },
        {   'cam'      => 'SCT',
            'mv_valor' => 'sct_ias'
        },
        {   'cam'      => 'SIX',
            'mv_valor' => 'six_www'
        },
        {   'cam'      => 'SIX',
            'mv_valor' => 'sixmain'
        },
        {   'cam'      => 'ZZZ',
            'mv_valor' => 'zzzclus'
        },
        {   'cam'      => 'ZZZ',
            'mv_valor' => 'zzz_bat'
        },
        {   'cam'      => 'ZZZ',
            'mv_valor' => 'zzz_was'
        },
        {   'cam'      => 'ZZZ',
            'mv_valor' => 'zzzstre'
        },
        {   'cam'      => 'ZZZ',
            'mv_valor' => 'zzz'
        },
        {   'cam'      => 'ZZZ',
            'mv_valor' => 'zzz_b_t'
        }
    );

    my @cam_env = (
        {   'env' => 'T',
            'cam' => 'AAD'
        },
        {   'env' => 'T',
            'cam' => 'AAP'
        },
        {   'env' => 'T',
            'cam' => 'ABC'
        },
        {   'env' => 'T',
            'cam' => 'ARA'
        },
        {   'env' => 'T',
            'cam' => 'CAL'
        },
        {   'env' => 'A',
            'cam' => 'CDI'
        },
        {   'env' => 'T',
            'cam' => 'CDI'
        },
        {   'env' => 'T',
            'cam' => 'DK3'
        },
        {   'env' => 'T',
            'cam' => 'EDW'
        },
        {   'env' => 'T',
            'cam' => 'EDW'
        },
        {   'env' => 'T',
            'cam' => 'EFR'
        },
        {   'env' => 'T',
            'cam' => 'E9R'
        },
        {   'env' => 'T',
            'cam' => 'JSX'
        },
        {   'env' => 'T',
            'cam' => 'KH7'
        },
        {   'env' => 'T',
            'cam' => 'KH8'
        },
        {   'env' => 'T',
            'cam' => 'KH9'
        },
        {   'env' => 'T',
            'cam' => 'KK2'
        },
        {   'env' => 'T',
            'cam' => 'MZ1'
        },
        {   'env' => 'T',
            'cam' => 'M3E'
        },
        {   'env' => 'P',
            'cam' => 'PSR'
        },
        {   'env' => 'T',
            'cam' => 'PSR'
        },
        {   'env' => 'T',
            'cam' => 'PSR'
        },
        {   'env' => 'P',
            'cam' => 'PSR'
        },
        {   'env' => 'A',
            'cam' => 'PSR'
        },
        {   'env' => 'A',
            'cam' => 'PSR'
        },
        {   'env' => 'P',
            'cam' => 'PSR'
        },
        {   'env' => 'T',
            'cam' => 'R5W'
        },
        {   'env' => 'P',
            'cam' => 'SCM'
        },
        {   'env' => 'T',
            'cam' => 'SCM'
        },
        {   'env' => 'A',
            'cam' => 'SCM'
        },
        {   'env' => 'T',
            'cam' => 'SCT'
        },
        {   'env' => 'A',
            'cam' => 'SCT'
        },
        {   'env' => 'A',
            'cam' => 'SIX'
        },
        {   'env' => 'A',
            'cam' => 'SIX'
        },
        {   'env' => 'T',
            'cam' => 'SIX'
        },
        {   'env' => 'T',
            'cam' => 'SIX'
        },
        {   'env' => 'P',
            'cam' => 'SIX'
        },
        {   'env' => 'P',
            'cam' => 'SIX'
        },
        {   'env' => 'P',
            'cam' => 'SIX'
        },
        {   'env' => 'T',
            'cam' => 'S1T'
        },
        {   'env' => 'T',
            'cam' => 'S26'
        },
        {   'env' => 'T',
            'cam' => 'XYX'
        },
        {   'env' => 'T',
            'cam' => 'ZOP'
        },
        {   'env' => 'A',
            'cam' => 'ZZZ'
        },
        {   'env' => 'T',
            'cam' => 'ZZZ'
        },
        {   'env' => 'T',
            'cam' => '4ER'
        },
        {   'env' => 'T',
            'cam' => '4ER'
        },
        {   'env' => 'T',
            'cam' => '5ER'
        },
        {   'env' => 'T',
            'cam' => '5ER'
        }
    );

    # Abro fichero
#    my $filename = 'C:\prueba4-2.txt';
#    open my $FILE, '>', $filename or croak("No puedo abrir el fichero $filename.\n");

    # Inicializo el hash que imprimiré en el fichero...
    my %hash = ();

    for my $href (@cam) {

        # no hace falta condición,  si existe hace  un push y si no crea key y
        # value
        push @{ $hash{ $href->{cam} }{sub_apl} }, $href->{mv_valor};

        for my $href2 (@cam_env) {
            if ( $href->{cam} eq $href2->{cam} ) {
                if ( $href2->{env} ~~ @{ $hash{ $href->{cam} }{entorno} } ) {

                    #do nothing
                }
                else {
                    push @{ $hash{ $href->{cam} }{entorno} }, $href2->{env};
                }
            }
        }
    }

    $c->stash->{hash}        = \%hash;
    $c->stash->{template}    = 'mason.html';
    $c->forward('View::Mason');
}

1;

