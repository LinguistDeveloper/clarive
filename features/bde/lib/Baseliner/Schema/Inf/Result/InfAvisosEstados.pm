package Baseliner::Schema::Inf::Result::InfAvisosEstados;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_avisos_estados");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "id_estado",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "estado",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "orden",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:10:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HNDXcZQH47MhD7fMSCp1GA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
