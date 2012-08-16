package Baseliner::Schema::Baseliner::Result::BaliChainedRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_chained_rule");
__PACKAGE__->add_columns(
  "id",
  {
    data_type   => "integer",
    is_nullable => 0,
  },
  "chain_id",
  {
    data_type   => "integer",
    is_nullable => 0,
  },
  "seq",
  {
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 0,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "step",
  { data_type => "varchar2", is_nullable => 0, size => 10 },
  "dsl",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "dsl_code",
  { data_type => "clob", is_nullable => 0 },
  "active",
  { data_type => "char", default_value => "1", is_nullable => 0, size => 1 },
  "ns",
  { data_type => "char", default_value => '/', is_nullable => 0, size => 20 },
  "bl",
  { data_type => 'varchar2', default_value => "*", size => 1024 },
  "service",
  { data_type => 'varchar2', size => 1024 }
);
__PACKAGE__->set_primary_key("id");

1;
