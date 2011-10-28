package Baseliner::Schema::Inf::Result::InfForm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_form");
__PACKAGE__->add_columns(
  "cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 3,
  },
  "idform",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "activo",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("idform");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:16:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c5oZqCAKsiUlfmbNXwGbBA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
