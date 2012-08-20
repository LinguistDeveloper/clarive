use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicFieldsCategory;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopicFieldsCategory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_fields_category");

__PACKAGE__->add_columns(
  "id_category",
  {
    data_type => "numeric",
    is_nullable => 0,
  },
  "id_field",
  {
    data_type => "numeric",
    is_nullable => 0,
  },
);

__PACKAGE__->belongs_to(
  "fields",
  "Baseliner::Schema::Baseliner::Result::BaliFieldsCategory",
  { id => "id_field" },
);

1;
