use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicLabel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopicLabel

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

=head1 TABLE: C<bali_topic_label>

=cut

__PACKAGE__->table("bali_topic_label");

=head1 ACCESSORS

=head2 id_topic

  data_type: 'number'
  is_nullable: 0
  size: 126

=head2 id_label

  data_type: 'number'
  is_nullable: 0
  size: 126

=cut

__PACKAGE__->add_columns(
  "id_topic",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },
  "id_label",
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



# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A

__PACKAGE__->belongs_to(
  "label",
  "Baseliner::Schema::Baseliner::Result::BaliLabel",
  { id => "id_label" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;