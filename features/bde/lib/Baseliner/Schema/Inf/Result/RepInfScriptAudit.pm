package Baseliner::Schema::Inf::Result::RepInfScriptAudit;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("rep_inf_script_audit");
__PACKAGE__->add_columns(
  "idscript",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "nombre_script",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "ruta_script",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 500,
  },
  "parametros",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "iniciado_por",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "id_peticion",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "nombre_peticion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "id_tarea",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "nombre_tarea",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 80,
  },
  "maquina",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "fecha_inicio",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "fecha_finalizacion",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xBs1Nu02ybK6Lh9shSliCw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
