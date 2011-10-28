package Baseliner::Schema::Inf::Result::InfMetaView;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_meta_view");
__PACKAGE__->add_columns(
  "src_fld",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 9,
  },
  "src_val",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "dst_flds",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "dst_vals",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:16:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NcpioAU1YV0c1Xe6Pt8M4Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
