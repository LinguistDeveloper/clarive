package BaselinerX::Model::BaliRoleUser;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Moose;
use utf8;

has 'bali_project', is => 'ro', isa => 'Object', lazy_build => 1;
has 'table',        is => 'ro', isa => 'Str',    lazy_build => 1;

sub update {
  my $self = shift;
  $self->populate_second_level;
  $self->populate_third_level;
  return;
}

sub roles_for_lvl {
  my ($self, $lvl) = @_;
  my $projects = [map { $_ = "project/$_" } $self->bali_project->lvl_ids($lvl)];
  $self->search({ns => {in => $projects}});
}

sub search {
  my ($self, $where) = @_;
  my $rs = Baseliner->model($self->table)->search($where);
  rs_hashref($rs);
  [$rs->all];
}

sub ns_id {
  my ($self, $str) = @_;
  $1 if $str =~ m/\w+\/(\d+)/x;
}

sub _build_bali_project { BaselinerX::Model::BaliProject->new }

sub _build_table { 'Baseliner::BaliRoleUser' }

sub populate_second_level {
  my $self = shift;
  $self->_decompose($self->roles_for_lvl(1), $self->bali_project->first_to_second);
  return;
}

sub populate_third_level {
  my $self = shift;
  $self->_decompose($self->roles_for_lvl(2), $self->bali_project->second_to_third);
  return;
}

sub _decompose {
  my $self = shift;
  my @roles = @{shift()};
  my %pairs = %{shift()};
  %pairs = $self->bali_project->filter_relationship(%pairs);
  for my $href (@roles) {
    my $id = $self->ns_id($href->{ns});
    if (exists $pairs{$id}) {
      my @subapls = @{$pairs{$id}};
      for my $subapl (@subapls) {
        $self->clone($href, $subapl);
      }
    }
  }
  return;
}

sub clone { # HashRef Int -> new-record?
  my ($self, $href, $id) = @_;
  unless ($self->already_exists($href, $id)) {
    $href->{ns} = "project/$id";
    Baseliner->model($self->table)->create($href);
  }
}

sub already_exists { # HashRef Int -> Bool
  my ($self, $href, $id) = @_;
  $href->{ns} = "project/$id";
  my $rs = Baseliner->model($self->table)->search($href);
  rs_hashref($rs);
  scalar $rs->all ? 1 : 0;
}

sub delete {
  my ($self, $where) = @_;
  return Baseliner->model($self->table)->delete() if $where eq ':all';
  Baseliner->model(shift->table)->search($where)->delete if $where;
}

1;

__END__

=head1 BaliRoleUser

  my $model = BaselinerX::Model::BaliRoleUser->new;

=head2 roles_for_lvl

Gives the roles for a given level (1..3)

  $model->roles_for_level(1)

=head2 search

Searchs in the model table with a given where clause (hashref). Returns all columns.

  $model->search({username => 'foo'})

=head2 ns_id

  $model->ns_id('project/72')
  #=> 72

=head2 update

Runs the update of both 2nd and 3rd level.

  $model->update

=head2 populate_second_level

Populates the second level.

  $model->populate_second_level

=head2 populate_third_level

Populates the third level

  $model->populate_third_level

=head2 delete

  $model->delete({username => 'santa'});

  # or, to delete all...
  $model->delete(:all);

=cut
