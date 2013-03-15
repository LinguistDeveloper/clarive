use utf8;
package Baseliner::Schema::Baseliner::Result::BaliNotification;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliNotification

=head1 DESCRIPTION

This is the new master-relationship table

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_notification");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "number",
    is_auto_increment => 1,
    is_nullable => 0,
    sequence => "bali_notification_seq",
  },
  "event_key",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "action",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "recipients",
  { data_type => "clob", is_nullable => 0 },
  "event_scope",
  { data_type => "clob", is_nullable => 0 },
  "is_active",
  { data_type => "char", is_nullable => 0, size => 1, default => '1' },
  "username",
  { data_type => "varchar2", is_nullable=>1, size => 1024 },
  "template_path",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "digest_time",
  { data_type => "varchar2", is_nullable=>1, size => 1024 },
  "digest_date",
  { data_type => "varchar2", is_nullable=>1, size => 1024 },
  "digest_freq",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
);

__PACKAGE__->set_primary_key("id");


1;

