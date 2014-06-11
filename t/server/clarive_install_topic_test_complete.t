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
my %data;
my $json;

#########################
#		entorno			#
#########################

{
    my $data = {
        as_json   => 1,
        form_data => {
            name           => 'Entorno de pruebas',
            description    => 'Entorno de pruebas',
            bl             => '*',
            moniker        => '',
            active         => 'on',
            children       => '',
            seq => '100'
        },
        _merge_with_params => 1,
        action             => 'add',
        collection         => 'bl',
    };
    my $res = $ag->json( URL('ci/update') => $data );
    is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
    # if( my $mid = $res->{mid} ) {
    #     $res =  $ag->json( URL('ci/delete') => { mids=>$mid } );
    #     is( ${ $res->{success} }, 1,  'ci delete ok' );
    # }
     
}

#########################
#		status			#
#########################

#nuevo
{
    my $data = {
        as_json   => 1,
        form_data => {
            name            => 'nuevo',
            description     => 'Estado nuevo',
            bls             => ['14'],
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
    my $res = $ag->json( URL('ci/update') => $data );
    is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
    # if( my $mid = $res->{mid} ) {
    #     $res =  $ag->json( URL('ci/delete') => { mids=>$mid } );
    #     is( ${ $res->{success} }, 1,  'ci delete ok' );
    # }
     
}

#progreso
{
    my $data = {
        as_json   => 1,
        form_data => {
            name            => 'progreso',
            description     => 'Estado progreso',
            bls             => ['14'],
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
    my $res = $ag->json( URL('ci/update') => $data );
    is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
    # if( my $mid = $res->{mid} ) {
    #     $res =  $ag->json( URL('ci/delete') => { mids=>$mid } );
    #     is( ${ $res->{success} }, 1,  'ci delete ok' );
    # }
     
}

#finalizado
{
    my $data = {
        as_json   => 1,
        form_data => {
            name            => 'finalizado',
            description     => 'Estado finalizado',
            bls             => ['14'],
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
    my $res = $ag->json( URL('ci/update') => $data );
    is( ${ $res->{success} }, 1,  "$res->{msg}: enviroment created succesfully" );
    # if( my $mid = $res->{mid} ) {
    #     $res =  $ag->json( URL('ci/delete') => { mids=>$mid } );
    #     is( ${ $res->{success} }, 1,  'ci delete ok' );
    # }
     
}

#############################
#		categoria			#
#############################

{
    
    my $data = {
        as_json         => 1,
        type            => 'N',
        provider        => 'internal',
        action          => 'add',
        name            => 'catTest',
        category_color  => '#808000',
        id              => '-1',
        description     => 'Categoria de prueba',
        _merge_with_params => 1,
        idsstatus       => ['16', '17', '18']
    };

    my $res = $ag->json( URL('topicadmin/update_category') => $data );
    is( ${ $res->{success} }, 1,  "$res->{msg}: category created succesfully" );     
}

done_testing;