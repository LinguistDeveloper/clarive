package Baseliner::Schema::Baseliner::Result::BaliJobItems;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_job_items");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 38,
  },
  "data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "provider",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 38,
  },
  "service",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "application",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "rfc",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_project",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },  
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_job

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJob>

=cut

__PACKAGE__->belongs_to(
  "id_job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);

__PACKAGE__->belongs_to(
  "project",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { mid => "id_project" },
);

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_job_items_idx_id_job', fields=>['id_job'] );
}

1;
