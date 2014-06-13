use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

my $ag = Clarive::Test->user_agent;

my $url;
my $data;
my $json;
my $res;


my $project_mid1;
my $project_mid2;
my $user_mid;
my $role_id1;
my $role_id2;

#########################
#       roles           #
#########################


{
    $url = 'role/update';
    my $data = {
        role_actions=>_encode_json([
            {
                action=>'User can change his password',
                bl=>'*',
                description=>'action.change_password'
            },
            {
                action=>'Administer baselines',
                bl=>'*',
                description=>'action.admin.baseline'
            },
            {
                action=>'Administer configuration variables',
                bl=>'*',
                description=>'action.admin.config_list'
            },
            {
                action=>'Admin Events',
                bl=>'*',
                description=>'action.admin.event'
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
                action=>'User can change his password',
                bl=>'*',
                description=>'action.change_password'
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
        roles_checked=>             [$role_id1,$role_id2],
        type=>                      'roles_projects',
        username=>                  'test_user'
    };
    $url = 'user/update';
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'user updated succesfully';

}



#########################
#		entorno			#
#########################

$url = 'ci/update';
$data = {
    as_json   => 1,
    form_data => {
        name           	=> 'Entorno de pruebas',
        description    	=> 'Entorno de pruebas',
        bl             	=> '*',
        moniker        	=> '',
        active         	=> 'on',
        children       	=> '',
        seq 			=> '100'
    },
    _merge_with_params => 1,
    action             => 'add',
    collection         => 'bl',
};
$res = $ag->json( URL($url) => $data );
my $bl = $res->{mid};
is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
     

#########################
#		status			#
#########################

$url = 'ci/update';
my @cats;
#nuevo
$data = {
    as_json   => 1,
    form_data => {
        name            => 'nuevo',
        description     => 'Estado nuevo',
        bls             => [$bl],
        moniker         => '',
        active          => 'on',
        children        => '',
        seq             => '100',
        type            => 'I'
    },
    _merge_with_params => 1,
    action             => 'add',
    collection         => 'status',
};
$res = $ag->json( URL($url) => $data );
my $new_status = $res->{mid};
push @cats, $res->{mid};
is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );


#progreso
$data = {
    as_json   => 1,
    form_data => {
        name            => 'progreso',
        description     => 'Estado progreso',
        bls             => [$bl],
        moniker         => '',
        active          => 'on',
        children        => '',
        seq             => '100',
        type            => 'G'
    },
    _merge_with_params => 1,
    action             => 'add',
    collection         => 'status',
};
$res = $ag->json( URL($url) => $data );
my $progress_status = $res->{mid};
push @cats, $res->{mid};
is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
     

#finalizado
$data = {
    as_json   => 1,
    form_data => {
        name            => 'finalizado',
        description     => 'Estado finalizado',
        bls             => [$bl],
        moniker         => '',
        active          => 'on',
        children        => '',
        seq             => '100',
        type            => 'G'
    },
    _merge_with_params => 1,
    action             => 'add',
    collection         => 'status',
};
$res = $ag->json( URL($url) => $data );
my $finish_status = $res->{mid};
push @cats, $res->{mid};
is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
     

#############################
#		categoria			#
#############################

$url = 'topicadmin/update_category';
$data = {
    as_json         => 1,
    type            => 'N',
    provider        => 'internal',
    action          => 'add',
    name            => 'catTest',
    category_color  => '#808000',
    id              => '-1',
    description     => 'Categoria de prueba',
    _merge_with_params => 1,
    idsstatus       => \@cats
};

$res = $ag->json( URL($url) => $data );
is( ${ $res->{success} }, 1,  "$res->{msg}: category created succesfully" );     
my $cat = $res->{category_id};
#add fields to a category

$url = 'topicadmin/update_fields';

$res = $ag->post( URL($url) => [ fields =>'title', fields =>'moniker', fields=>'description', id_category=>$cat,
                                 params=>'{"bd_field":"title","origin":"system","name_field":"Title","section":"head","font_weigth":"bold","system_force":true,"allowBlank":false,"html":"/fields/system/html/field_title.html","js":"/fields/templates/js/textfield.js","field_order":-1,"field_order_html":1}', 
                                 params=>'{"bd_field":"moniker","origin":"system","name_field":"Moniker","section":"body","html":"/fields/templates/html/row_body.html","allowBlank":true,"js":"/fields/templates/js/textfield.js","field_order":-8}', 
                                 params=>'{"bd_field":"description","origin":"system","name_field":"Description","section":"head","html":"/fields/templates/html/dbl_row_body.html","js":"/fields/templates/js/html_editor.js","field_order":-7,"field_order_html":2}' ] );

$json = _decode_json( $ag->content );
ok $json->{success}, 'fields added to category succesfully';

#asignar dos workflows a la categoria, hay que obtener los id de rol de alguna manera

$url = 'topicadmin/update_category_admin';
$data = {
    action          => '',
    idsroles        => $role_id1,
    idsstatus_to    => $progress_status,
    id              => $cat,
    status_from     => $new_status,
    job_type        => '' 
};

$ag->post( URL($url), $data);
$json = _decode_json( $ag->content );
ok $json->{success}, 'workflow added succesfully';

$data = {
    action          => '',
    idsroles        => $role_id2,
    idsstatus_to    => $finish_status,
    id              => $cat,
    status_from     => $progress_status,
    job_type        => '' 
};

$ag->post( URL($url), $data);
$json = _decode_json( $ag->content );
ok $json->{success}, 'workflow added succesfully';

#####################
#       topico      #
#####################

#crear un topico

$url = 'topic/update';
$data = {
    as_json         => 1,
    type            => 'N',
    moniker         => '',
    progress        => '',
    form            => '',
    action          => 'add',
    title            => 'testTopic',
    topic_mid       => '-1',
    description     => 'Esto es un tópico de prueba',
    _merge_with_params => 1,
    category        => $cat,
    txtcategory_old => '',
    _cis            => '[]',
    status_new      => $new_status,
    status          => '',
    form            => ''
};

$ag->post( URL($url), $data);
$json = _decode_json( $ag->content );
ok $json->{success}, 'topic created succesfully';



done_testing;