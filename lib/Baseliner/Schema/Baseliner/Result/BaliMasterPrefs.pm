package Baseliner::Schema::Baseliner::Result::BaliMasterPrefs;

=head1 DESCRIPTION

This table contains user prefs for each mid

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_master_prefs");
__PACKAGE__->add_columns(
  "mid",
  { data_type => "number", is_nullable => 0 },
  "username",
  { data_type => "varchar", default_value => undef, is_nullable => 0 },
  "last_seen",
  { data_type => "date", default_value => undef, is_nullable => 1 },
  "kanban_seq",
  { data_type => "number", default_value => 0, is_nullable => 1 },
  "star_level",
  { data_type => "number", default_value => 0, is_nullable => 1 },
);
__PACKAGE__->set_primary_key('mid','username');

__PACKAGE__->belongs_to("master", "Baseliner::Schema::Baseliner::Result::BaliMaster", 
    { 'foreign.mid' => 'self.mid' },
    { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_master_prefs_idx_user', fields=>['username'] );
}

1;



