use utf8;
package Baseliner::Schema::Baseliner::Result::BaliRuleStatement;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRuleStatement;

=head1 DESCRIPTION

Rule Abstract Syntax Tree storage, one row per statement.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

# __PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_rule_statement");

__PACKAGE__->add_columns(
  "id", { data_type => "number", is_nullable => 0, is_auto_increment=>1 },
  "id_parent", { data_type => "number", is_nullable => 1 },
  "id_rule", { data_type => "number", is_nullable => 0 },
  "stmt_text", { data_type => "varchar2", size=>2048, is_nullable => 0 },
  "stmt_attr", { data_type => "clob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "id_rule",
  "Baseliner::Schema::Baseliner::Result::BaliRule",
  { id => "id_rule" },
);

1;


