package Baseliner::Schema::Inf::Result::Infvar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("infvar");
__PACKAGE__->add_columns(
  "variable",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "valor",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 4000,
  },
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "internal",
  { data_type => "NUMBER", default_value => undef, is_nullable => 0, size => 1 },
  "rpt",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:20:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pxpCFgJFJONK5SvyVMMZtQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
