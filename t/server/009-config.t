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

#####################
#   	CONFIG		#
#####################

#updating a value stored in the registry and storing it in the db

$url = 'configlist/update';
%data = ('bl' => '*', 'config_default' => '10', 'key' => 'config.comm.email.max_attempts', 'ns' => '/', 'value' => '15');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'config updated succesfully';


#creating a value storing it in the db

$url = 'configlist/update';
%data = ('bl' => '*', 'config_default' => '*', 'key' => 'config.test.ok.1', 'ns' => '/', 'value' => 'configuracion de test 2');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'config updated succesfully';
my $id1 = $json->{_id};

#creating a value storing it in the db

$url = 'configlist/update';
%data = ('bl' => '121', 'config_default' => '*', 'key' => 'config.test.ok.2', 'ns' => '/', 'value' => 'configuracion de test 2');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'config updated succesfully';
my $id2 = $json->{_id};



# #custom searchs

# my $config1 = Baseliner->model('ConfigStore')->get('config.test', bl => '*');
# ok $config1->{1} eq 'configuracion de test 1', 'search 1 ok';


# my $config2 = Baseliner->model('ConfigStore')->get('config.test', bl => '121');
# ok $config2->{2} eq 'configuracion de test 2', 'search 2 ok';


#removing previous config1

$url = 'configlist/delete';
%data = ('id' => $id1, 'key' => 'config.test.ok.1');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'config deleted succesfully';

#removing previous config2

$url = 'configlist/delete';
%data = ('id' => $id2, 'key' => 'config.test.ok.2');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'config deleted succesfully';


done_testing;
