package BaselinerX::SQL;
use Baseliner::Plug;
use Baseliner::Utils;

register 'config.sql.types' => {
  metadata => [
    {id => 'BDY', default => "PACKAGE BODY"},
    {id => 'FNC', default => "FUNCTION"},
    {id => 'PCK', default => "PACKAGE"},
    {id => 'PKB', default => "PACKAGE BODY"},
    {id => 'PKG', default => "PACKAGE"},
    {id => 'PKS', default => "PACKAGE"},
    {id => 'PRC', default => "PROCEDURE"},
    {id => 'SPC', default => "PACKAGE"},
    {id => 'SYN', default => "SYNONYM"},
    {id => 'TPB', default => "TYPE BODY"},
    {id => 'TPS', default => "TYPE"},
    {id => 'TRG', default => "TRIGGER"},
    {id => 'TYP', default => "TYPE"},
    {id => 'VIW', default => "VIEW"},
    {id => 'VW',  default => "VIEW"},
    {id => 'bdy', default => "PACKAGE BODY"},
    {id => 'fnc', default => "FUNCTION"},
    {id => 'pck', default => "PACKAGE"},
    {id => 'pkb', default => "PACKAGE BODY"},
    {id => 'pkg', default => "PACKAGE"},
    {id => 'pks', default => "PACKAGE"},
    {id => 'prc', default => "PROCEDURE"},
    {id => 'spc', default => "PACKAGE"},
    {id => 'syn', default => "SYNONYM"},
    {id => 'tpb', default => "TYPE BODY"},
    {id => 'tps', default => "TYPE"},
    {id => 'trg', default => "TRIGGER"},
    {id => 'typ', default => "TYPE"},
    {id => 'viw', default => "VIEW"},
    {id => 'vw',  default => "VIEW"},
  ]
};

register 'config.sql.types.dll' => {
  metadata => [
    {id => 'BDY', default => "PACKAGE_BODY"},
    {id => 'FNC', default => "FUNCTION"},
    {id => 'PCK', default => "PACKAGE"},
    {id => 'PKB', default => "PACKAGE_BODY"},
    {id => 'PKG', default => "PACKAGE"},
    {id => 'PKS', default => "PACKAGE"},
    {id => 'PRC', default => "PROCEDURE"},
    {id => 'SPC', default => "PACKAGE"},
    {id => 'SYN', default => "SYNONYM"},
    {id => 'TPB', default => "TYPE_BODY"},
    {id => 'TPS', default => "TYPE"},
    {id => 'TRG', default => "TRIGGER"},
    {id => 'TYP', default => "TYPE"},
    {id => 'VIW', default => "VIEW"},
    {id => 'VW',  default => "VIEW"},
    {id => 'bdy', default => "PACKAGE_BODY"},
    {id => 'fnc', default => "FUNCTION"},
    {id => 'pck', default => "PACKAGE"},
    {id => 'pkb', default => "PACKAGE_BODY"},
    {id => 'pkg', default => "PACKAGE"},
    {id => 'pks', default => "PACKAGE"},
    {id => 'prc', default => "PROCEDURE"},
    {id => 'spc', default => "PACKAGE"},
    {id => 'syn', default => "SYNONYM"},
    {id => 'tpb', default => "TYPE_BODY"},
    {id => 'tps', default => "TYPE"},
    {id => 'trg', default => "TRIGGER"},
    {id => 'typ', default => "TYPE"},
    {id => 'viw', default => "VIEW"},
    {id => 'vw',  default => "VIEW"},
  ]
};

1;
