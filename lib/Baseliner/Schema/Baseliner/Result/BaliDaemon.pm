package Baseliner::Schema::Baseliner::Result::BaliDaemon;

use strict;
use warnings;
use Baseliner::Utils;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table("bali_daemon");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
    is_auto_increment => 1
  },
  "service",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "active",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "config",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "pid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "params",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "hostname",
  {
    data_type => "VARCHAR2",
    default_value => 'localhost',
    is_nullable => 1,
    size => 255,
  },
  "last_ping",
  {
    data_type     => "datetime",
    is_nullable   => 1,
    set_on_create => 1, 
    set_on_update => 1,
    timezone => Util->_tz,
  },
);
__PACKAGE__->set_primary_key("id");

1;
