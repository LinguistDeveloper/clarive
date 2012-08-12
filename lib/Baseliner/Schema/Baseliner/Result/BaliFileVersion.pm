use utf8;
package Baseliner::Schema::Baseliner::Result::BaliFileVersion;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliFile;

=head1 DESCRIPTION

A File is an attached uploaded file.

This table is integrated with the Master system.

=cut


use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_file_version");

__PACKAGE__->add_columns(
  "mid", {
    data_type => "number",
    is_nullable => 0,
    original => { data_type => "number" },
  },
  "filedata", { data_type => "blob", is_nullable => 0 },   
  "filename", { data_type => "varchar2", is_nullable => 0, size => 2048 },
  "filesize", { data_type => "number", default_value=>0 },
  "md5", { data_type => "varchar2", size=>1024 },
  "versionid", { data_type => "varchar2", is_nullable => 0, size => 255 },
  "extension", { data_type => "varchar2", default_value=>'', size => 255, is_nullable=>1 },
  "created_on", {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_by",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);

__PACKAGE__->set_primary_key("mid");

__PACKAGE__->has_many(
  "file_projects",
  "Baseliner::Schema::Baseliner::Result::BaliProjectDirectoriesFiles",
  { "foreign.id_file" => "self.mid" },
);

1;

