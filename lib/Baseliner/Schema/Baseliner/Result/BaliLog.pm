package Baseliner::Schema::Baseliner::Result::BaliLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliLog

=cut

__PACKAGE__->table("bali_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 38,
  },
  "text",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "lev",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "more",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "timestamp",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => "/",
    is_nullable => 1,
    size => 255,
  },
  "provider",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "data",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "data_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "data_length",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 38 },
  "module",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "section",
  {
    data_type => "VARCHAR2",
    default_value => "general",
    is_nullable => 1,
    size => 255,
  },
  "step",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "exec",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "prefix",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "milestone",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "service_key",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 bali_log_datas

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliLogData>

=cut

__PACKAGE__->has_many(
  "bali_log_datas",
  "Baseliner::Schema::Baseliner::Result::BaliLogData",
  { "foreign.id_log" => "self.id" },
);

__PACKAGE__->belongs_to(
  "job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);

1;

