package Baseliner::Schema::Harvest::Result::Harenvironmentaccess;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("harenvironmentaccess");
__PACKAGE__->add_columns(
  "envobjid",
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
  "secureaccess",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
  "updateaccess",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
  "viewaccess",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
  "executeaccess",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("envobjid", "usrgrpobjid");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-02 12:09:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3kkpQk+gQOYTnM4YDqXueQ


__PACKAGE__->has_many(
  "users",
  "Baseliner::Schema::Harvest::Result::Harusersingroup",
  { "foreign.usrgrpobjid" => "self.usrgrpobjid" },
);

__PACKAGE__->belongs_to(
  "harenvironment",
  "Baseliner::Schema::Harvest::Result::Harenvironment",
  { envobjid => "envobjid" },
);

1;
