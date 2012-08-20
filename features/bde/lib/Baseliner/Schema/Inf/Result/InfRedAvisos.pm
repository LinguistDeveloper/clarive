package Baseliner::Schema::Inf::Result::InfRedAvisos;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_red_avisos");
__PACKAGE__->add_columns(
  "idred",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "descripcion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "orden",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:18:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:41x8HRzJm9Mf66D/xPS1+Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
