package Baseliner::Schema::Inf::Result::InfPeticion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_peticion");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "nombre",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 3,
  },
  "env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "usuario",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "fecha",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "iddata",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "num",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "starting_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "starting_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "running_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "running_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "finished_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "finished_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "msg",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "inf_peticion_tareas",
  "Baseliner::Schema::Inf::Result::InfPeticionTarea",
  { "foreign.idpeticion" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:17:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YEYreRLp5vO6G6HFVapbGQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
