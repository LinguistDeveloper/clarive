package Baseliner::Schema::Inf::Result::InfQueueManager;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_queue_manager");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 8,
  },
  "descr",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "created_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "created_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "updated_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "updated_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "status_flag",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 1 },
  "oid",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "dummy",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "dummy2",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "net",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:18:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H7x0yWA4JJB0yrZmcvdqmg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
