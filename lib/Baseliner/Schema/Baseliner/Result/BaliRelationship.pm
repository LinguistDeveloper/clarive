package Baseliner::Schema::Baseliner::Result::BaliRelationship;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_relationship");
__PACKAGE__->add_columns(
  "from_ns",
  { data_type => "VARCHAR2", default_value => undef, is_nullable => 0, size => 1024 },
  "to_ns",
  { data_type => "VARCHAR2", default_value => undef, is_nullable => 0, size => 1024 },
  "from_id",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
  "to_id",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
);
__PACKAGE__->set_primary_key("to_ns", "from_ns");

1;
