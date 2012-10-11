use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesPriority;

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_topic_categories_priority");

__PACKAGE__->add_columns(
  "id_category",
  {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "id_priority",
  {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },  
  "response_time_min",
  { data_type => "number", is_nullable => 1, size => 126 },
  "deadline_min",
  { data_type => "number", is_nullable => 1, size => 126 },
  "expr_response_time",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "expr_deadline",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "is_active",
  { data_type => "char", is_nullable => 1, size => 1 },    
);

__PACKAGE__->set_primary_key("id_category", "id_priority");

__PACKAGE__->belongs_to(
  "priority",
  "Baseliner::Schema::Baseliner::Result::BaliTopicPriority",
  { id => "id_priority" },
);

1;
