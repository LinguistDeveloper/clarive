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
#		status			#
#########################

$url = 'ci/update';
%data = ('action' => 'add', 'collection' => 'bl', 
		 'form_data' => ('children' => '', 'name' => 'Entorno de pruebas', 'description' => 'Entorno de pruebas', 'active' => 'on', 'moniker' => '', 'bl' => '*', 'seq' => '100'));

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, "Entorno anyadido";

done_testing;