use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesStatus;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_categories_status");
__PACKAGE__->add_columns(
  "id_category",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },
  "id_status",
  {
    data_type => "number",
    is_nullable => 0,
    size => 126,
  },

);

__PACKAGE__->set_primary_key("id_status", "id_category");
__PACKAGE__->belongs_to(
  "status",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { id => "id_status" },
);
__PACKAGE__->belongs_to(
  "category",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategories",
  { id => "id_category" },
);

1;
