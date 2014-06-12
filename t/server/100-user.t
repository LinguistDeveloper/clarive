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

#####################
#		USER	    #
#####################

$url = 'user/update';
%data = ('action' => 'add', 'type' => 'user', 'id' => '-1', 'username' => 'utest', 'pass' => 'utest', 'alias' => 'utest', 'pass_cfrm' => 'utest',
		'realname' => 'usuario de prueba', 'language' => 'spanish', 'phone' => '661000000', 'email' => 'usuario@test.es');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, "user added succesfully with mid: $json->{user_id}";


done_testing;