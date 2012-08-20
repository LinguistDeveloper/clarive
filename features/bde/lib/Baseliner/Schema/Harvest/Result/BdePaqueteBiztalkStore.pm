package Baseliner::Schema::Harvest::Result::BdePaqueteBiztalkStore;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bde_paquete_biztalk_store");
__PACKAGE__->add_columns(
  "prj_env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "prj_item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1000,
  },
  "prj_store",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
);
__PACKAGE__->set_primary_key("prj_env", "prj_item");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-28 13:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lFsOdTtKbe2J0oZH6ARFZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
