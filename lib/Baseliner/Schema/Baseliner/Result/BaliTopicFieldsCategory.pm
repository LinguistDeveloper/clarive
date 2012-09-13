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
    data_type => "varchar2",
    size => 1024,
    is_nullable => 0,
  },
  "params_field",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },  
);

__PACKAGE__->set_primary_key("id_category", "id_field");


1;
