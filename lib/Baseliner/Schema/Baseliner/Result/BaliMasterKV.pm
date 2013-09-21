package Baseliner::Schema::Baseliner::Result::BaliMasterKV;

=head1 DESCRIPTION

This table contains a KV for searching

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_master_kv");
__PACKAGE__->add_columns(
  "id",
  { data_type => "number", default_value => undef, is_nullable => 0, is_auto_increment=>1 },
  "mid",
  { data_type => "number", default_value => undef, is_nullable => 0 },
  "mtype",
  { data_type => "varchar", size => 20, is_nullable => 1 },
  "mkey",
  { data_type => "varchar", size=>4000, is_nullable => 0 },
  "mvalue",
  { data_type => "clob", is_nullable => 1 },
  "mvalue_str",
  { data_type => "varchar", size=>4000, is_nullable => 1 },
  "mvalue_date",
  { data_type => "date", is_nullable => 1 },
  "mvalue_num",
  { data_type => "number", default_value => 0, is_nullable => 1 },
  "mpos",
  { data_type => "number", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_master_kvmidk_idx', fields=>['mid','mkey'] );
   $sqlt_table->add_index(name =>'bali_master_kvsearch_idx', fields=>['mvalue_str'] );
   $sqlt_table->add_index(name =>'bali_master_kvnum_idx', fields=>['mvalue_num'] );
   # create index bali_master_kv_fullix on bali_master_kv( mvalue ) indextype is ctxsys.context;
}

__PACKAGE__->belongs_to("master", "Baseliner::Schema::Baseliner::Result::BaliMaster", 
    { 'foreign.mid' => 'self.mid' },
    { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

1;



