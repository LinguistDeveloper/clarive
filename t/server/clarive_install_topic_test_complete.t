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
my @cats=[];
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
        type            => 'G'
    },
    _merge_with_params => 1,
    action             => 'add',
    collection         => 'status',
};
$res = $ag->json( URL($url) => $data );
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

done_testing;