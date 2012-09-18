use utf8;
package Baseliner::Schema::Baseliner::Result::BaliDashboard;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliDashboard

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_dashboard");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_dashboard_seq",
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "dashlets",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "is_main",
  { data_type => "char", is_nullable => 1, size => 1, default_value => '0'},
  "is_columns",
  { data_type => "char", is_nullable => 1, size => 1, default_value => '1'},
  "is_system",
  { data_type => "char", is_nullable => 1, size => 1, default_value => '0'},
  "system_params",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },  
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "dashboard_roles",
  "Baseliner::Schema::Baseliner::Result::BaliDashboardRole",
  { "foreign.id_dashboard" => "self.id" },
);

1;
