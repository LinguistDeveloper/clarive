use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesAdmin;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_categories_admin");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_category_admin_seq",
    size => 126,
  },
  "id_category", { data_type => "numeric", is_nullable => 0, size => 126, },
  "id_role", { data_type => "numeric", is_nullable => 0, size => 126, },  
  "id_status_from", { data_type => "numeric", is_nullable => 0, size => 126, },  
  "id_status_to", { data_type => "numeric", is_nullable => 0, size => 126, },  
  "job_type", { data_type => "varchar2", is_nullable => 1, size=>255, default_value=>'none' },  
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "roles",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { "foreign.id" => "self.id_role" },
  { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

__PACKAGE__->belongs_to(
  "statuses_from",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { id => "id_status_from" },
  { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

__PACKAGE__->belongs_to(
  "statuses_to",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { id => "id_status_to" },
  { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

__PACKAGE__->belongs_to(
  "category_statuses_from",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesStatus",
  { id_status => "id_status_from", id_category => "id_category" },
  { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

__PACKAGE__->belongs_to(
  "category_statuses_to",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesStatus",
  { id_status => "id_status_to", id_category => "id_category" },
  { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

__PACKAGE__->has_many(
  "user_role",
  "Baseliner::Schema::Baseliner::Result::BaliRoleuser",
  { "foreign.id_role" => "self.id_role" },
);

1;
