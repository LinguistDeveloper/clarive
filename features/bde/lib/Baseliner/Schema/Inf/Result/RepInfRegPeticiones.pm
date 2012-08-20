package Baseliner::Schema::Inf::Result::RepInfRegPeticiones;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("rep_inf_reg_peticiones");
__PACKAGE__->add_columns(
  "clave",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "codigo_de_gasto",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 6,
  },
  "fecha_llegada",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "observaciones",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1083,
  },
  "rechazada",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 27,
  },
  "fecha_inicio",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "fecha_finalizacion",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:18:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:neEiWi7rJEhSs/nSJQtFKg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
