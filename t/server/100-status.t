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
            type            => 'I'
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

done_testing;
