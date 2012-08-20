package Baseliner::Schema::Inf::Result::InfEpoch;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_epoch");
__PACKAGE__->add_columns(
  "epoch",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:15:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FoLNIIUZmufDrDNPCdZhsg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
