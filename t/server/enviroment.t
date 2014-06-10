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

$url = 'ci/update';
my %form_data = ('children' => '', 'name' => 'Entorno de pruebas', 'description' => 'Entorno de pruebas', 'active' => 'on', 'moniker' => '', 'bl' => '*', 'seq' => '100');
%data = ('action' => 'add', 'collection' => 'bl', 'form_data' => \%form_data);

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, "Entorno anyadido";

done_testing;