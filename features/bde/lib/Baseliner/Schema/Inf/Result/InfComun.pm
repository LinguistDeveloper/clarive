package Baseliner::Schema::Inf::Result::InfComun;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_comun");
__PACKAGE__->add_columns(
  "variable",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "valor",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "descripcion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 3000,
  },
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "recargar",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:15:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tBSgv5dTHTYhFUfYXDPLTw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
