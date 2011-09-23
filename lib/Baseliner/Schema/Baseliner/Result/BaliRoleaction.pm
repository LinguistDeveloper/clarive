package Baseliner::Schema::Baseliner::Result::BaliRoleaction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRoleaction

=cut

__PACKAGE__->table("bali_roleaction");

=head1 ACCESSORS

=head2 id_role

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 38

=head2 action

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 0
  size: 255

=head2 bl

  data_type: VARCHAR2
  default_value: *
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "id_role",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "action",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "bl",
  { data_type => "VARCHAR2", default_value => "*", is_nullable => 0, size => 50 },
);
__PACKAGE__->set_primary_key("action", "id_role", "bl");

=head1 RELATIONS

=head2 id_role

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliRole>

=cut

__PACKAGE__->belongs_to(
  "id_role",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-10-29 18:11:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cutSh+7KzO2/fbteXcIvcA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
