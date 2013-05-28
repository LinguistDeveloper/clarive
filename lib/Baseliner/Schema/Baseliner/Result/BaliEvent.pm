use utf8;
package Baseliner::Schema::Baseliner::Result::BaliEvent;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliMasterRel

=head1 DESCRIPTION

This is the new master-relationship table

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_event");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_event_seq",
  },
  "mid",
  {
    data_type => "number",
    is_nullable => 0,
  },
  "event_key",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "event_status",
  { data_type => "varchar2", is_nullable => 0, size => 255, default_value=>'new' },
  "event_data",
  { data_type => "clob", is_nullable => 0 },
  "ts",
  {
    data_type     => "datetime",
    default_value => \"SYSDATE",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "username",
  { data_type => "varchar2", is_nullable=>1, size => 1024 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "rules",
  "Baseliner::Schema::Baseliner::Result::BaliEventRules",
  { "foreign.id_event" => "self.id" },
);

1;

