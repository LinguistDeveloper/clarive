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

my @mids;

my $ag = Clarive::Test->user_agent;
#insert a new calendar not a copy

my $url;
my %data;
my $json;
my $id_cal;

#####################
#	CALENDARIOS		#
#####################

$url = '/job/calendar_update';

my $action;
my $bl;
my $description;
my $name;
my $ns;
my $rbMode;
my $seq;

#1 crear un calendario
$action = 'create';
$bl = '*';
$description = q{un Calendario de prueba};
$name = q{unCalendario};
$ns = "/";
$rbMode = 1;
$seq = 100;

%data = ('action' => $action, 'bl' => $bl, 'description' => $description, 'name' => $name, 'ns' => $ns, 'rbMode' => $rbMode, 'seq' => $seq);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar created';
$id_cal = $json->{id_cal};


#2 borrar el calendario creado anteriormente
$action = 'delete';

%data = ('action' => $action, 'id_cal' => $id_cal);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar deleted';


#3 crear un calendario de nuevo
$action = 'create';
$bl = '*';
$description = q{Segundo Calendario de Prueba};
$name = q{segundoCalendario};
$ns = "/";
$rbMode = 1;
$seq = 100;

%data = ('action' => $action, 'bl' => $bl, 'description' => $description, 'name' => $name, 'ns' => $ns, 'rbMode' => $rbMode, 'seq' => $seq);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar created';
$id_cal = $json->{id_cal};


#4 actualizar el anterior calendario
$action = 'update';
$bl = '*';
$description = q{Segundo Calendario de Prueba actualizado};
$name = q{segundoCalendarioUpdate};
$ns = "/";
$rbMode = 1;
$seq = 100;

%data = ('action' => $action, 'bl' => $bl, 'description' => $description, 'name' => $name, 'ns' => $ns, 'rbMode' => $rbMode, 'seq' => $seq, 'id_cal' => $id_cal);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar updated';
$id_cal = $json->{id_cal};
my $id_a_borrar = $id_cal;


#5 crear nuevo calendario a partir de una copia(el anterior)
$action = 'create';
$bl = '*';
$description = q{Calendario copia de segundo calendario};
$name = q{copia de calendario};
$ns = "2";
$rbMode = 1;
$seq = 100;

%data = ('action' => $action, 'bl' => $bl, 'description' => $description, 'name' => $name, 'ns' => $ns, 'rbMode' => $rbMode, 'seq' => $seq, 'copyof' => $id_cal);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar copy of another one created';
$id_cal = $json->{id_cal};


#6 borrar el primer calendario creado
$action = 'delete';

%data = ('action' => $action, 'id_cal' => $id_a_borrar);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar deleted';


#7 actualizamos el calendario restante
$action = 'update';
$bl = '*';
$description = q{Segundo Calendario de Prueba actualizado};
$name = q{segundoCalendarioUpdate};
$ns = "/";
$rbMode = 1;
$seq = 100;

%data = ('action' => $action, 'bl' => $bl, 'description' => $description, 'name' => $name, 'ns' => $ns, 'rbMode' => $rbMode, 'seq' => $seq, 'id_cal' => $id_cal);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Calendar updated';
$id_cal = $json->{id_cal};


#########################
#	VENTANAS DE PASE	#
#########################

my $cmd;
my $date;
my $id;
my $ven_dia;
my $ven_fin;
my $ven_ini;
my $ven_tipo;

#8 crear una ventana en un calendario
$url = '/job/calendar_submit';
$cmd = 'A';
$date = '03/03/2014';
$id = '';
$ven_dia = '0';
$ven_fin = '24:00';
$ven_ini = '00:00';
$ven_tipo = 'N';

%data = ('cmd' => $cmd, 'date' => $date, 'id' => $id, 'id_cal' => $id_cal, 'ven_dia' => $ven_dia, 'ven_fin' => $ven_fin, 'ven_ini' => $ven_ini, 'ven_tipo' => $ven_tipo);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Window created';


#9 crear una segunda ventana
$cmd = 'A';
$date = '05/03/2014';
$id = '';
$ven_dia = '2';
$ven_fin = '24:00';
$ven_ini = '00:00';
$ven_tipo = 'N';

%data = ('cmd' => $cmd, 'date' => $date, 'id' => $id, 'id_cal' => $id_cal, 'ven_dia' => $ven_dia, 'ven_fin' => $ven_fin, 'ven_ini' => $ven_ini, 'ven_tipo' => $ven_tipo);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Another window created';
my $otro_id = $json->{cal_window};

#10 modificacion de la segunda ventana
$cmd = 'A';
$date = '05/03/2014';
$id = $otro_id;
$ven_dia = '2';
$ven_fin = '24:00';
$ven_ini = '00:00';
$ven_tipo = 'U';

%data = ('cmd' => $cmd, 'date' => $date, 'id' => $id, 'id_cal' => $id_cal, 'ven_dia' => $ven_dia, 'ven_fin' => $ven_fin, 'ven_ini' => $ven_ini, 'ven_tipo' => $ven_tipo);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'update window succesfully';


#11 solapamiento de ventana en ventana 1
$cmd = 'A';
$date = '03/03/2014';
$id = '';
$ven_dia = '0';
$ven_fin = '18:00';
$ven_ini = '10:00';
$ven_tipo = 'U';

%data = ('cmd' => $cmd, 'date' => $date, 'id' => $id, 'id_cal' => $id_cal, 'ven_dia' => $ven_dia, 'ven_fin' => $ven_fin, 'ven_ini' => $ven_ini, 'ven_tipo' => $ven_tipo);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'merge windows succesfully';

# #############################
# #	AÑADIR PASE A VENTANAS 	#
# #############################

$url = "/job/build_job_window_direct";

$date = '2014-03-03';
my $date_format = "%Y-%m-%d";
$bl = '*';
$ns = '/';

%data = ('date' => $date, 'date_format' => $date_format, 'bl' => $bl, 'ns' => $ns);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg} if (defined $json->{msg});
ok $json->{success}, 'job added succesfully';

done_testing;
