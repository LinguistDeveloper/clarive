use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesAdmin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesAdmin

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

=head1 TABLE: C<bali_topic_categories_admin>

=cut

__PACKAGE__->table("bali_topic_categories_admin");

=head1 ACCESSORS

=head2 id

  data_type: 'number'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_topic_categories_seq'
  size: 126

=head2 id_category

  data_type: 'number'
  is_nullable: 0
  size: 126

=head2 id_rol

  data_type: 'number'
  is_nullable: 0
  size: 126

=head2 id_status_from

  data_type: 'number'
  is_nullable: 0
  size: 126

=head2 id_status_to

  data_type: 'number'
  is_nullable: 0
  size: 126


=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_category_admin_seq",
    size => 126,
  },
  "id_category",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },
  "id_role",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },  
  "id_status_from",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },  
  "id_status_to",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },  
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "roles",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);

__PACKAGE__->belongs_to(
  "statuses_from",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { id => "id_status_from" },
);

__PACKAGE__->belongs_to(
  "statuses_to",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { id => "id_status_to" },
);

# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
