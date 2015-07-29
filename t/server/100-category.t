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

#reload de entire system to create a topic for the new category

done_testing;
