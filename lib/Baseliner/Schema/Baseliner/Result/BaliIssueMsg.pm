use utf8;
package Baseliner::Schema::Baseliner::Result::BaliIssueMsg;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliIssueMsg

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<bali_issue_msg>

=cut

__PACKAGE__->table("bali_issue_msg");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'bali_issue_msg_seq'
  size: 126

=head2 id_issue

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 text

  data_type: 'clob'
  is_nullable: 0

=head2 created_on

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0
  original: {data_type => "date",default_value => \"sysdate"}

=head2 created_by

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "bali_issue_msg_seq",
    size => 126,
  },
  "id_issue",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "text",
  { data_type => "clob", is_nullable => 0 },
  "created_on",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_by",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-23 09:45:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9WdBbElGrb2cadu363V6yA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
