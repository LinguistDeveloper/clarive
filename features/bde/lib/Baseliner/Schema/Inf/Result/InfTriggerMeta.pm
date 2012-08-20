package Baseliner::Schema::Inf::Result::InfTriggerMeta;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_trigger_meta");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "column_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "seq",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "display_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 240,
  },
  "short_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "column_group",
  {
    data_type => "VARCHAR2",
    default_value => "'MAIN'                ",
    is_nullable => 0,
    size => 30,
  },
  "advanced",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "list_of_values",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "default_value",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "column_section",
  {
    data_type => "NUMBER",
    default_value => "0                     ",
    is_nullable => 0,
    size => 1,
  },
  "created_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "created_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 90,
  },
  "updated_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "updated_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 90,
  },
  "data_type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "data_size",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "env",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "rpt",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "lck",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 1 },
  "adm",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 1 },
  "dependencies",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "display_size",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "acl",
  {
    data_type => "VARCHAR2",
    default_value => "'#RPT-SCM#'",
    is_nullable => 1,
    size => 4000,
  },
  "groups",
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
    size => 80,
  },
  "targets",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "targets_",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "dummy2",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "task",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "task_",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "rpt_",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "primarykey",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 126 },
  "subappl",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 1 },
  "extra1",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "extra2",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "flag_dist",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 1 },
  "flag_ctxt",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 1 },
  "flag_cache",
  { data_type => "NUMBER", default_value => "'0'", is_nullable => 1, size => 1 },
  "column_attributes",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("uk_inf_trigger_meta", ["column_name"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5XlsCkf84cXEC7Yj16gj0w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
