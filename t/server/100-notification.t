use v5.10;
use lib 'lib';
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;
use Time::Piece;

BEGIN {
    plan skip_all => 'set TEST_LIVE to run this test' unless $ENV{TEST_LIVE};
}

my $ag = Clarive::Test->user_agent;

my $url;
my %data;
my $json;

#########################
#   NOTIFICACIONES      #
#########################




# 1) crear notificacion -> OK
# 2) crear evento de login failed (event.auth.failed) -> OK
# 3) ejecutar el servicio de eventos (/service/rest) -> OK
# http://localhost:3000/service/rest?service=service.event.run_once
# 4) consultar buzon del root donde tiene que estar el correo -> OK

#take mid of user root
$url = '/ci/gridtree';
%data = ('ci_form' => '/ci/user.js', '_is_leaf' => 'false',  'class' => 'BaselinerX::CI::user', 'classname' => 'BaselinerX::CI::user', 'click' => '[object Object]', 
		 'collection' => 'user', 'has_bl' => '0', 'has_collection' => '0', 'icon' => '/static/images/icons/user.gif', 'item' => 'user', 'limit' => '30', 'pretty' => 'true',
		 'query' => 'root', 'start' => '0', 'tab_icon' => '/static/images/icons/user.gif', 'ts' => '-', 'type' => 'class');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
my $root_id = $json->{data}[0]->{_id};


#create notification
$url = '/notification/save_notification';
my $now = localtime->strftime('%Y/%d/%m - %H:%M:%S');
my $test_subject = "Test de notificacion: $now";
%data = ('action' => 'SEND',  'event' => 'event.auth.failed', 'notification_id' => '-1',  'recipients' => '{"TO":{"Users":{"$root_id":"root"}}}', 
		 'subject' => "$test_subject", 'template' => '/email/test.html');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
my $id = $json->{notification_id};
ok $json->{success}, 'notification created succesfully';



#update notification
$url = '/notification/save_notification';
$now = localtime->strftime('%Y/%d/%m - %H:%M:%S');
$test_subject = "Test de notificacion: $now";
%data = ('action' => 'SEND',  'event' => 'event.auth.failed', 'notification_id' => $id,  'recipients' => '{"TO":{"Users":{"$root_id":"root"}}}', 
		 'subject' => "$test_subject", 'template' => '/email/test.html');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
$id = $json->{notification_id};
ok $json->{success}, 'notification updated succesfully';



#launch login event
$url = '/login';
%data = ('login' => 'local/root', 'password' => 'nono');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};



#launch service event handler
$url = '/service/rest';
%data = ('service' => 'service.event.run_once');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );



#delete notificaction
$url = '/notification/remove_notifications';
%data = ('ids_notification' => $id);

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'notification deleted succesfully';



#check if the notification is in the root's inbox
$url = '/message/inbox_json';
%data = ('limit' => '30', 'start' => '0', 'username' => 'root', 'test' => '1');

$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
ok $json->{data}[0]->{subject} eq $test_subject, "notification received succesfully at root's inbox";


done_testing;
