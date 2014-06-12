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
#   DASHBOARDS      #
#####################

#crear un dashboard
$url = '/dashboard/update';
%data = ('action' => 'add', 'dashlets' => '/dashlets/emails.html#/dashboard/list_emails, /dashlets/topics.html#/dashboard/list_topics', 
		 'description' => 'test', 'id' => '-1', 'name' => 'test', 'roles' => '61, 2', 'type' => 'T');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'dashboard created succesfully';
my $id = $json->{dashboard_id};


#actualizar un dashboard
$url = '/dashboard/update';
%data = ('action' => 'update', 'dashlets' => '/dashlets/emails.html#/dashboard/list_emails', 
		 'description' => 'test actualizado', 'id' => $id, 'name' => 'test actualizado', 'roles' => '61, 2', 'type' => 'T');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'dashboard updated succesfully';


#borrar un dashboard
$url = '/dashboard/update';
%data = ('action' => 'delete', 'id' => $id);

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'dashboard deleted succesfully';

done_testing;