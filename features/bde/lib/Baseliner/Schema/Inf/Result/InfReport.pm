package Baseliner::Schema::Inf::Result::InfReport;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_report");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "report",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 40,
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
  "url",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "acl",
  {
    data_type => "VARCHAR2",
    default_value => "'Todos'",
    is_nullable => 1,
    size => 2000,
  },
  "dummy",
  {
    data_type => "VARCHAR2",
    default_value => "'Todos'",
    is_nullable => 1,
    size => 80,
  },
  "grupo",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("sys_c00153860", ["report"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:18:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BitmsgybsOxxvgmDUbqmeA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
