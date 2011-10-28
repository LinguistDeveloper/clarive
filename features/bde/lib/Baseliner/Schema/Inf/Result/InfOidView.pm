package Baseliner::Schema::Inf::Result::InfOidView;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_oid_view");
__PACKAGE__->add_columns(
  "oid",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "oname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:10:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kqDmC45BOpRVw667dYoHjw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
