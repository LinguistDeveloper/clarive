package Baseliner::Schema::Baseliner::Result::BaliPlugin;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_plugin");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "plugin",
  { data_type => "VARCHAR", is_nullable => 0, size => 250 },
  "desc",
  { data_type => "VARCHAR", is_nullable => 0, size => 500 },
  "wiki_id",
  { data_type => "INT", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("id");


1;
