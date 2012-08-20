package Baseliner::Schema::Harvest::Result::Harusergroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("harusergroup");
__PACKAGE__->add_columns(
  "usrgrpobjid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "usergroupname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "creationtime",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  "creatorid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "modifiedtime",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  "modifierid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "note",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "groupexternal",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("usrgrpobjid");
__PACKAGE__->has_many(
  "harusersingroups",
  "Baseliner::Schema::Harvest::Result::Harusersingroup",
  { "foreign.usrgrpobjid" => "self.usrgrpobjid" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-02 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OoY8vM5mw5tisTujmFdRDA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
