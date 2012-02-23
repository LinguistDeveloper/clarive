package Baseliner::Schema::Baseliner::Result::BaliProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliProject

=cut

__PACKAGE__->table("bali_project");

=head1 ACCESSORS

=head2 id

  is_auto_increment: 1
  is_nullable: 0
  sequence: 'bali_project_seq'

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 1024

=head2 data

  data_type: 'clob'
  is_nullable: 1

=head2 ns

  data_type: 'varchar2'
  default_value: '/'
  is_nullable: 1
  size: 1024

=head2 bl

  data_type: 'varchar2'
  default_value: '*'
  is_nullable: 1
  size: 1024

=head2 ts

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=head2 domain

  data_type: 'varchar2'
  is_nullable: 1
  size: 1

=head2 description

  data_type: 'clob'
  is_nullable: 1

=head2 id_parent

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 nature

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => 'integer',
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_project_seq",
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "data",
  { data_type => "clob", is_nullable => 1 },
  "ns",
  {
    data_type => "varchar2",
    default_value => "/",
    is_nullable => 1,
    size => 1024,
  },
  "bl",
  {
    data_type => "varchar2",
    default_value => "*",
    is_nullable => 1,
    size => 1024,
  },
  "ts",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "domain",
  { data_type => "varchar2", is_nullable => 1, size => 1 },
  "description",
  { data_type => "clob", is_nullable => 1 },
  "id_parent",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "nature",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "active",
  { data_type => "char", is_nullable => 1, size => 1, default => 1 },  
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 bali_project_items

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliProjectItems>

=cut

__PACKAGE__->has_many(
  "bali_project_items",
  "Baseliner::Schema::Baseliner::Result::BaliProjectItems",
  { "foreign.id_project" => "self.id" },
  {},
);

__PACKAGE__->belongs_to(
  "parent",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { id => "id_parent" },
);
# You can replace this text with custom content, and it will be preserved on regeneration
1;
