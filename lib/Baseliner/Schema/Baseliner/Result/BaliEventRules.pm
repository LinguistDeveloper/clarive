use utf8;
package Baseliner::Schema::Baseliner::Result::BaliEventRules;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliEventRules

=head1 DESCRIPTION

Each rule executed for a given event.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_event_rules");

__PACKAGE__->add_columns(
  "id", { data_type => "number", is_auto_increment => 1, is_nullable => 0, sequence => "bali_event_rules_seq", },
  "id_event", { data_type => "number", is_nullable => 0, },
  "id_rule", { data_type => "number", is_nullable => 0, },
  "return_code", { data_type => "number", is_nullable => 1, default_value=>'0' },
  "stash_data", { data_type => "clob", is_nullable => 1 },
  "ts",   {
    data_type     => "datetime",
    is_nullable   => 0,
    set_on_create => 1,
    timezone => Util->_tz,
  },
  "dsl", { data_type => "clob", is_nullable => 1 },
  "log_output", { data_type => "clob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  "event",
  "Baseliner::Schema::Baseliner::Result::BaliEvent",
  { "foreign.id" => "self.id_event" },
);

__PACKAGE__->belongs_to(
  "rule",
  "Baseliner::Schema::Baseliner::Result::BaliRule",
  { "foreign.id" => "self.id_rule" },
);

1;


