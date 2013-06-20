use utf8;
package Baseliner::Schema::Baseliner::Result::BaliProjectDirectoriesFiles;

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

__PACKAGE__->table("bali_project_directories_files");

=head1 ACCESSORS

=head2 id_directory

  data_type: 'number'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 id_file

  data_type: 'number'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=cut



__PACKAGE__->add_columns(
  "id_directory",
  {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "id_file",
  {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },  
);

__PACKAGE__->set_primary_key("id_directory", "id_file");

__PACKAGE__->belongs_to(
  "directory",
  "Baseliner::Schema::Baseliner::Result::BaliProjectDirectories",
  { id => "id_directory" },
);

__PACKAGE__->belongs_to(
  "file_directory",
  "Baseliner::Schema::Baseliner::Result::BaliFileVersion",
  { mid => "id_file" },
);

__PACKAGE__->belongs_to(
  "topic",
  "Baseliner::Schema::Baseliner::Result::BaliTopic",
  { mid => "id_file" },
);


# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
