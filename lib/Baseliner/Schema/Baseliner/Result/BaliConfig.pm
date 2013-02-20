package Baseliner::Schema::Baseliner::Result::BaliConfig;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    is_nullable => 0,
    is_auto_increment => 1,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => '/',
    is_nullable => 0,
    size => 1000,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => '*',
    is_nullable => 0,
    size => 100,
  },
  "key",
  {
    data_type => "VARCHAR2",
    is_nullable => 0,
    size => 100,
  },
  "value",
  {
    data_type => "VARCHAR2",
    is_nullable => 1,
    size => 1536,
  },
  "ts",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 0,
    size => 19,
  },
  "ref",
  {
    data_type => "NUMBER",
    is_nullable => 1,
  },
  "reftable",
  {
    data_type => "VARCHAR2",
    is_nullable => 1,
    size => 100,
  },
  "data",
  {
    data_type => "CLOB",
    is_nullable => 1,
  },
  "parent_id",
  {
    data_type => "NUMBER",
    default_value => 0,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");

1;
