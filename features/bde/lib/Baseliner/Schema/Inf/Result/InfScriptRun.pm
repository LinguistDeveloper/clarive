package Baseliner::Schema::Inf::Result::InfScriptRun;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_script_run");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "idscript",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "idpeticion",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "idtask",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "maq",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "maqusu",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "estado",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "rc",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "inicio",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "fin",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "iniciado_por",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "param",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "logtxt",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "idscript",
  "Baseliner::Schema::Inf::Result::InfScript",
  { id => "idscript" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nOcJ3Z+mA9nJClQlVhISlQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
