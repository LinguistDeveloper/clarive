package Baseliner::Schema::Baseliner::Result::BaliFileDist;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_file_dist");
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
  "filter",
  {
    data_type => "VARCHAR2",
    default_value => '*.*',
    is_nullable => 1,
    size => 1024,
  },
  "isrecursive",
  {
    data_type => "NUMBER",
    default_value => 0,
    is_nullable => 1,
    size => 1,
  },
  "src_dir",
  {
    data_type => "VARCHAR2",
    default_value => '.',
    is_nullable => 0,
    size => 1024,
  },
  "dest_dir",
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
  "xtype",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "sys",
  {
    data_type => "VARCHAR2",
    default_value => 'AIX',
    is_nullable => 0,
    size => 20,
  },  
  "exclussions",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_scripts_in_file_dists",
  "Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist",
  { "foreign.file_dist_id" => "self.id" },
);

1;
