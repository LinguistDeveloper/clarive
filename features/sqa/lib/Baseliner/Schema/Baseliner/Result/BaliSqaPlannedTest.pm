package Baseliner::Schema::Baseliner::Result::BaliSqaPlannedTest;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliSqaPlannedTest

=cut

__PACKAGE__->table("bali_sqa_planned_tests");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 project

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 subapl

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 nature

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 username

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 active

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 last_exec

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 comments

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "project",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "subapl",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "nature",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "username",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "active",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "last_exec",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "comments",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "scheduled",
  { data_type => "varchar2", is_nullable => 1, size => 5 },
  "bl",
  { data_type => "varchar2", is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id");

1;