use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicCategories;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_categories");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_categories_seq",
    size => 126,
  },
  "name", { data_type => "varchar2", is_nullable => 0, size => 255 },
  "description", { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "color", { data_type => "varchar2", is_nullable => 1, size => 255 },
  "forms", { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "is_changeset", { data_type => "char", is_nullable => 1, size => 1, default=>'0' },
  "is_release", { data_type => "char", is_nullable => 1, size => 1, default=>'0'},

);
__PACKAGE__->set_primary_key("id");
1;
