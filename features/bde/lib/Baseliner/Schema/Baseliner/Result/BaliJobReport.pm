package Baseliner::Schema::Baseliner::Result::BaliJobReport;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_job_report");

__PACKAGE__->add_columns(
  'id', {data_type => 'integer', is_nullable => 0, is_auto_increment => 1, sequence => 'bali_job_report_seq'},
  'job_name', {data_type => 'varchar2', is_nullable => 0, size => 50},
  'project', {data_type => 'varchar2', is_nullable => 0, size => 3},
  'subapplication', {data_type => 'varchar2', is_nullable => 1, size => 20},
  'technology', {data_type => 'varchar2', is_nullable => 0, size => 20},
  'urgent', {data_type => 'integer', is_nullable => 0, default => 0},
  'year', {data_type => 'integer', is_nullable => 0},
  'quarter', {data_type => 'integer', is_nullable => 0},
  'month', {data_type => 'integer', is_nullable => 0},
  'day', {data_type => 'integer', is_nullable => 0},
  'start_time', {data_type => 'varchar2', is_nullable => 0, size => 20},
  'end_time', {data_type => 'varchar2', is_nullable => 0, size => 20},
  'duration', {data_type => 'integer', is_nullable => 0},
  'environment', {data_type => 'varchar2', is_nullable => 0, size => 20},
  'status', {data_type => 'varchar2', is_nullable => 0, size => 20},
  'month_str', {data_type => 'varchar2', is_nullable => 1, size => 20}
);

__PACKAGE__->set_primary_key('id');

1;