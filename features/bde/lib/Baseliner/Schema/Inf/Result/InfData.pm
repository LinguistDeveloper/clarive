package Baseliner::Schema::Inf::Result::InfData;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_data");
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
__PACKAGE__->add_unique_constraint(
  "data_unique",
  ["idform", "cam", "column_name", "ident", "idred", "subaplicacion"],
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:15:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BInhMgh95OYgbofWFpJthw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
