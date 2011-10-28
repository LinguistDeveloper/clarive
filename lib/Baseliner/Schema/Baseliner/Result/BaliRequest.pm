package Baseliner::Schema::Baseliner::Result::BaliRequest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRequest

=cut

__PACKAGE__->table("bali_request");

=head1 ACCESSORS

=head2 id

  data_type: NUMBER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 38

=head2 ns

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 0
  size: 1024

=head2 bl

  data_type: VARCHAR2
  default_value: *
  is_nullable: 1
  size: 50

=head2 requested_on

  data_type: DATE
  default_value: undef
  is_nullable: 1
  size: 19

=head2 finished_on

  data_type: DATE
  default_value: undef
  is_nullable: 1
  size: 19

=head2 status

  data_type: VARCHAR2
  default_value: pending
  is_nullable: 1
  size: 50

=head2 finished_by

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 requested_by

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 action

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 id_parent

  data_type: NUMBER
  default_value: undef
  is_nullable: 1
  size: 38

=head2 key

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 name

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 type

  data_type: VARCHAR2
  default_value: approval
  is_nullable: 1
  size: 100

=head2 id_wiki

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: 126

=head2 id_job

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: 126

=head2 data

  data_type: CLOB
  default_value: undef
  is_nullable: 1
  size: 2147483647

=head2 callback

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 1024

=head2 id_message

  data_type: NUMBER
  default_value: undef
  is_nullable: 1
  size: 126

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
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "bl",
  { data_type => "VARCHAR2", default_value => "*", is_nullable => 1, size => 50 },
  "requested_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "finished_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => "pending",
    is_nullable => 1,
    size => 50,
  },
  "finished_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "requested_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "action",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "id_parent",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
  "key",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => "approval",
    is_nullable => 1,
    size => 100,
  },
  "item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_wiki",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 126,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 126,
  },
  "data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "callback",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_message",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "projects",
  "Baseliner::Schema::Baseliner::Result::BaliProjectItems",
  { "foreign.ns" => "self.ns" },
);

use Baseliner::Utils;

sub data_hash {
	my $self = shift;
	my $data = $self->data;
	return {} unless $data;
	return _load( $data );
}

1;
