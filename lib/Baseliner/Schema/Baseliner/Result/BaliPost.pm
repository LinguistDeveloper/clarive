use utf8;
package Baseliner::Schema::Baseliner::Result::BaliPost;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliPost;

=head1 DESCRIPTION

A Post is a comment, code snipet, knowledge-base info, wiki page, etc.

This table is integrated with the Master system.

=cut


use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_post");

__PACKAGE__->add_columns(
  "mid",
  {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
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
  "content_type",
  { data_type => "varchar2", default_value=>'html', size => 255 },
);

__PACKAGE__->set_primary_key("mid");


1;
