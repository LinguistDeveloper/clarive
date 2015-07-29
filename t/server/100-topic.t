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
my $data;
my $json;
my $res;


#crear un topico   NO ES DINÁMICO

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
    category        => '38',
    txtcategory_old => '',
    _cis            => '[]',
    status_new      => '148',
    status          => '',
    form            => ''
};

$ag->post( URL($url), $data);
$json = _decode_json( $ag->content );
ok $json->{success}, 'topic created succesfully';

done_testing;
