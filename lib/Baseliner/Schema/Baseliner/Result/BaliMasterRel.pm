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
  { data_type => "numeric", default_value => undef, is_nullable => 1 },
  "to_mid",
  { data_type => "numeric", default_value => undef, is_nullable => 1 },
  "rel_type",
  {
    data_type => "VARCHAR2",
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("from_mid", "to_mid", "rel_type");

__PACKAGE__->belongs_to("master_from", "Baseliner::Schema::Baseliner::Result::BaliMaster", { 'foreign.mid' => 'self.from_mid' });
__PACKAGE__->belongs_to("master_to", "Baseliner::Schema::Baseliner::Result::BaliMaster", { 'foreign.mid' => 'self.to_mid' });

1;

