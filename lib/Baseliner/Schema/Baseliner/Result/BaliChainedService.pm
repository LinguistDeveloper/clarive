package Baseliner::Schema::Baseliner::Result::BaliChainedService;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_chained_service");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
    sequence => "bali_chain_service_seq",    
  },
  "chain_id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "seq",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "key",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "step",
  {
    data_type => "VARCHAR2",
    default_value => 'RUN',
    is_nullable => 1,
    size => 50,
  },
  "active",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "data",
  { data_type => "clob", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


1;
