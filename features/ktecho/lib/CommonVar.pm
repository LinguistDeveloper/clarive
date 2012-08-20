package BaselinerX::Ktecho::CommonVar;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;

use Exporter::Tidy default => [qw(%estado_entorno)];

my %estado_entorno = (
    'Desarrollo'            => 'TEST',
    'Pruebas'               => 'TEST',
    'Preproducci�n'         => 'ANTE',
    'Producci�n'            => 'PROD',
    'Emergencia'            => 'PROD',
    'Producci�n Emergencia' => 'PROD',
    'Desarrollo Correctivo' => 'TEST',
    'Producci�n Correctivo' => 'PROD'
);

#my %vista_entorno = (
#    "DESA" => "TEST",
#    "TEST" => "TEST",
#    "ANTE" => "ANTE",
#    "PROD" => "PROD"
#);

#my %estado_vista = (
#    "Desarrollo"            => "DESA",
#    "Pruebas"               => "TEST",
#    "Preproducci�n"         => "ANTE",
#    "Producci�n"            => "PROD",
#    "Emergencia"            => "PROD",
#    "Producci�n Emergencia" => "PROD",
#    "Desarrollo Correctivo" => "TEST",
#    "Producci�n Correctivo" => "PROD"
#);

#my %vista_estado = (
#    "DESA" => "Pruebas",
#    "TEST" => "Pruebas",
#    "ANTE" => "Preproducci�n",
#    "PROD" => "Producci�n"
#);

#my %estado_checkout = ( "Desarrollo Correctivo" => "Producci�n" );

#my %entorno_estado = (
#    "TEST" => "Pruebas",
#    "ANTE" => "Preproducci�n",
#    "PROD" => "Producci�n"
#);

#my %promote_process = (
#    "Desarrollo"            => "admin: Promover a Desarrollo",
#    "Emergencia"            => "admin: Promover a Emergencia",
#    "Desarrollo Correctivo" => "admin: Promover a Desarrollo Correctivo"
#);

#my %usuario_entorno = ( vtscm => 'TEST',  vascm => 'ANTE',  vpscm => 'PROD' );
#my %entorno_usuario = ( TEST  => 'vtscm', ANTE  => 'vascm', PROD  => 'vpscm' );

1;
