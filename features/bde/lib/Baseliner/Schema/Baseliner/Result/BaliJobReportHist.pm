package Baseliner::Schema::Baseliner::Result::BaliJobReportHist;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_job_report_hist");

__PACKAGE__->add_columns(
  'PAS_CODIGO',     { data_type => 'varchar2', is_nullable=>0,size=>17},
  'PAS_TIPO',       { data_type => 'char', is_nullable => 0,size=>8},
  'PAS_DESDE',      { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  'PAS_HASTA',      { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  'PAS_ESTADO',     { data_type => 'char', is_nullable => 0,size=>1},
  'PAS_USUARIO',    { data_type => 'varchar2', is_nullable=>0,size=>30},
  'PAS_APLICACION', { data_type => 'varchar2', is_nullable=>0,size=>255},
  'PAS_STATENAME',  { data_type => 'varchar2', is_nullable=>0,size=>30},
  'PAS_LASTLOG',    { data_type => 'varchar2', is_nullable=>0,size=>512},
  'PAS_LASTLOGTIPO',{ data_type => 'char', is_nullable=>0,size=>1},
  'PAS_LOGHTML',    { data_type => 'varchar2', is_nullable=>0,size=>255},
  'PAS_NATURALEZA', { data_type => 'varchar2', is_nullable=>0,size=>255},
  'PAS_SUBAPL',     { data_type => 'varchar2', is_nullable=>0,size=>255},
  'PAS_NODIST',     { data_type => 'char', is_nullable=>0,size=>1, default_value => '0'},
);

__PACKAGE__->set_primary_key('PAS_CODIGO');

1;
