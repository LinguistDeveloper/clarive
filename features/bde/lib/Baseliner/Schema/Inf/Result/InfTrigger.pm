package Baseliner::Schema::Inf::Result::InfTrigger;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_trigger");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "trigger_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 40,
  },
  "trigger_type",
  {
    data_type => "VARCHAR2",
    default_value => "'trigger'             ",
    is_nullable => 0,
    size => 20,
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
  "trigger_body",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "args",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "trigger_comment",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "ismetadata",
  { data_type => "CHAR", default_value => "'0'", is_nullable => 1, size => 1 },
  "trigger_description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "status_flag",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 1 },
  "trigger_ref",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "trigger_refcnt",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 6 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("uk_inf_trigger", ["trigger_name"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/ue3Pq7VJAGXJVE6QekDfg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
