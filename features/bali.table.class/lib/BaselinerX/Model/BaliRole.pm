package BaselinerX::Model::BaliRole;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Moose;
use Try::Tiny;

has 'id',          is => 'ro', isa => 'Int',    lazy_build => 1;
has 'role',        is => 'ro', isa => 'Str',    lazy_build => 1;
has 'description', is => 'ro', isa => 'Str',    lazy_build => 1;
has 'table',       is => 'ro', isa => 'Str',    lazy_build => 1;
has 'model',       is => 'ro', isa => 'Object', lazy_build => 1;

sub _build_table { 'Baseliner::BaliRole' }

sub _build_model {
  my $self = shift;
  Baseliner->model($self->table);
}

sub _single {
  my ($self, $arg, $where_ref) = @_;
  my $model = $self->model;
  my $rs = $model->search->search($where_ref, {select => $arg});
  rs_hashref($rs);
  $rs->next->{$arg};
}

sub _build_id {
  my $self = shift;
  try {
    my $id = $self->_single('id', {role => $self->role});
    return $id;
  }
  catch {
    $self->insert;
    $self->id;
  };
}

sub _build_role {
  my $self = shift;
  $self->_single('role', {id => $self->id});
}

sub _build_description {
  my $self = shift;
  $self->_single('description', {id => $self->id});
}

sub insert {
  my $self  = shift;
  my $model = $self->model;
  $model->create({role => $self->role});
}

1;
