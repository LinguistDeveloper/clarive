package Baseliner::Schema::Baseliner::Result::BaliRole;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRole

=cut

__PACKAGE__->table("bali_role");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "role",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "mailbox",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 bali_roleactions

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliRoleaction>

=cut

__PACKAGE__->has_many(
  "bali_roleactions",
  "Baseliner::Schema::Baseliner::Result::BaliRoleaction",
  { "foreign.id_role" => "self.id" },
);

=head2 bali_roleusers

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliRoleuser>

=cut

__PACKAGE__->has_many(
  "bali_roleusers",
  "Baseliner::Schema::Baseliner::Result::BaliRoleuser",
  { "foreign.id_role" => "self.id" },
);


__PACKAGE__->has_many(
  "roles",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesAdmin",
  { id => "id_role" },
);

__PACKAGE__->has_many(
  "dashboard_roles",
  "Baseliner::Schema::Baseliner::Result::BaliDashboardRole",
  { "foreign.id_role" => "self.id" },
);

sub name {
    my $self = shift;
    return $self->role;
}

1;
