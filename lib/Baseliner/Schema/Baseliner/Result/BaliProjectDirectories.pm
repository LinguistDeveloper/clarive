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

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_project_directories");


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


__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "files",
  "Baseliner::Schema::Baseliner::Result::BaliProjectDirectoriesFiles",
  { "foreign.id_directory" => "self.id" },
);

1;
