package Baseliner::Schema::Harvest::Result::BdeBtsNet;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bde_bts_net");
__PACKAGE__->add_columns(
  "bts_env",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "bts_usa_net",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-28 13:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gDg7r2QJ6T5sot6GE7SqIQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
