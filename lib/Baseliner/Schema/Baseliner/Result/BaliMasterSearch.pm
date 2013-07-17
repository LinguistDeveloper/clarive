package Baseliner::Schema::Baseliner::Result::BaliMasterSearch;

=head1 DESCRIPTION

This table contains a CLOB for holding search data

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_master_search");
__PACKAGE__->add_columns(
  "mid",
  { data_type => "number", default_value => undef, is_nullable => 0 },
  "ts",
  { data_type => "date", default_value => undef, is_nullable => 1 },
  "search_data",
  {
    data_type => "CLOB",
    default_value => '',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("mid");

__PACKAGE__->belongs_to("master", "Baseliner::Schema::Baseliner::Result::BaliMaster", 
    { 'foreign.mid' => 'self.mid' },
    { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

1;


