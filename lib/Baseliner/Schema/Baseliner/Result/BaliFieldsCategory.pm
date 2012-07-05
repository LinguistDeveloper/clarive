use utf8;
package Baseliner::Schema::Baseliner::Result::BaliFieldsCategory;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliFieldsCategory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_fields_category");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "numeric",
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 256 },
);


__PACKAGE__->set_primary_key("id");


1;
