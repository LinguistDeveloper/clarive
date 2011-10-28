package Baseliner::Schema::Inf::Result::InfPeticionTarea;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_peticion_tarea");
__PACKAGE__->add_columns(
  "taskname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 40,
  },
  "idpeticion",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "starting_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
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
  "status",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "starting_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "dependencies",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "antecedents",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "msg",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "task",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("idpeticion", "taskname");
__PACKAGE__->belongs_to(
  "idpeticion",
  "Baseliner::Schema::Inf::Result::InfPeticion",
  { id => "idpeticion" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:17:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bgxq3dwuekKJT9D2hKKuPw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
