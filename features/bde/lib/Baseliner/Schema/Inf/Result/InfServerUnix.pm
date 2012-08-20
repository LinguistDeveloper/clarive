package Baseliner::Schema::Inf::Result::InfServerUnix;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_server_unix");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "server",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 40,
  },
  "version",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "webserver",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
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
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "script",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "dummy",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "harax_port",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "oid",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "dummy2",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "version_was",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "version_web",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "version_jdk",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "server_cluster",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "desplegar_flag",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "numero_bits",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "servidor_gpfs",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kkVXmZCF1cRebJaPyREPxw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
