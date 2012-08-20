package Baseliner::Schema::Inf::Result::InfStatusTemp;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_status_temp");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "cam",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "env",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 1 },
  "column_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "task",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "newvalue",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "oldvalue",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "status_internal",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "dependencies_internal",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "dummy",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "lck",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "flag",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "seq",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "admin",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "subappls",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "todo",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "lvl",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "freq",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "flow_id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "delete_dependencies",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "hidden_delete",
  { data_type => "NUMBER", default_value => undef, is_nullable => 0, size => 1 },
  "flag_notask_default",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "identdat",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "idreddat",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "identpet",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "idredpet",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "subaplicacion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  "id_old",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "correlation",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "idpeticion",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wbweCzUqp/5iVQ2QThc9Xg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
