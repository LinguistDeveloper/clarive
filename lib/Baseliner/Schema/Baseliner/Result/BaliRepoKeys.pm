package Baseliner::Schema::Baseliner::Result::BaliRepoKeys;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_repokeys");
__PACKAGE__->add_columns(
  "ns", { data_type => "VARCHAR2", default_value => undef, is_nullable => 0, size => 1024, },
  "ts", { data_type => "DATE", default_value => \"SYSDATE", is_nullable => 1, size => 19, },
  "bl", { data_type => "VARCHAR2", default_value => '*', is_nullable => 0, size => 255, },
  "version", { data_type => "NUMBER", default_value => 0, is_nullable => 0, size => 38 },
  "datatype", { data_type => "VARCHAR2", default_value => '', is_nullable => 1, size => 50, },
  "k", { data_type => "VARCHAR2", default_value => undef, is_nullable => 0, size => 255 },
  "v", { data_type => "CLOB", default_value => undef, is_nullable => 1 },
);
__PACKAGE__->set_primary_key(qw/ns bl k version/);

__PACKAGE__->belongs_to(
  "repo",
  "Baseliner::Schema::Baseliner::Result::BaliRepo",
  { "foreign.ns" => "self.ns" },
);

1;
