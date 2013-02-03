package Baseliner::Schema::Baseliner::Result::BaliReleaseItems;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_release_items");
__PACKAGE__->add_columns(
  "id",
  { data_type => "NUMBER", default_value => undef, is_nullable => 0, size => 38 },
  "id_rel",
  { data_type => "NUMBER", default_value => undef, is_nullable => 0, size => 38 },
  "item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "provider",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "id_rel",
  "Baseliner::Schema::Baseliner::Result::BaliRelease",
  { id => "id_rel" },
);


__PACKAGE__->belongs_to(
  "release",
  "Baseliner::Schema::Baseliner::Result::BaliRelease",
  { id => "id_rel" },
);

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_release_items_idx_id_rel', fields=>['id_rel'] );
}

1;
