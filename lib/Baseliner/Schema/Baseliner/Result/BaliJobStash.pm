package Baseliner::Schema::Baseliner::Result::BaliJobStash;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliJobStash

=cut

__PACKAGE__->table("bali_job_stash");

=head1 ACCESSORS

=head2 id

  data_type: NUMBER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 38

=head2 stash

  data_type: BLOB
  default_value: undef
  is_nullable: 1
  size: 2147483647

=head2 id_job

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: 38

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 38,
  },
  "stash",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 38,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 bali_jobs

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJob>

=cut

__PACKAGE__->has_many(
  "bali_jobs",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { "foreign.id_stash" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-07 11:18:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O16odajTWL4y+jSHOq+rpg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
