use v5.10;
use lib 'lib';
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
#		DAEMONS	    #
#####################

#create a daemon
$url = '/daemon/update';
%data = ('action' => 'add', 'hostname' => 'localhost', 'id' => '-1', 'service' => 'service.config', 'state' => '1');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'daemon created succesfully';
my $id = $json->{daemon_id};


#update previous daemon
$url = '/daemon/update';
%data = ('action' => 'update', 'hostname' => 'localhost', 'id' => $id, 'state' => '0');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'daemon updated succesfully';


#delete daemon
$url = '/daemon/update';
%data = ('action' => 'delete', 'id' => $id);

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'daemon deleted succesfully';

done_testing;
