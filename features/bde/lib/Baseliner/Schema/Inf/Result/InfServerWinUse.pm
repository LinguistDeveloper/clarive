package Baseliner::Schema::Inf::Result::InfServerWinUse;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_server_win_use");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "use",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:19:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:17CYD0zOt4diw8ZfoXxQng


# You can replace this text with custom content, and it will be preserved on regeneration
1;
