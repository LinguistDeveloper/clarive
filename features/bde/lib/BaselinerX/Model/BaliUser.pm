package BaselinerX::Model::BaliUser;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Baseliner::Sugar;
use Moose;
use Try::Tiny;
use utf8;

# Either ID or USERNAME must be provided.
has 'mid',           is => 'ro', isa => 'Int', lazy_build => 1;
has 'harid',        is => 'ro', isa => 'Str', lazy_build => 1;
has 'username',     is => 'ro', isa => 'Str', lazy_build => 1;
has 'realname',     is => 'ro', isa => 'Str', lazy_build => 1;
has 'har_realname', is => 'ro', isa => 'Str', lazy_build => 1;

sub table { 'Baseliner::BaliUser' }

sub _get {
  my ($self, $where, $args) = @_;
  my $rs = Baseliner->model($self->table)->search($where, $args);
  rs_hashref($rs);
  $rs;
}

sub _build_mid {
  my $self = shift;
  my $rs = $self->_get({username => $self->username}, {select => 'mid'});
  try {
    my $mid = $rs->next->{mid};
    return $mid;
  }
  catch {
    $self->insert;
    $self->mid;  # Call the builder again.
  };
}

sub _build_realname {
  my $self = shift;
  my $rs = $self->_get({mid => $self->mid}, {select => 'realname'});
  $rs->next->{realname};
}

sub _build_username {
  my $self = shift;
  my $rs = $self->_get({mid => $self->mid}, {select => 'username'});
  $rs->next->{username};
}

sub delme {
  my $self = shift;
  my $rs = $self->_get({mid => $self->mid});
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

sub _build_har_realname {
  my $self     = shift;
  my $username = $self->username;
  my $query    = qq{
    SELECT realname
      FROM haruser
     WHERE username = '$username'
  };
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  $har_db->db->value($query) || uc($username) . " - JOHN DOE";
}

sub insert {
  my $self  = shift;
  my $model = Baseliner->model('Baseliner::BaliUser');
  master_new "user"=>$self->username=>sub{
      my $mid=shift;
      $model->create({mid      => $mid,
                      username => $self->username,
                      password => '~',
                      realname => $self->har_realname});
  };
}

sub desc_roles {
  my $self = shift;

  my $rs = Baseliner->model('Baseliner::BaliRoleUser')
             ->search({username => $self->username});
  rs_hashref($rs);
  my @data = $rs->all;

  for my $href (@data) {
    my $project_id = $1 if $href->{ns} =~ /\/(.+)/;
    my $project = BaselinerX::Model::BaliProject->new(mid => $project_id);

    next unless $project->is_first_level();

    $rs = Baseliner->model('Baseliner::BaliRole')
            ->search({id     => $href->{id_role}}, 
                     {select => [qw/role description/]});
    rs_hashref($rs);
    my $roleref = $rs->next;
    my $role    = $roleref->{role};
    my $desc    = $roleref->{description};

    my $str = $self->username . " is $role";
    $str .= " ($desc)" if $desc;
    $str .= " in " . $project->name . ".";
    say $str;
  }

  return;
} 

1;
