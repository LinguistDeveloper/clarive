use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

BEGIN {
    plan skip_all => 'set TEST_LIVE to run this test' unless $ENV{TEST_LIVE};
}

my $ag = Clarive::Test->user_agent;

my $url;
my %data;
my $json;

my $project_mid1;
my $project_mid2;
my $user_mid;
my $role_id1;
my $role_id2;
my $role_dev;

#########################
#       roles           #
#########################


{
    $url = 'role/update';
    my $data = {
        role_actions=>_encode_json([
            {
                action=>'action.change_password',
                bl=>'*'
            },
            {
                action=>'action.admin.baseline',
                bl=>'*'
            },
            {
                action=>'action.admin.config_list',
                bl=>'*'
            },
            {
                action=>'action.admin.event',
                bl=>'*'
            }]),
        mailbox=>'rol1@clarive.com',
        id=>-1,
        description=>'mi rol 1',
        name=>'rol_prueba1',
    };
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    $role_id1 = $json->{id};
    ok $json->{success}, 'Role created';
}


{
    $url = 'role/update';
    my $data = {
        role_actions=>_encode_json([
            {
                action=>'action.change_password',
                bl=>'*'
            }]),
        mailbox=>'',
        id=>-1,
        description=>'mi rol 2',
        name=>'rol_prueba2',
    };
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    $role_id2 = $json->{id};
    ok $json->{success}, 'Role created';
}

{
    $url = 'role/update';
    my $data = {
        role_actions => _encode_json([
            {
                    action => 'action.git.repository_access',
                    bl => '*'
            },
            {
                    action => 'action.home.show_lifecycle',
                    bl => '*'
            },
            {
                    action => 'action.home.show_menu',
                    bl => '*'
            },
            {
                    action => 'action.job.viewall',
                    bl => '*'
            },
            {
                    action => 'action.project.see_lc',
                    bl => '*'
            },
            {
                    action => 'action.search.topic',
                    bl => '*'
            },
            {
                    action => 'action.topics.cambio.create',
                    bl => '*'
            },
            {
                    action => 'action.topics.cambio.edit',
                    bl => '*'
            },
            {
                    action => 'action.topics.cambio.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.cambio_de_alcance.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.defecto.create',
                    bl => '*'
            },
            {
                    action => 'action.topics.defecto.edit',
                    bl => '*'
            },
            {
                    action => 'action.topics.defecto.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.entrega_independiente.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.fast_track.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.peticion.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.problema.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.proyecto_especial.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.release.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.validacion_de_desarrollo.view',
                    bl => '*'
            },
            {
                    action => 'action.topics.validacion_de_modelo_de_datos.view',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.cambio_de_alcance.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.cambio_modelo_de_datos.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.cambio_modelo_de_datos.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.descripcion.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.descripcion.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.descripcion.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.description.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.description.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.description.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.documentacion.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.documentacion.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.documentacion.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.ficheros_sql.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.incidencias.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.incidencias.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.incidencias.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.incidencias_arregladas.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.peticion.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.peticion_problema.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.problemas.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.problemas.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.problemas.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.pruebas_a_realizar.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.pruebas_a_realizar.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.pruebas_a_realizar.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.pruebas_de_rendimiento.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.pruebas_de_rendimiento.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.revisiones.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.sistema.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.error_migracion_it.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.error_migracion_pre.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.error_migracion_prod.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.fin_desarrollo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.status.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.title.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio.version.analisis.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.coste_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.coste_de_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.coste_desarrollo.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.coste_especificacion.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.coste_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.coste_total.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.costes.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.esfuerzo_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.esfuerzo_especificacion.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.esfuerzo_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.estimaciones.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.estimaciones_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.otros_costes.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.tarifa_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.tarifa_especificacion.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.cambio_de_alcance.tarifa_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.description.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.impacto.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.origen.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.prioridad.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.sistema_afectado.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.status.abierto.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.status.mas_informacion.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.status.rechazado.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.tipo.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.title.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.defecto.version.nuevo.write',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.estimacion_de_impacto.coste_jornadas.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.coste_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.coste_de_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.coste_desarrollo.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.coste_especificacion.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.coste_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.coste_total.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.costes.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.esfuerzo_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.esfuerzo_especificacion.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.esfuerzo_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.estimaciones.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.estimaciones_it.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.otros_costes.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.tarifa_cfm.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.tarifa_especificacion.read',
                    bl => '*'
            },
            {
                    action => 'action.topicsfield.peticion.tarifa_it.read',
                    bl => '*'
            }]),
        mailbox=>'desarrollador@clarive.com',
        id=>-1,
        description=>'Desarrollador',
        name=>'Desarrollador',
    };
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    $role_dev = $json->{id};
    ok $json->{success}, 'Role created';
}


#########################
#       projects        #
#########################

{

    my $data = {
        as_json   => 1,
        form_data => {
            name           => 'test_project',
            description    => 'Proyecto de pruebas',
            bl             => '*',
            moniker        => '',
            active         => 'on',
            children       => '',
            seq            => '100'
        },
        _merge_with_params => 1,
        action             => 'add',
        collection         => 'project',
    };
    my $res = $ag->json( URL('ci/update') => $data );
    $project_mid1 = $res->{mid};
    is( ${ $res->{success} }, 1,  "$res->{msg}: project created succesfully" );
     
}

{

    my $data = {
        as_json   => 1,
        form_data => {
            name           => 'test_project2',
            description    => 'Proyecto de pruebas2',
            bl             => '*',
            moniker        => '',
            active         => 'on',
            children       => '',
            seq => '101'
        },
        _merge_with_params => 1,
        action             => 'add',
        collection         => 'project',
    };
    my $res = $ag->json( URL('ci/update') => $data );
    $project_mid2 = $res->{mid};
    is( ${ $res->{success} }, 1,  "$res->{msg}: project created succesfully" );
     
}

#########################
#       users           #
#########################

{
    my $data = {
        action=>    'add',
        alias=>     'test_user',
        email=>     'test_user@test_user.com',
        id=>        '-1',
        language=>  'spanish',
        pass=>      'test_user',
        pass_cfrm=> 'test_user',
        phone=>     '33334444',
        realname=>  'test_user',
        type=>      'user',
        username=>  'test_user'
    };
    $url = 'user/update';
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'user created succesfully';

    $data = {
        action=>                    'update',
        alias=>                     'test_user',
        email=>                     'test_user@test_user.com',
        id=>                        $user_mid,
        language=>                  'spanish',
        pass=>                      'test_user',
        pass_cfrm=>                 'test_user',
        phone=>                     '33334444',
        projects_checked=>          [$project_mid1,$project_mid2],
        projects_parents_checked=>  '',  
        realname=>                  'test_user',
        roles_checked=>             [$role_id1,$role_id2,$role_dev],
        type=>                      'roles_projects',
        username=>                  'test_user'
    };
    $url = 'user/update';
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'user updated succesfully';

}

done_testing;
