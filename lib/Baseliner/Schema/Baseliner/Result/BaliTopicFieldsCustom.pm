use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicFieldsCustom;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopicFieldsCustom

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_fields_custom");

__PACKAGE__->add_columns(
  "topic_mid",
  {
    data_type => "numeric",
    is_nullable => 0,
  },
  "name",
  {
    data_type => "varchar2",
    size => 1024,
    is_nullable => 0,
  },
  "value",
  {
    data_type => "varchar2",
    size => 2048,
    is_nullable => 1,
  },
  "value_clob",
  { data_type => "clob", is_nullable => 1 },  
);

__PACKAGE__->set_primary_key("topic_mid", "name");


__PACKAGE__->belongs_to(
  "topics",
  "Baseliner::Schema::Baseliner::Result::BaliTopic",
  { 'foreign.mid' => 'self.topic_mid' },
);

1;
