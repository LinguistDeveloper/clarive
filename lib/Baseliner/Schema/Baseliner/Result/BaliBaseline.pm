package Baseliner::Schema::Baseliner::Result::BaliBaseline;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_baseline");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 1, 
    size => 126,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "seq",
  { 
    data_type     => "number",
    is_nullable   => 1,
  },  
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->load_components("+Baseliner::Schema::Master");
__PACKAGE__->has_master;

1;
