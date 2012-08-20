package Baseliner::Schema::Harvest::Result::BdePaquetePrepost;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bde_paquete_prepost");
__PACKAGE__->add_columns(
  "pp_cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "pp_env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "pp_naturaleza",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "pp_prepost",
  {
    data_type => "VARCHAR2",
    default_value => "'PRE'",
    is_nullable => 1,
    size => 4,
  },
  "pp_exec",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "pp_maq",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "pp_usu",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "pp_os",
  {
    data_type => "VARCHAR2",
    default_value => "'UNIX'",
    is_nullable => 1,
    size => 4,
  },
  "pp_block",
  { data_type => "CHAR", default_value => "'N'", is_nullable => 1, size => 1 },
  "pp_orden",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 126 },
  "pp_user",
  {
    data_type => "VARCHAR2",
    default_value => "''",
    is_nullable => 1,
    size => 255,
  },
  "pp_activo",
  { data_type => "CHAR", default_value => "'S'", is_nullable => 1, size => 1 },
  "pp_errcode",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-28 13:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vtMPsBsQmzM6Saf4+ba7nw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
