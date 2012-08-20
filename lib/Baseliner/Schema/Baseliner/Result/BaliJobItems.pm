package Baseliner::Schema::Baseliner::Result::BaliJobItems;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliJobItems

=cut

__PACKAGE__->table("bali_job_items");

=head1 ACCESSORS

=head2 id

  data_type: NUMBER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 38

=head2 data

  data_type: CLOB
  default_value: undef
  is_nullable: 1
  size: 2147483647

=head2 item

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 1024

=head2 provider

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 1024

=head2 id_job

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 38

=head2 service

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 application

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 1024

=head2 rfc

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 1024

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
  "data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "provider",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "service",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "application",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "rfc",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_job

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJob>

=cut

__PACKAGE__->belongs_to(
  "id_job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-07 11:18:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cLKOTBUa+hUPpYj6o42Czg

__PACKAGE__->belongs_to(
  "id_job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);

1;
