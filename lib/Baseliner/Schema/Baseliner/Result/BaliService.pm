package Baseliner::Schema::Baseliner::Result::BaliService;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_service");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "name",
  { data_type => "VARCHAR", is_nullable => 0, size => 100 },
  "description",
  { data_type => "VARCHAR", is_nullable => 0, size => 100 },
  "wiki_id",
  { data_type => "INT", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("id");

1;
