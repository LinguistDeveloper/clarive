package Baseliner::Schema::Baseliner::Result::BaliChainedRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliChainedRule

=cut

__PACKAGE__->table("bali_chained_rule");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 chain_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 seq

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 rename_me

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=head2 step

  data_type: 'varchar2'
  is_nullable: 0
  size: 10

=head2 dsl

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 dsl_code

  data_type: 'clob'
  is_nullable: 0

=head2 active

  data_type: 'char'
  default_value: NULL
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "chain_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "seq",
  {
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 0,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "step",
  { data_type => "varchar2", is_nullable => 0, size => 10 },
  "dsl",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "dsl_code",
  { data_type => "clob", is_nullable => 0 },
  "active",
  { data_type => "char", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("id");

1;
