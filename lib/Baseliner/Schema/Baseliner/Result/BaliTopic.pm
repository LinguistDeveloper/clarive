use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopic;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopic

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic");

__PACKAGE__->add_columns(
  "mid",
  {
    data_type => "numeric",
    is_nullable => 0,
  },
  "id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_seq",
    size => 126,
  },
  "title",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "description",
  { data_type => "clob", is_nullable => 0 },
  "created_on",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_by",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "status",
  { data_type => "char", default_value => "O", is_nullable => 0, size => 1 },
  "id_category",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },
  "id_category_status",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },  
  "id_priority",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "response_time_min",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "deadline_min",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "expr_response_time",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "expr_deadline",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_one(
  "categories",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategories",
  { "foreign.id" => "self.id_category" },
);

__PACKAGE__->has_many(
  "projects",
  "Baseliner::Schema::Baseliner::Result::BaliTopicProject",
  { "foreign.id_topic" => "self.id" },
);

__PACKAGE__->has_one(
  "status",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { "foreign.id" => "self.id_category_status" },
);

__PACKAGE__->has_many(
    'children' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
    { 'foreign.from_mid' => 'self.mid' }
);
__PACKAGE__->has_many(
    'parents' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
    { 'foreign.to_mid' => 'self.mid' }
);
#__PACKAGE__->many_to_many('posts' => 'master_rel', 'address');

__PACKAGE__->has_one(
  "master",
  "Baseliner::Schema::Baseliner::Result::BaliMaster",
  { "foreign.mid" => "self.mid" },
);

1;
