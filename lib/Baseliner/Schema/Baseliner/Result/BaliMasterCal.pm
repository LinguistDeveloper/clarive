package Baseliner::Schema::Baseliner::Result::BaliMasterCal;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliMasterCal

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->load_components("+Baseliner::Schema::Master");
__PACKAGE__->table("bali_master_cal");

__PACKAGE__->add_columns(
  "id", { data_type => "number", is_nullable => 0, },
  "mid", { data_type => "number", is_nullable => 0, },
  "start_date", {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "end_date", {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  slotname => { data_type => "varchar2", is_nullable => 0, size => 255 },
  #"created_by", { data_type => "varchar2", is_nullable => 0, size => 255 },
  "allday", { data_type => "char", default_value => "0", is_nullable => 0, size => 1 },
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->load_components("+Baseliner::Schema::Master");
__PACKAGE__->has_master;

1;

