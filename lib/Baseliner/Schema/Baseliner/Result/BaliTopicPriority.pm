use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicPriority;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopicPriority

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

=head1 TABLE: C<bali_topic_priority>

=cut

__PACKAGE__->table("bali_topic_priority");

=head1 ACCESSORS

=head2 id

  data_type: 'number'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_topic_priority_seq'
  size: 126

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 response_time_min

  data_type: 'number'
  is_nullable: 1
  size: 126


=head2 deadline_min

  data_type: 'number'
  is_nullable: 1
  size: 126

=head2 expr_response_time

  data_type: 'varchar2'
  is_nullable: 0
  size: 255
=cut


=head2 expr_deadline

  data_type: 'varchar2'
  is_nullable: 0
  size: 255
=cut



__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_priority_seq",
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "response_time_min",
  { data_type => "number", is_nullable => 1, size => 126 },
  "deadline_min",
  { data_type => "number", is_nullable => 1, size => 126 },
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