package Baseliner::Schema::Inf::Result::InfFormAla;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_form_ala");
__PACKAGE__->add_columns(
  "cam",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 3,
  },
  "idform",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "activo",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-03-21 13:16:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z9JAkzaN9JuLHqXb2C6/pg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
