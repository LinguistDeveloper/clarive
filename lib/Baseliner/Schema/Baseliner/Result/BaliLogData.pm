package Baseliner::Schema::Baseliner::Result::BaliLogData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliLogData

=cut

__PACKAGE__->table("bali_log_data");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 38,
  },
  "id_log",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "data",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "timestamp",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "len",
  { 
    data_type => "NUMBER", 
    default_value => undef, 
    is_nullable => 1, 
    size => 38 
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 38,
  },
  "path",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_log

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliLog>

=cut

__PACKAGE__->belongs_to(
  "id_log",
  "Baseliner::Schema::Baseliner::Result::BaliLog",
  { id => "id_log" },
);

=head2 id_job

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJob>

=cut

__PACKAGE__->belongs_to(
  "id_job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'BALI_LOG_DATA_IDX_ID_LOG', fields=>['id_log'] );
}

1;
