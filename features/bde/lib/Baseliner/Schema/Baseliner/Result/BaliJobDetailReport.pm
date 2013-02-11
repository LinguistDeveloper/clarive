package Baseliner::Schema::Baseliner::Result::BaliJobDetailReport;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_job_detail_report");

__PACKAGE__->add_columns(
  'id', {data_type => 'integer', is_nullable => 0, is_auto_increment => 1, sequence => 'bali_job_detail_report_seq'},
  'job_name', {data_type => 'varchar2', is_nullable => 0, size => 50},
  'package_name', {data_type => 'varchar2', is_nullable => 0, size => 255},
  'type', {data_type => 'varchar2', is_nullable => 0, size => 50},
  'description', {data_type => 'varchar2', is_nullable => 0, size => 4000},
  'fecha', {data_type => "DATE", is_nullable => 1, size => 19},
  'cam', {data_type => 'char', is_nullable => 0, size => 3},
  'bl', {data_type => 'char', is_nullable => 0, size => 3},
  'statename', {data_type => 'varchar2', is_nullable => 0, size => 50},
  'technology', {data_type => 'varchar2', is_nullable => 0, size => 1024},
  'subappl', {data_type => 'varchar2', is_nullable => 1, size => 1024},
  'packagegroup', {data_type => 'varchar2', is_nullable => 1, size => 1024},
  'node', {data_type => 'varchar2', is_nullable => 1, size => 1024},
);

__PACKAGE__->set_primary_key('id');

1;
