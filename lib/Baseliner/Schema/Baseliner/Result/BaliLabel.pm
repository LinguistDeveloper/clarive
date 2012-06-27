use utf8;
package Baseliner::Schema::Baseliner::Result::BaliLabel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliLabel

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

=head1 TABLE: C<bali_label>

=cut

__PACKAGE__->table("bali_label");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_label_seq'
  size: 126

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 1024

=head2 color

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
    sequence => "bali_label_seq",
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "color",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A


=head2 bali_issuelabels

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliIssueLabel>

=cut

__PACKAGE__->has_many(
  "bali_topiclabel",
  "Baseliner::Schema::Baseliner::Result::BaliTopicLabel",
  { "foreign.id_label" => "self.id" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;