package Baseliner::Schema::Harvest::Result::BdePaqueteOracleOwner;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bde_paquete_oracle_owner");
__PACKAGE__->add_columns(
  "ora_prj",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "ora_campo_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "ora_campo_value",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-28 13:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jty6qEoWST72jfcrCn5Xbg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
