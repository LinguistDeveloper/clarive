package Baseliner::Schema::Baseliner::Result::BaliSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliSession

=cut

__PACKAGE__->table("bali_session");

=head1 ACCESSORS

=head2 id

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 0
  size: 72

=head2 session_data

  data_type: CLOB
  default_value: undef
  is_nullable: 1
  size: 2147483647

=head2 expires

  data_type: NUMBER
  default_value: undef
  is_nullable: 1
  size: 126

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 72,
  },
  "session_data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "expires",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-07-13 19:15:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pjTL/52SYbsjvSeprfDIYQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
