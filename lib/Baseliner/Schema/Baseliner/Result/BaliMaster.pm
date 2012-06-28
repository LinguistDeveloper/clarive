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
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_master_seq",
  },
  "collection",
  { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "ts",
  {
    data_type     => "datetime",
    default_value => \"SYSDATE",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "username",
  { data_type => "varchar2", default_value=>'html', size => 1024, is_nullable=>1 },
  "yaml",
  { data_type => "clob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("mid");

1;


