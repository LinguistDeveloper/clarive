package Baseliner::Schema::Inf::Result::InfHashdata;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_hashdata");
__PACKAGE__->add_columns(
  "cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 3,
  },
  "idform",
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
    is_nullable => 1,
    size => 30,
  },
  "ident",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "idred",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "subaplicacion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  "valor",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:16:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vH9piSN36m5rp3QorpWdZg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
