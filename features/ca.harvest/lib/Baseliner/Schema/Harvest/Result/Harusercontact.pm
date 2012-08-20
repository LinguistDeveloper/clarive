package Baseliner::Schema::Harvest::Result::Harusercontact;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("harusercontact");
__PACKAGE__->add_columns(
  "formobjid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "contactextension",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "zip",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "contactphone",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 32 },
  "state",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "city",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 66,
  },
  "contactfax",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 66,
  },
  "contactname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 66,
  },
  "contacttitle",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 66,
  },
  "country",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 66,
  },
  "position",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 66,
  },
  "mailstop",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 130,
  },
  "organization",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 130,
  },
  "address",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 257,
  },
);
__PACKAGE__->set_primary_key("formobjid");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-02 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ws2h9vf5QE/CCYcHA+4ovg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
