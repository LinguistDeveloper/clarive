package Baseliner::Schema::Inf::Result::InfOid;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_oid");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "oid",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 4000,
  },
  "oper",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  "created_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 80,
  },
  "oldname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 80,
  },
  "newname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:10:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qq/5FwosCrBfEB/xt9me4A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
