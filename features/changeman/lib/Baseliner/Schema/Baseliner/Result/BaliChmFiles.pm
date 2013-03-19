use utf8;
package Baseliner::Schema::Baseliner::Result::BaliChmFiles;

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
__PACKAGE__->table("bali_chm_files");

__PACKAGE__->add_columns(
  "filename", { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "ts", { data_type => "datetime", default_value => \"current_timestamp", is_nullable   => 0, original => { data_type => "date", default_value => \"sysdate" }, },
  "jobid", { data_type => "number" },
  "username", { data_type => "char", size=>8},
  "key", { data_type => "varchar2", is_nullable => 0, size => 15 },
  "complete_filename", { data_type => "varchar2", is_nullable => 0, size => 2048 },
);

__PACKAGE__->set_primary_key("filename", "ts");

__PACKAGE__->belongs_to(
  "job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => 'jobid' }, {join_type => 'LEFT'}
);

1;

