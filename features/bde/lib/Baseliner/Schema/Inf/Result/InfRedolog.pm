package Baseliner::Schema::Inf::Result::InfRedolog;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_redolog");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "tablename",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "dml",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "instant",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "id_inf",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "grupopase",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:18:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GYEhgB2kFdRVLRR5xyVN2w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
