package Baseliner::Schema::Inf::Result::InfScript;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_script");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "rpt",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "script",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 500,
  },
  "param",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "os",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "created_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "created_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "updated_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "updated_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "dummy",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "dummy2",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "usu",
  {
    data_type => "VARCHAR2",
    default_value => "''",
    is_nullable => 1,
    size => 50,
  },
  "comentario",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("uk_inf_script", ["name"]);
__PACKAGE__->has_many(
  "inf_script_runs",
  "Baseliner::Schema::Inf::Result::InfScriptRun",
  { "foreign.idscript" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xiU5jSv+LY4HkBm070yD2A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
