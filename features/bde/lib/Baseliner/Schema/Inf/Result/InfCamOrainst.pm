package Baseliner::Schema::Inf::Result::InfCamOrainst;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_cam_orainst");
__PACKAGE__->add_columns(
  "cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 3,
  },
  "entorno",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "instancia",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "propietario",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 240,
  },
  "red",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "subaapl",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
);
__PACKAGE__->set_primary_key("cam", "entorno", "instancia", "propietario", "red");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-04-19 16:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tftZ8XemBIprCYj65tag5A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
