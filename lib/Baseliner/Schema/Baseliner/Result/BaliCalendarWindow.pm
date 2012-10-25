package Baseliner::Schema::Baseliner::Result::BaliCalendarWindow;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_calendar_window");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    is_nullable => 0,
    is_auto_increment => 1,
  },
  "start_time",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "end_time",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "day",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "active",
  {
    data_type => "VARCHAR2",
    default_value => "1",
    is_nullable => 1,
    size => 1,
  },
  "id_cal",
  {
    data_type => "NUMBER",
    default_value => 1,
    is_nullable => 0,
  },
  "start_date",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "end_date",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "calendar",
  "Baseliner::Schema::Baseliner::Result::BaliCalendar",
  { id => "id_cal" },
);

1;
