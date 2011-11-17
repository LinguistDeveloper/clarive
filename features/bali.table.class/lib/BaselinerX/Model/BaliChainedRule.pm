package BaselinerX::Model::BaliChainedRule;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use List::Util qw/reduce/;
use Moose;
use Try::Tiny;
use utf8;

has 'id',          is => 'ro', isa => 'Int',  lazy_build => 1;
has 'seq',         is => 'rw', isa => 'Int',  lazy_build => 1, trigger => \&update_seq;
has 'name',        is => 'rw', isa => 'Str',  lazy_build => 1;
has 'description', is => 'rw', isa => 'Str',  lazy_build => 1;
has 'step',        is => 'rw', isa => 'Str',  lazy_build => 1;
has 'dsl',         is => 'rw', isa => 'Str',  lazy_build => 1;
has 'dsl_code',    is => 'rw', isa => 'Str',  lazy_build => 1;
has 'active',      is => 'rw', isa => 'Bool', lazy_build => 1;
has 'ns',          is => 'rw', isa => 'Str',  lazy_build => 1;
has 'service',     is => 'rw', isa => 'Str',  lazy_build => 1;

sub _build_step {
  my $self = shift;
  $self->get_from_id('step');
}

sub _build_description {
  my $self = shift;
  $self->get_from_id('description');
}

sub _build_name {
  my $self = shift;
  $self->get_from_id('name');
}

sub get_from_id {
  my ($self, $arg) = @_;
  my $model = $self->model;
  my $rs = $model->search({id => $self->id}, {select => $arg});
  rs_hashref($rs);
  $rs->next->{$arg};
}

sub _build_seq {
  my $self = shift;
  $self->get_from_id('seq');
}

sub _build_id {
  my $self  = shift;
  my $model = $self->model;
  my $rs    = $model->search(undef, {select => 'id'});
  rs_hashref($rs);
  inc reduce { $a > $b ? $a : $b } map { $_->{id} } $rs->all;
}

sub table { 'Baseliner::BaliChainedRule' }

sub model {
  my $self = shift;
  Baseliner->model($self->table);
}

sub increase_seq {
  my $self = shift;

  # Search the ID for the next sequence.
  my $model = $self->model;
  my $rs = $model->search({seq => $self->seq + 1});
  rs_hashref($rs);

  # Increase self.
  $self->seq($self->seq + 1);

  # Increase the rest of the objects or return if last.
  try {
    my $next_object_id = $rs->next->{id};
    my $next_seq_object =
      BaselinerX::Model::BaliChainedRule->new(id => $next_object_id);
    $next_seq_object->increase_seq;
  }
  catch {
    return;
  }
}

sub update_seq {
  my $self  = shift;
  my $model = $self->model;
  $model->search({id => $self->id})->update({seq => $self->seq});
}

1;
