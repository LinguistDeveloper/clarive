package Baseliner::Schema::Inf::Result::InfDataMv;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_data_mv");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "mv_index",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "mv_valor",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "idform",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id", "mv_index");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:15:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7oCd4Gp5wUjvaP71G7O5ug


# You can replace this text with custom content, and it will be preserved on regeneration
1;
