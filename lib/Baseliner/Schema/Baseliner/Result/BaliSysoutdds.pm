package Baseliner::Schema::Baseliner::Result::BaliSysoutdds;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliSysoutdd

=cut

__PACKAGE__->table("bali_sysoutdds");

=head1 ACCESSORS

=head2 dd_order

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 dd_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 dd_string

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_sysoutdds_seq'
  size: 126

=head2 dd_step

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "dd_order",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "dd_name",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "dd_string",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_sysoutdds_seq",
    size => 126,
  },
  "dd_step",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-29 18:31:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sJ0hW5MS76SHfXdh3sTiig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
