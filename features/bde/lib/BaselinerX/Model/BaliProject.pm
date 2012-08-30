package BaselinerX::Model::BaliProject;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Moose;
use Try::Tiny;
use utf8;

has 'mid',             is => 'ro', isa => 'Int',      lazy_build => 1;
has 'name',            is => 'ro', isa => 'Str',      lazy_build => 1;
has 'table',           is => 'ro', isa => 'Str',      lazy_build => 1;
has 'first_level',     is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'second_level',    is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'third_level',     is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'first_to_second', is => 'ro', isa => 'HashRef',  lazy_build => 1;
has 'second_to_third', is => 'ro', isa => 'HashRef',  lazy_build => 1;

sub _build_table { 'Baseliner::BaliProject' }

sub _build_mid {
  my $self  = shift;
  my $model = Baseliner->model($self->table);
  my $rs = $model->search({name      => $self->name,
                           id_parent => {is => undef},
                           nature    => {is => undef}},
                          {select => 'mid'});
  rs_hashref($rs);
  try {
    my $mid = $rs->next->{mid};
    return $mid;
  }
  catch {
    $self->insert;
    $self->mid;
  };
}

sub _build_name {
  my $self  = shift;
  my $model = Baseliner->model($self->table);
  my $rs = $model->search({mid        => $self->mid,
                           id_parent => {is => undef},
                           nature    => {is => undef}});
  rs_hashref($rs);
  $rs->next->{name};
}

sub insert {
  my $self  = shift;
  _log "Adding project " . $self->name;
  my $model = Baseliner->model($self->table);
  $model->create({name => uc($self->name)});
}

sub _build_first_level { shift->search_in_projects({id_parent => undef}) }

sub _build_second_level {
  shift->search_in_projects({id_parent => {not => undef},
                             nature    => undef})
}

sub _build_third_level {
  shift->search_in_projects({id_parent => {not => undef},
                             nature    => {not => undef}})
}

sub search_in_projects {
  my ($self, $where) = @_;
  my $rs = Baseliner->model('Baseliner::BaliProject')->search($where,
                                                              $self->args);
  rs_hashref($rs);
  [$rs->all];
}

sub args { {select => [qw/mid id_parent/], order_by => 'id_parent'} }

sub give_relatives {
  my ($self, $mid, @ls) = @_;
  [map $_->{mid}, grep $_->{id_parent} eq $mid, @ls];
}

sub level_to_level {
  my ($self, $upper_list, $bottom_list) = @_;
  my %h = map { $_->{mid} => $self->give_relatives($_->{mid}, @{$upper_list}) }
              @{$bottom_list};
  \%h;
}

sub _build_second_to_third {
  my $self = shift;
  $self->level_to_level($self->third_level, $self->second_level);
}

sub _build_first_to_second {
  my $self = shift;
  $self->level_to_level($self->second_level, $self->first_level);
}

sub lvl_ids {
  my ($self, $level) = @_;
  my $fn = sub { sort {$a > $b} map $_->{mid}, @_ };
  given ($level) {
    when (1) { return $fn->(@{$self->first_level})  }
    when (2) { return $fn->(@{$self->second_level}) }
    when (3) { return $fn->(@{$self->third_level})  }
    default  { return ()                            }
  }
}

sub filter_relationship {
  my ($self, %dummy) = @_;
  do { delete $dummy{$_} unless scalar @{$dummy{$_}} } for keys %dummy;
  %dummy;
}

sub is_first_level {
  my $self  = shift;
  my $mid    = $self->mid;
  my $model = Baseliner->model($self->table);
  my $rs = $model->search({mid        => $self->mid,
                           id_parent => {is => undef},
                           nature    => {is => undef}});
  rs_hashref($rs);
  my @data = $rs->all;

  scalar @data ? 1 : 0;
}

1;

__END__

=head1 BaliProject

  my $model = BaselinerX::Model::BaliProject->new;

=head2 first_level

Returns data from all projects at level 1 (CAM)

  $model->first_level
  #=> ArrayRef[HashRef]

=head2 second_level

Returns data from all projects at level 2 (CAM => SUBAPL)

  $model->second_level
  #=> ArrayRef[HashRef]

=head2 third_level

Returns data from all projects at level 3 (SUBAPL => NATURE)

  $model->third_level
  #=> ArrayRef[HashRef]

=head2 first_to_second

The relationship between the first and the second level. Kind of l1 has 0..N l2.

  $model->first_to_second
  #=> {id_l1 => [id_l2..N], ...}

=head2 second_to_third

The relationship between the second and the third level. Same as the previous method.

  $model->second_to_third
  #=> {id_l2 => [id_l3..N], ...}

=head2 filter_relationship

Returns the relationship without any entry with no children ids.

  $model->filter_relationship(%{$model->first_to_second})

=head2 lvl_ids

Returns a list with all project ids from a given level.

  $model->lvl_ids(1)
  #=> [1, 2, 3, 4, 5 .. N]

=cut
