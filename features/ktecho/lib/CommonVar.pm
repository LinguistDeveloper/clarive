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
    'Preproducción'         => 'ANTE',
    'Producción'            => 'PROD',
    'Emergencia'            => 'PROD',
    'Producción Emergencia' => 'PROD',
    'Desarrollo Correctivo' => 'TEST',
    'Producción Correctivo' => 'PROD'
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
#    "Preproducción"         => "ANTE",
#    "Producción"            => "PROD",
#    "Emergencia"            => "PROD",
#    "Producción Emergencia" => "PROD",
#    "Desarrollo Correctivo" => "TEST",
#    "Producción Correctivo" => "PROD"
#);

#my %vista_estado = (
#    "DESA" => "Pruebas",
#    "TEST" => "Pruebas",
#    "ANTE" => "Preproducción",
#    "PROD" => "Producción"
#);

#my %estado_checkout = ( "Desarrollo Correctivo" => "Producción" );

#my %entorno_estado = (
#    "TEST" => "Pruebas",
#    "ANTE" => "Preproducción",
#    "PROD" => "Producción"
#);

#my %promote_process = (
#    "Desarrollo"            => "admin: Promover a Desarrollo",
#    "Emergencia"            => "admin: Promover a Emergencia",
#    "Desarrollo Correctivo" => "admin: Promover a Desarrollo Correctivo"
#);

#my %usuario_entorno = ( vtscm => 'TEST',  vascm => 'ANTE',  vpscm => 'PROD' );
#my %entorno_usuario = ( TEST  => 'vtscm', ANTE  => 'vascm', PROD  => 'vpscm' );

1;
