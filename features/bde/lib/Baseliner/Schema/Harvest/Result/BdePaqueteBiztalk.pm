package Baseliner::Schema::Harvest::Result::BdePaqueteBiztalk;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bde_paquete_biztalk");
__PACKAGE__->add_columns(
  "prj_env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "prj_proyecto",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "prj_tipo",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "prj_subaplicacion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "prj_fullname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "prj_registro_gac",
  {
    data_type => "VARCHAR2",
    default_value => "'Si'",
    is_nullable => 1,
    size => 2,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-28 13:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HmtwvUdeA9Uw82/7aGT3/w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
