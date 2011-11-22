package Baseliner::Schema::Baseliner::Result::BaliUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliUser

=cut

__PACKAGE__->table("bali_user");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_user_seq'
  size: 126

=head2 username

  data_type: 'varchar2'
  is_nullable: 0
  size: 45

=head2 password

  data_type: 'varchar2'
  is_nullable: 0
  size: 45

=head2 realname

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 avatar

  data_type: 'blob'
  is_nullable: 1

=head2 alias

  data_type: 'varchar2'
  is_nullable: 1
  size: 512

=head2 data

  data_type: 'clob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    #sequence => "bali_user_seq",
    size => 126,
  },
  "username",
  { data_type => "varchar2", is_nullable => 0, size => 45 },
  "password",
  { data_type => "varchar2", is_nullable => 0, size => 45 },
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
  { data_type => "varchar2", is_nullable => 1, size => 10 },  
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "roles",
  "Baseliner::Schema::Baseliner::Result::BaliRoleuser",
  { 'foreign.username' => "self.username" },
);

1;
