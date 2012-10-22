use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicImage;
use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_image");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_topic_image_seq",
  },
  "topic_mid",
  { data_type => "number", is_nullable => 1 },
  "id_hash",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "content_type",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "img_format",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "img_size",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "img_data",
  { data_type => "blob", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "topic",
  "Baseliner::Schema::Baseliner::Result::BaliTopic",
  { "mid" => "topic_mid" },
  { cascade_delete => 1, on_delete=>'cascade', is_foreign_key_constraint=>1, },
);

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_topicimg_idhash_ix', fields=>['id_hash'] );
}

1;

