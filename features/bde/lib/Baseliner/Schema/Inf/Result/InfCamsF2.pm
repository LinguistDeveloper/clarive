package Baseliner::Schema::Inf::Result::InfCamsF2;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_cams_f2");
__PACKAGE__->add_columns(
  "cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 3,
  },
);
__PACKAGE__->set_primary_key("cam");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:14:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U9mCdqKvcFTKbqum+/i/xg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
