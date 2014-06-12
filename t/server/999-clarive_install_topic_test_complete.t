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


#crear un topico

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