package Baseliner::Schema::Baseliner::Result::BaliUser;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_user");

__PACKAGE__->add_columns(
  "mid", {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
  },  
  "username",
  { data_type => "varchar2", is_nullable => 0, size => 45 },
  "password",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "realname",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "avatar",
  { data_type => "blob", is_nullable => 1 },
  "data",
  { data_type => "clob", is_nullable => 1 },
  "alias",
  { data_type => "varchar2", is_nullable => 1, size => 512 },
  "email",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "phone",
  { data_type => "varchar2", is_nullable => 1, size => 25 },
  "api_key",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "active",
  { data_type => "char", is_nullable => 1, size => 1, default_value => 1 },  
);
__PACKAGE__->set_primary_key("mid");

__PACKAGE__->has_many(
  "roles",
  "Baseliner::Schema::Baseliner::Result::BaliRoleuser",
  { 'foreign.username' => "self.username" },
);

__PACKAGE__->add_unique_constraint(
  username => [ qw/username/ ],
);

sub id { $_[0]->mid; }   # for backwards compatibility

__PACKAGE__->load_components("+Baseliner::Schema::Master");
__PACKAGE__->has_master;

1;
