use utf8;
package Baseliner::Schema::Baseliner::Result::BaliIssueProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliIssueProject

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

=head1 TABLE: C<bali_issue_project>

=cut

__PACKAGE__->table("bali_issue_project");

=head1 ACCESSORS

=head2 id_issue

  data_type: 'numeric'
  is_nullable: 0
  size: 126

=head2 id_project

  data_type: 'numeric'
  is_nullable: 0
  size: 126

=cut

__PACKAGE__->add_columns(
  "id_issue",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },
  "id_project",
  {
    data_type => "numeric",
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
  "project",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { id => "id_project" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;