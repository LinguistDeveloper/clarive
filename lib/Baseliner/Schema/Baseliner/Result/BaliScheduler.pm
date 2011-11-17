package Baseliner::Schema::Baseliner::Result::BaliScheduler;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliScheduler

=cut

__PACKAGE__->table("bali_scheduler");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_scheduler_seq'
  size: 126

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 service

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 parameters

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 next_exec

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 last_exec

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=head2 frequency

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 workdays

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 status

  data_type: 'varchar2'
  default_value: 'IDLE'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_scheduler_seq",
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "service",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "parameters",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "next_exec",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "last_exec",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "frequency",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "workdays",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "status",
  {
    data_type => "varchar2",
    default_value => "IDLE",
    is_nullable => 1,
    size => 20,
  },
  "pid",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },

);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-13 13:46:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L7KmHacgbmsqi/jvbuL2oQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
