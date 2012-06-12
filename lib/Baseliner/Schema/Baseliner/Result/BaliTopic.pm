use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopic;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopic

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->load_components("+Baseliner::Schema::Master");
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

__PACKAGE__->belongs_to(
  "categories",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategories",
  { "id" => "id_category" },
);

__PACKAGE__->belongs_to(
  "status",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { "id" => "id_category_status" },
);

__PACKAGE__->master_setup( 'posts', ['topic','mid'] => ['post', 'BaliPost','mid'] );
__PACKAGE__->master_setup( 'files', ['topic','mid'] => ['file_version', 'BaliFileVersion','mid'] );
__PACKAGE__->master_setup( 'users', ['topic','mid'] => ['users', 'BaliUser','mid'] );
__PACKAGE__->master_setup( 'projects', ['topic','mid'] => ['project', 'BaliProject','mid'] );
__PACKAGE__->master_setup( 'topics', ['topic','mid'] => ['topic', 'BaliTopic','mid'] );

__PACKAGE__->belongs_to(
  "priorities",
  "Baseliner::Schema::Baseliner::Result::BaliTopicPriority",
  { id => "id_priority" },
);

1;
