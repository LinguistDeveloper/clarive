package BaselinerX::Job::Service::UpdateUsers;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Class::Date qw/date now/;
use Data::Dumper;
use Try::Tiny;

register 'service.update.users' => {
  name    => 'Carga de usuarios y sus permisos',
  handler => \&run
};

register 'service.update.users.now' => {
  name    => 'Force update users',
  handler => \&do_now
};

register 'service.update.users.now.noldif' => {
  name    => 'Force update users without ldif',
  handler => \&do_now_noldif
};

sub run {
  my $self = shift;
  while (1) {
    my $date = now;
    $self->init(1) if $date->hour == _bde_conf('update_user_hour');
    sleep 3600;
  }
}

sub do_now {
  my $self = shift;
  $self->init;
}

sub do_now_noldif {
  my $self = shift;
  $self->init(1);
}

sub init { # Undef -> Undef
  my $self = shift;
  my $no_ldif = shift || 0;
  if ($no_ldif) {
    _log 'Launching without ldif';
  }
  else {
    _log 'Launching with ldif';
    BaselinerX::Controller::CargaLdif->init;
  }

  my $bali_role_user = BaselinerX::Model::BaliRoleUser->new();
  my $bali_user = BaselinerX::Model::BaliUser->new();

  _log 'Deleting bali_user...';
  $bali_user->delete(':all');

  _log 'Deleting bali_role_user...';
  $bali_role_user->delete(':all');

  _log 'Building user iterator...';
  my $user_iterator = $self->loop_usrobjids();
  while (1) {  # Giving a new user id until empty.
    my $user_id = $user_iterator->();
    $self->update_create_baliuser($user_id);
    $self->insert_baliroleuser($user_id);
  }
  $bali_role_user->populate_second_level;
  $bali_role_user->populate_third_level;
  return;
}

sub loop_usrobjids { # Undef -> CodeRef
  my $self = shift;
  my $args = {select => 'usrobjid'};
  my $rs = Baseliner->model('Harvest::Haruser')->search(undef, $args);
  rs_hashref($rs);
  my @data = $rs->all;
  sub {
    my $href = shift @data;
    $href->{usrobjid} or last;  # End condition.
  } 
}

sub build_haruser_params { # Int -> HashRef
  my ( $self, $id ) = @_;
  my $args = {select => ['usrobjid', {trim => 'username'}, {trim => 'realname'}], 
              as     => ['id', 'username', 'realname']};
  my $where = { usrobjid => $id };
  my $rs = Baseliner->model('Harvest::Haruser')->search( $where, $args );
  rs_hashref($rs);
  $rs->next;
}

sub update_create_baliuser { # Int -> Undef
  # Updates or creates a given user (id) from HARUSER to BALI_USER.
  my ($self, $user_id) = @_;
  my $user = $self->build_haruser_params($user_id);
  _log "Creating user $user->{username} in bali_user";
  Baseliner->model('Baseliner::BaliUser')
               ->update_or_create({ username => $user->{username}
                                  , password => '~'
                                  , realname => $user->{realname}
                                  }, {key => 'username'});
  return;
}

sub groups { # int -> Defined/ArrayRef[HashRef]
  # Gives all the harvest groups corresponding to a given user (id).
  my ($self, $user_id) = @_;
  my $query = qq{
    SELECT TRIM(usergroupname) as usergroupname
      FROM harusergroup
     WHERE usrgrpobjid IN (SELECT usrgrpobjid
                             FROM harusersingroup
                            WHERE usrobjid = $user_id)
  };
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my @groups = $har_db->db->array($query);
  _log "got some groups!" if scalar @groups;
  wantarray ? @groups : \@groups;
}

sub insert_baliroleuser { # Int -> Undef
  my ($self, $user_id) = @_;
  my @data  = $self->BALIdate_roles_user($user_id);
  my $model = 'Baseliner::BaliRoleuser';

  for my $href (@data) {
    # Checks if there is any record (I don't want to mess with
    # constraints right now and they don't really offer any
    # performance boost...).
    my $rs = Baseliner->model($model)->search($href);
    rs_hashref($rs);
    my @results = $rs->all;
    Baseliner->model($model)->create($href) unless @results;
  }
  return;
}

sub BALIdate_roles_user { # Int -> Defined|ArrayRef[HashRef]
  my ($self, $user_id) = @_;
  my $user   = $self->build_haruser_params($user_id);
  my @data;
  my @groups = $self->groups($user_id);

  for my $group (@groups) {
    my $bali_rolename;
    my $ns;
    if ($group =~ m/^RPT/) {
      if ($group =~ m/-(.+)/) {
        if ($1 ~~ $self->roles) {
          $ns            = 'RPT';
          $bali_rolename = $1;
        }
        else {
          $bali_rolename = $group; 
        } 
      }
      else {
        $ns            = 'RPT';
        $bali_rolename = 'RO'; 
      } 
    }
    else {
      if ($group =~ m/(...)-(..)/) {
        $ns            = $1;
        $bali_rolename = $2; 
      }
      elsif (length($group) == 3) {  # CAMs only.
        $ns            = $group;
        $bali_rolename = 'RO'; 
      } 
    }
    # Comment this if you want to see the cam name.
    $ns = $ns ? "project/" . $self->projectid_given_cam($ns)
              : "/";

    push @data, { ns       => $ns
                , id_role  => $self->roleid_given_rolename($bali_rolename)
                , username => $user->{username}
                } if $bali_rolename; 
  }
  wantarray ? @data : \@data;
}

sub projectid_given_cam { # Str -> Int
  # Given a CAM, returns its ID contained in BALI_PROJECT.  If it does
  # not exist, creates a new record and then returns the ID.
  my ($self, $cam) = @_;
  my $args = {name => $cam};

  # We have to check and create manually because DBIx::Class
  # find_or_create sucks and promps over 9000 warnings about
  # deprecated stuff because our table has a tree format.
  my $rs = Baseliner->model('Baseliner::BaliProject')->search($args);
  rs_hashref($rs);
  my @data = $rs->all;

  return $data[0]->{id} if @data;

  # Otherwise we have to create a new record and return the {id}.
  Baseliner->model('Baseliner::BaliProject')->create($args);
  my $rs2 = Baseliner->model('Baseliner::BaliProject')->search($args);
  rs_hashref($rs2);
  $rs2->next->{id};
}

sub roles { # Undef -> Defined|ArrayRef[HashRef]
  # All the roles in BALI_ROLE (those whose length is not longer than 2).
  my $self = shift;
  my $rs = Baseliner->model('Baseliner::BaliRole')->search();
  rs_hashref($rs);
  my @roles = map { $_->{role} } grep (length($_->{role}) <= 2, $rs->all);
  _log 'got some roles!' if scalar @roles;
  wantarray ? @roles : \@roles;
}

sub roleid_given_rolename { # Str -> Int
  my ($self, $role) = @_;
  Baseliner->model('Baseliner::BaliRole')
               ->find_or_create({role => $role})->id;
}

1;
