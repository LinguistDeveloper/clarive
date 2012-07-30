use utf8;
package Baseliner::Schema::Baseliner::Result::BaliMaster;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_master");

__PACKAGE__->add_columns(
  "mid",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_master_seq",
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "bl",
  { data_type => "varchar2", is_nullable => 0, size => 1024, default_value=>'*' },
  "collection",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "ts",
  {
    data_type     => "datetime",
    default_value => \"SYSDATE",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "versionid", { data_type => "varchar2", is_nullable => 0, size => 255, default_value=>'1' },
  "username",
  { data_type => "varchar2", default_value=>'html', size => 1024, is_nullable=>1 },
  "yaml",
  { data_type => "clob", is_nullable => 1 },
  # ns is here so that foreign objects may keep a unique key and avoid having 2 CIs for the same thing
  "ns",
  { data_type => "varchar2", default_value=>'', size => 2048, is_nullable=>1 },
  "active", { data_type => "char", size => 1, default_value=>'1' },
);

__PACKAGE__->set_primary_key("mid");

1;


