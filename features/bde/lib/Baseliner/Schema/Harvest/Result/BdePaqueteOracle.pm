package Baseliner::Schema::Harvest::Result::BdePaqueteOracle;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bde_paquete_oracle");
__PACKAGE__->add_columns(
  "ora_prj",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "ora_fullname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "ora_redes",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "ora_instancia",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "ora_entorno",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 4 },
  "ora_desplegar",
  { data_type => "CHAR", default_value => "'Si'", is_nullable => 1, size => 2 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-28 13:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XmZyiB42dIzc7d4M/1+a6g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
