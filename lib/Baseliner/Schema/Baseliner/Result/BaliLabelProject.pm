use utf8;
package Baseliner::Schema::Baseliner::Result::BaliLabelProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliLabelProject

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

=head1 TABLE: C<bali_label_Project>

=cut

__PACKAGE__->table("bali_label_project");


__PACKAGE__->add_columns(
  "id_label",
  { data_type => "number", is_nullable => 0, size => 126 },
  "mid_project",
  { data_type => "number", is_nullable => 0, size => 126 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key( "id_label", "mid_project" );


# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A


=head2 bali_issuelabels

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliIssueLabel>

=cut



# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;