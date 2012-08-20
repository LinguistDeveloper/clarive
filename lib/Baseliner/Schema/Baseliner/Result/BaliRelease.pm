package Baseliner::Schema::Baseliner::Result::BaliRelease;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_release");
__PACKAGE__->add_columns(
  "id",
  { data_type => "NUMBER", default_value => undef, is_nullable => 0, size => 38 },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "active",
  { data_type => "CHAR", default_value => 1, is_nullable => 0, size => 1 },
  "ts",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => '*',
    is_nullable => 0,
    size => 100,
  },
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => '/',
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_release_items",
  "Baseliner::Schema::Baseliner::Result::BaliReleaseItems",
  { "foreign.id_rel" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-29 12:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8ipVWsLgWJHmnqWRqlGuoQ

sub namespace {
    my $self = shift;
    use BaselinerX::Release::Namespace::Release;
    return BaselinerX::Release::Namespace::Release->new({ row=>$self });
}

sub item {
    my $self = shift;
    return 'release/' . $self->id
}

1;
