use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicStatus;
use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_status");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_topic_status_seq",
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "type",
  { data_type => "varchar2", is_nullable => 1, size => 2 },
  "seq",
  { data_type => "number", is_nullable => 1, default_value=>1 },
  "bl",
  { data_type => "varchar2", is_nullable => 0, size => 1024, default_value=>'*' },
  "bind_releases",
  { data_type => "char", is_nullable => 0, size => 1, default_value=>'0' },
  "frozen",
  { data_type => "char", is_nullable => 0, size => 1, default_value=>'0' },
  "readonly",
  { data_type => "char", is_nullable => 0, size => 1, default_value=>'0' },
  "ci_update",
  { data_type => "char", is_nullable => 0, size => 1, default_value=>'0' },
);
__PACKAGE__->set_primary_key("id");

sub name_with_bl {
    my ($self)=@_;
    $self->bl eq '*' 
        ? $self->name
        : sprintf '%s [%s]', $self->name, $self->bl;
}

__PACKAGE__->has_many(
  "statuses_to",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesAdmin",
  { "foreign.id_status_from" => 'self.id' },
);

__PACKAGE__->has_many(
  "categories_status",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesStatus",
  { 'foreign.id_status' => "self.id" },
 
);

1;
