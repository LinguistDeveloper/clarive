use utf8;
package Baseliner::Schema::Baseliner::Result::BaliRule;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRule;

=head1 DESCRIPTION

Rules

=cut


use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_rule");

__PACKAGE__->add_columns(
  "id", { data_type => "number", is_nullable => 0, is_auto_increment=>1 },
  "rule_name", { data_type => "varchar2", size=>1024, is_nullable => 0 },
  "rule_type", { data_type => "varchar2", size=>1024, is_nullable => 0, default_value=>'event' },
  "rule_seq", { data_type => "number", is_nullable => 0, default_value=>1 },
  "rule_when", { data_type => "varchar2", size=>1024, is_nullable => 1 },
  "rule_event", { data_type => "varchar2", size=>1024, is_nullable => 1 },
  "rule_active", { data_type => "varchar2", size=>1, is_nullable => 1, default_value=>'1' },
);

__PACKAGE__->set_primary_key("id");


1;

