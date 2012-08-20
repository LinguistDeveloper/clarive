package Baseliner::Schema::Inf::Result::InfAvisosMaestro;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_avisos_maestro");
__PACKAGE__->add_columns(
  "id",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
  "descripcion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "red",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "pestana",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "subappl",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "alerta",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:10:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5vzA4zvFxgY+b8pMo/SS0w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
