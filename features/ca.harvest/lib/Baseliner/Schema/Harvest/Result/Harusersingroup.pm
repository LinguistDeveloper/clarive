package Baseliner::Schema::Harvest::Result::Harusersingroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("harusersingroup");
__PACKAGE__->add_columns(
  "usrobjid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "usrgrpobjid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("usrobjid", "usrgrpobjid");
__PACKAGE__->belongs_to(
  "usrobjid",
  "Baseliner::Schema::Harvest::Result::Haruser",
  { usrobjid => "usrobjid" },
);
__PACKAGE__->belongs_to(
  "usrgrpobjid",
  "Baseliner::Schema::Harvest::Result::Harusergroup",
  { usrgrpobjid => "usrgrpobjid" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-02 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z0sBWN9Cvh3krWla5Ba8Pw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
