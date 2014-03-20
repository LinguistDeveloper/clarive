use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

my @mids;

my $ag = Clarive::Test->user_agent;
#insert a new calendar not a copy

my $url;
my %data;
my $json;
my $id_cal;

#####################
#   MENSAJES        #
#####################

$url = '/message/detail';

my $id;
my $username;

$id = "110";
$username = "rodrigo";

%data = ('id' => $id, 'username' => $username);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'message readed';

my $config = Baseliner->model('ConfigStore')->get('config.comm.email');
my @users_list = ('saul@clarive.com');

my $to = [ _unique(@users_list) ];

Baseliner->model('Messaging')->notify(
to => { users => $to },
sender => $config->{from},
carrier => 'email',
template => 'email/generic.html',
template_engine => 'mason',
vars => {
subject => "Prueba de envio de correo desde Clarive",
message =>
'Has recibido este correo porque estamos ejecutando una prueba de envio desde Clarive'
}
);


say "Result: " . $json->{msg};
ok $json->{success}, 'message readed';

done_testing;
