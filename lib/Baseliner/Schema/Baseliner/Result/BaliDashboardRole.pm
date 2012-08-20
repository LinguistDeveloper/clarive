use utf8;
package Baseliner::Schema::Baseliner::Result::BaliDashboardRole;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliDashboardRole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_dashboard_role");

__PACKAGE__->add_columns(
  "id_dashboard",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "id_role",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },  
);


1;
