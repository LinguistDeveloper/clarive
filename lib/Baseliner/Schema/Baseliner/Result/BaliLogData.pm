package Baseliner::Schema::Baseliner::Result::BaliLogData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliLogData

=cut

__PACKAGE__->table("bali_log_data");

=head1 ACCESSORS

=head2 id

  data_type: NUMBER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 38

=head2 id_log

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 38

=head2 data

  data_type: BLOB
  default_value: undef
  is_nullable: 1
  size: 2147483647

=head2 timestamp

  data_type: DATE
  default_value: SYSDATE
  is_nullable: 1
  size: 19

=head2 name

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 2048

=head2 type

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 len

  data_type: NUMBER
  default_value: undef
  is_nullable: 1
  size: 38

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
  "id_log",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "data",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "timestamp",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "len",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_log

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliLog>

=cut

__PACKAGE__->belongs_to(
  "id_log",
  "Baseliner::Schema::Baseliner::Result::BaliLog",
  { id => "id_log" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-21 12:59:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1nz7qakwYqymKkL0F7jQJA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
