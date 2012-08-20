package Baseliner::Schema::Baseliner::Result::BaliRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRole

=cut

__PACKAGE__->table("bali_role");

=head1 ACCESSORS

=head2 id

  data_type: NUMBER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 38

=head2 role

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 0
  size: 255

=head2 description

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 2048

=head2 mailbox

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 38,
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


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-10-29 18:11:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SZePRrn3q3DyUUF50Lfv4w


sub name {
    my $self = shift;
    return $self->role;
}

1;
