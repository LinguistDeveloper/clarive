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
  "id", { 
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_master_cal_seq",
  },
  "mid", { data_type => "number", is_nullable => 0, },
  "id_parent", { data_type => "number", is_nullable => 1, },
  "start_date", {
    data_type     => "datetime",
    is_nullable   => 0,
    original      => { data_type => "date" },
  },
  "end_date", {
    data_type     => "datetime",
    is_nullable   => 0,
    original      => { data_type => "date" },
  },
  "plan_start_date", {
    data_type     => "datetime",
    is_nullable   => 0,
    original      => { data_type => "date" },
  },
  "plan_end_date", {
    data_type     => "datetime",
    is_nullable   => 0,
    original      => { data_type => "date" },
  },
  slottype  => { data_type => "varchar2", is_nullable => 0, size => 255 },
  slotname  => { data_type => "varchar2", is_nullable => 0, size => 4000 },
  rel_field => { data_type => "varchar2", is_nullable => 0, size => 2000 },
  #"created_by", { data_type => "varchar2", is_nullable => 0, size => 255 },
  "allday", { data_type => "char", default_value => "0", is_nullable => 0, size => 1 },
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->load_components("+Baseliner::Schema::Master");
__PACKAGE__->has_master;

1;

