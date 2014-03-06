use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

my @mids;

#IMPORT

my $ag = Clarive::Test->user_agent;
#insert a generic_server

my $gs = q{agent_timeout;bl;connect_balix;connect_ssh;connect_timeout;connect_worker;description;hostname;moniker;name;ns;os;remote_perl;remote_tar;remote_temp
0;*;1;1;30;1;"servidor de prueba de test";test_server;;test_server;;unix;perl;tar;};
my %data_imp_gs = ('_bali_login_count' => 0, '_bali_notify_valid_session' => 'true', 'ci_type' => 'generic_server', 'format' => 'csv', 'text' => $gs);
$ag->post( URL('/ci/import'), \%data_imp_gs );
my $json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Generic Server inserted';


#insert a balix agent
my $bl = q{bl;chunk_size;copy_attrs;description;key;mkpath_on;moniker;mvs;name;ns;os;output;overwrite_on;password;port;rc;ret;server;throw_errors;timeout;user;wait_frequency
*;;0;"test de Balix agent";1234;1;;0;test_balix;;unix;;1;;9999;0;;test_server;;0;1234;5};
my %data_imp_ba = ('_bali_login_count' => 0, '_bali_notify_valid_session' => 'true', 'ci_type' => 'balix_agent', 'format' => 'csv', 'text' => $bl);
$ag->post( URL('/ci/import'), \%data_imp_ba );
my $json2 = _decode_json( $ag->content );
say "Result: " . $json2->{msg};
ok $json2->{success}, 'Balix agent inserted';


#update a generic_server
my $gs2 = q{agent_timeout;bl;connect_balix;connect_ssh;connect_timeout;connect_worker;description;hostname;moniker;name;ns;remote_perl;remote_tar;remote_temp
0;*;1;1;30;1;"servidor de prueba de test updated";test_server;;test_server;;unix;perl;tar;};
my %data_imp_gs2 = ('_bali_login_count' => 0, '_bali_notify_valid_session' => 'true', 'ci_type' => 'generic_server', 'format' => 'csv', 'text' => $gs2);
$ag->post( URL('/ci/import'), \%data_imp_gs2 );
my $json3 = _decode_json( $ag->content );
say "Result: " . $json3->{msg};
ok $json3->{success}, 'Generic Server updated';


#update a balix agent
my $ba2 = qq{bl;chunk_size;copy_attrs;description;key;mid;mkpath_on;moniker;mvs;name;ns;os;output;overwrite_on;password;port;rc;ret;server;throw_errors;timeout;user;wait_frequency
*;;0;"test de Balix agent ACTUALIZADO";1234;$json2->{mids}[0];1;;0;test_balix;;unix;;1;;9999;0;;test_server;;0;1234;5};
my %data_imp_ba2 = ('_bali_login_count' => 0, '_bali_notify_valid_session' => 'true', 'ci_type' => 'balix_agent', 'format' => 'csv', 'text' => $ba2);
$ag->post( URL('/ci/import'), \%data_imp_ba2 );
my $json4 = _decode_json( $ag->content );
say "Result: " . $json4->{msg};
ok $json4->{success}, 'Balix agent updated';
push @mids, $json4->{mids}[0];


#EXPORT de un process instance creado anteriormente
my $ag = Clarive::Test->user_agent;
my %data_exp_pi = ('_bali_login_count' => 0, '_bali_notify_valid_session' => 'true', 'ci_type' => 'balix_agent', 'format' => 'csv', 'mids' => join ',',@mids);
$ag->post( URL('/ci/export'), \%data_exp_pi );
my $json5 = _decode_json( $ag->content );
say "Result: " . $json5->{msg}.", Data: ".$json5->{data} ;
ok $json5->{success}, 'Balix agent exported';

done_testing;
