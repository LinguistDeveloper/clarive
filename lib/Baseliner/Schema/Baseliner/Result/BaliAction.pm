use utf8;
package Baseliner::Schema::Baseliner::Result::BaliAction;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliAction

=head1 DESCRIPTION

Additional actions.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_action");

__PACKAGE__->add_columns(
  "action_id", { data_type => "varchar2", size=>1024, is_nullable => 0, },
  "action_name", { data_type => "varchar2", size=>2048, is_nullable => 0, },
  "action_description", { data_type => "clob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key('action_id');

1;
