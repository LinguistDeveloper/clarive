package Baseliner::Schema::Baseliner::Result::BaliRoleuser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRoleuser

=cut

__PACKAGE__->table("bali_roleuser");

=head1 ACCESSORS

=head2 username

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 0
  size: 255

=head2 id_role

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 38

=head2 ns

  data_type: VARCHAR2
  default_value: /
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "id_role",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => "/",
    is_nullable => 0,
    size => 100,
  },
  "id_project",
  {
    data_type => "number",
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("ns", "id_role", "username");

__PACKAGE__->belongs_to(
  "id_role",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);


__PACKAGE__->belongs_to(
  "role",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);

__PACKAGE__->has_many(
  "actions",
  "Baseliner::Schema::Baseliner::Result::BaliRoleaction",
  { 'foreign.id_role' => "self.id_role" },
);

__PACKAGE__->has_many(
  "requests",
  "Baseliner::Schema::Baseliner::Result::BaliRequest",
  [
      { 'foreign.ns' => "self.ns" },
      { 'foreign.bl' => "actions.bl" },
      { 'foreign.action' => "actions.action" },
  ]
);

__PACKAGE__->belongs_to(
  "projects",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { mid => 'id_project' },
);

__PACKAGE__->has_one(
  "bali_user",
  "Baseliner::Schema::Baseliner::Result::BaliUser",
  { "foreign.username" => "self.username" },
);

1;
