package Baseliner::Schema::Baseliner::Result::BaliScheduler;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_scheduler");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_scheduler_seq",
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "service",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "parameters",
  { data_type => "clob", is_nullable => 1 },
  "next_exec",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "last_exec",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "frequency",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "workdays",
  {
    data_type => "number",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "status",
  {
    data_type => "varchar2",
    default_value => "IDLE",
    is_nullable => 1,
    size => 20,
  },
  "pid",
  {
    data_type => "number",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },

);
__PACKAGE__->set_primary_key("id");

1;
