package Baseliner::Schema::Baseliner::Result::BaliSession;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_session");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 72,
  },
  "session_data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "expires",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");

1;
