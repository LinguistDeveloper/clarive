package Baseliner::Schema::Baseliner::Result::BaliSshScript;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_ssh_script");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => '/',
    is_nullable => 0,
    size => 1000,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => '*',
    is_nullable => 0,
    size => 100,
  },
  "script",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "params",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "ssh_host",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "xorder",
  {
    data_type => "NUMBER",
    default_value => 1,
    is_nullable => 1,
    size => 1,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => 'POST',
    is_nullable => 1,
    size => 4,
  },  
  "xtype",
  {
    data_type => "VARCHAR2",
    default_value => '*',
    is_nullable => 1,
    size => 16,
  },  
);
__PACKAGE__->sequence("bali_ssh_script_seq");
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_scripts_in_file_dists",
  "Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist",
  { "foreign.script_id" => "self.id" },
);

1;
