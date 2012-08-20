package Baseliner::Schema::Inf::Result::InfScriptRpt;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_script_rpt");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "plataforma",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "usergroupname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "email",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "descr",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "orden",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "visible",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
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
  "wingroupname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "scmgroupname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "form",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "status_flag",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "smtp",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "allowed_users",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VW7kv/GKIhhWqUfO6vwIAQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
