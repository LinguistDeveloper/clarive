use utf8;
package Baseliner::Schema::Baseliner::Result::BaliProjectDirectories;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliProjectDirectories

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

=head1 TABLE: C<BaliProjectDirectories>

=cut

__PACKAGE__->table("bali_project_directories");

=head1 ACCESSORS

=head2 id

  data_type: 'number'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_project_directories_seq'
  size: 126

=head2 id_project

  data_type: 'number'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 id_parent

  data_type: 'number'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126
=cut



__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_nullable => 0,
    is_auto_increment => 1,       
    original => { data_type => "number" },
    size => 126,
  },
  "id_project",
  {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },  
  "id_parent",
  {
    data_type => "number",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "name",
  {
    data_type => "VARCHAR2",
    is_nullable => 0,
    size => 256,
  },  
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
