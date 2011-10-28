package BaselinerX::Model::BaliUser;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Moose;

# Either ID or USERNAME must be provided.
has 'id',       is => 'ro', isa => 'Int', lazy_build => 1;
has 'harid',    is => 'ro', isa => 'Str', lazy_build => 1;
has 'username', is => 'ro', isa => 'Str', lazy_build => 1;
has 'realname', is => 'ro', isa => 'Str', lazy_build => 1;

sub table { 'Baseliner::BaliUser' }

sub _get {
  my ($self, $where, $args) = @_;
  my $rs = Baseliner->model($self->table)->search($where, $args);
  rs_hashref($rs);
  $rs;
}

sub _build_id {
  my $self = shift;
  my $rs = $self->_get({username => $self->username}, {select => 'id'});
  $rs->next->{id};
}

sub _build_realname {
  my $self = shift;
  my $rs = $self->_get({id => $self->id}, {select => 'realname'});
  $rs->next->{realname};
}

sub _build_username {
  my $self = shift;
  my $rs = $self->_get({id => $self->id}, {select => 'username'});
  $rs->next->{username};
}

sub delme {
  my $self = shift;
  my $rs = $self->_get({id => $self->id});
  $rs->delete;
}

sub delete {
  my ($self, $where) = @_;
  return Baseliner->model($self->table)->delete if $where eq ':all';
  Baseliner->model($self->table)->search($where)->delete if $where;
}

sub _build_harid {
  my $self = shift;
  my $username = $self->username;
  my $query = qq{
    SELECT usrobjid
      FROM haruser
     WHERE username = '$username'     
  };
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  $har_db->db->value($query);
}

sub hargroups {
  my $self  = shift;
  my $harid = $self->harid;
  my $query = qq{
    SELECT TRIM(usergroupname) as usergroupname
      FROM harusergroup
     WHERE usrgrpobjid IN (SELECT usrgrpobjid
                             FROM harusersingroup
                            WHERE usrobjid = $harid)
  };
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my @groups = $har_db->db->array($query);
  wantarray ? @groups : \@groups;
}

1;
