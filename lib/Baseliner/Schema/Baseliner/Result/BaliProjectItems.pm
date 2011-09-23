package Baseliner::Schema::Baseliner::Result::BaliProjectItems;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliProjectItems

=cut

__PACKAGE__->table("bali_project_items");

=head1 ACCESSORS

=head2 id

  is_auto_increment: 1
  is_nullable: 0
  sequence: 'bali_project_items_seq'

=head2 id_project

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 ns

  data_type: 'varchar2'
  is_nullable: 1
  size: 1024

=cut

__PACKAGE__->add_columns(
  "id",
  {
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_project_items_seq",
  },
  "id_project",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "ns",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_project

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliProject>

=cut

__PACKAGE__->belongs_to(
  "id_project",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { id => "id_project" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-03-15 13:45:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fXYKWgIi/KsJ/6oPa+FKRQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
