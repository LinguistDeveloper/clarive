use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopic

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<bali_topic>

=cut

__PACKAGE__->table("bali_topic");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_topic_seq'
  size: 126

=head2 title

  data_type: 'varchar2'
  is_nullable: 0
  size: 1024

=head2 description

  data_type: 'clob'
  is_nullable: 0

=head2 created_on

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0
  original: {data_type => "date",default_value => \"sysdate"}

=head2 created_by

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 status

  data_type: 'char'
  default_value: 'O'
  is_nullable: 0
  size: 1

=head2 id_category

  data_type: 'numeric'
  default_value: 'O'
  is_nullable: 0
  size: 126
  
  
=head2 id_category_status

  data_type: 'numeric'
  default_value: 'O'
  is_nullable: 1
  size: 126
  
=head2 id_priority

  data_type: 'numeric'
  default_value: 'O'
  is_nullable: 1
  size: 126
  
=head2 response_time_min

  data_type: 'numeric'
  default_value: 'O'
  is_nullable: 1
  size: 126
  
=head2 deadline_time_min

  data_type: 'numeric'
  default_value: 'O'
  is_nullable: 1
  size: 126
  
=head2 expr_response_time

  data_type: 'varchar2'
  is_nullable: 1
  size: 255
  
=head2 expr_deadline

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

  
=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_seq",
    size => 126,
  },
  "title",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "description",
  { data_type => "clob", is_nullable => 0 },
  "created_on",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_by",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "status",
  { data_type => "char", default_value => "O", is_nullable => 0, size => 1 },
  "id_category",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },
  "id_category_status",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },  
  "id_priority",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "response_time_min",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "deadline_min",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "expr_response_time",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "expr_deadline",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
