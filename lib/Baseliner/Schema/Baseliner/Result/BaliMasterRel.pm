package Baseliner::Schema::Baseliner::Result::BaliMasterRel;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliMasterRel

=head1 DESCRIPTION

This is the new master-relationship table

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("bali_master_rel");
__PACKAGE__->add_columns(
  "from_mid",
  { data_type => "number", default_value => undef, is_nullable => 0 },
  "to_mid",
  { data_type => "number", default_value => undef, is_nullable => 0 },
  "rel_type",
  {
    data_type => "VARCHAR2",
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  "rel_field", 
  {
    data_type => "VARCHAR2",
    default_value => '',
    is_nullable => 1,
    size => 255,
  },
  "rel_seq",
  { data_type => "number", default_value => undef, 
      is_nullable       => 1,
      is_auto_increment => 1,
      sequence          => "bali_master_rel_seq"
  },
);
__PACKAGE__->set_primary_key("from_mid", "to_mid", "rel_type");

__PACKAGE__->belongs_to(
    "master_from",
    "Baseliner::Schema::Baseliner::Result::BaliMaster",
    { 'foreign.mid' => 'self.from_mid' },
);
__PACKAGE__->belongs_to(
    "master_to",
    "Baseliner::Schema::Baseliner::Result::BaliMaster",
    { 'foreign.mid' => 'self.to_mid' },
);

# joining with itself
__PACKAGE__->has_many(
    "to_children", __PACKAGE__,
    { 'foreign.from_mid' => 'self.to_mid' },
    { cascade_delete     => 0, on_delete => undef, is_foreign_key_constraint => 0, }
);
__PACKAGE__->has_many(
    "from_children", __PACKAGE__,
    { 'foreign.from_mid' => 'self.from_mid' },
    { cascade_delete     => 0, on_delete => undef, is_foreign_key_constraint => 0, }
);
__PACKAGE__->has_many(
    "from_parents", __PACKAGE__,
    { 'foreign.to_mid' => 'self.from_mid' },
    { cascade_delete   => 0, on_delete => undef, is_foreign_key_constraint => 0, }
);
__PACKAGE__->has_many(
    "to_parents", __PACKAGE__,
    { 'foreign.to_mid' => 'self.to_mid' },
    { cascade_delete   => 0, on_delete => undef, is_foreign_key_constraint => 0, }
);

1;

