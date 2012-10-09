package Baseliner::Schema::Baseliner::Result::BaliCalendar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_calendar");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 1, 
    size => 126,
  },
  "name",
  {
    data_type => "varchar2",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "ns",
  {
    data_type => "varchar2",
    default_value => "/",
    is_nullable => 0,
    size => 100,
  },
  "bl",
  {
    data_type => "varchar2",
    default_value => "*",
    is_nullable => 0,
    size => 100,
  },
  "description",
  {
    data_type => "varchar2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "type",
  {
    data_type => "varchar2",
    default_value => 'HI',
    is_nullable => 1,
    size => 2,
  },  
  "active",
  {
    data_type => "varchar2",
    default_value => '1',
    is_nullable => 1,
    size => 1,
  },  
  "seq",
  {
    data_type => "number",
    is_nullable => 1,
    default_value => 100,
  },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "windows",
  "Baseliner::Schema::Baseliner::Result::BaliCalendarWindow",
  { "foreign.id_cal" => "self.id" },
);

1;
