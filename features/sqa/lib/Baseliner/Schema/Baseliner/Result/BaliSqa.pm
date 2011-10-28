package Baseliner::Schema::Baseliner::Result::BaliSqa;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliSqa

=cut

__PACKAGE__->table("bali_sqa");

=head1 ACCESSORS

=head2 id

  is_auto_increment: 1
  is_nullable: 0
  sequence: 'bali_sqa_seq'

=head2 ns

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 bl

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 id_prj

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 nature

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 qualification

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 status

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 data

  data_type: 'clob'
  is_nullable: 1

=head2 tsstart

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=head2 tsend

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 type

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=cut

__PACKAGE__->add_columns(
  "id",
  { is_auto_increment => 1, is_nullable => 0, sequence => "bali_sqa_seq" },
  "ns",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "bl",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "id_prj",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "nature",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "qualification",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "status",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "data",
  { data_type => "clob", is_nullable => 1 },
  "tsstart",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "tsend",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "type",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "username",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "job",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
   "pid",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "path",
  { data_type => "varchar2", is_nullable => 1, size => 1024 }  
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-05-27 11:52:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z3+9Tx4owe7ccn4cj601IA

__PACKAGE__->belongs_to(
  "project",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { id => "id_prj" },
);
1;
