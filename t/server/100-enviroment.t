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

done_testing;
