package BaselinerX::Job::Service::UpdateBaselinerLdif;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Baseliner::Sugar;
use Class::Date qw/date now/;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.baseliner.update.ldif' => {
  name    => 'Update Baseliner from Ldif files',
  handler => \&init
};

register 'service.baseliner.update.ldif.cyclic' => {
  name    => 'Update Baseliner from Ldif files once a day more or less at 2am',
  handler => \&run_daemon
};

sub run_daemon {
  my $self = shift;
  while (1) {
    my $date = now;
    $self->init(1) if $date->hour == _bde_conf('update_user_hour');
    sleep 3600;
  }
}

sub init {
  my ($self, $c, $config) = @_;
  my %user_groups = %{$config->{user_groups}};

  #warn "INIT"._dump $config->{group};

  # Make sure we have some data...
  if (keys %user_groups < 50) {
    my $err_msg = 'Something went wrong when parsing ldif files.';
    _log $err_msg;
    _throw $err_msg;
    notify_ldif_error $err_msg;
    return;
  }

  _log "Inserting new projects...";
  my @added_projects;
  #for my $cam (sort @{_unique map { substr($_, 0, 3) } keys %{$config->{group}}}) {
  for my $cam (sort {$a cmp $b} _unique map { substr($_, 0, 3) } keys %{$config->{group}}) {
    unless ($self->exists_project($cam)) {
      $self->insert_project($cam) unless $self->exists_project($cam);
      push @added_projects, $cam;
    }
  }
  if (scalar @added_projects) {
    _log "Projects updated: " . join ', ', @added_projects;
  }
  
   # It's not a bad idea to update the projects now.
   _log "Applying changes...";
   try {
   $c->launch('service.load.bali.project_once');
   }
   catch {
   	 notify_ldif_error 'Error al actualizar los proyectos en Baseliner.';
   };
   _log "Baseliner Projects fully updated";

  # We have to delete all users and their roles as they can be deleted from the
  # ldif files. Meaning that they shouldn't exist in the database.
  _log "Deleting users and their roles...";
  Baseliner->model('Baseliner::BaliUser')->delete;
  $self->delete_non_immutable_data;
  # Baseliner->model('Baseliner::BaliRoleUser')->delete;
  _log "Users and roles deleted.";

  _log "Getting JU users...";
  my @ju_usernames = map { lc $_ } $self->_ju_usernames;
  _log join ', ', @ju_usernames;

  for my $user_name (keys %user_groups) {
    _log "Processing: ".$user_name;;
    
    # New user object. Remember that a new user is created automatically if
    # the username is not found in the table.
    $user_name = lc($user_name);
    my $user = BaselinerX::Model::BaliUser->new(username => $user_name);
    _log "CREADO: $user";
    $user->mid;  # Lazy update...

    # Is the user contained in JU list?
    my $user_is_ju = $user_name ~~ @ju_usernames ? 1 : 0;
    _log "user $user_name is JU" if $user_is_ju;
    _log "user $user_name not is JU" unless $user_is_ju;

    # These are all the roles that apply to the given user:
    for my $item (@{$user_groups{uc($user_name)}}) {
      my ($cam, $role_name) = $self->_cam_role($item);
      $role_name ||= 'RO';  # Default, read-only role.
      $role_name = "$cam-$role_name" if $cam eq 'RPT';
_log "Processing $item";
      my $role = BaselinerX::Model::BaliRole->new(role => $role_name);
      my $project = BaselinerX::Model::BaliProject->new(name => $cam);

      # So now we have the objects for both the user, cam and role. Let's do
      # some magic.
      my $href = {username   => $user->username,
                  id_role    => $role->id,
                  id_project => $project->mid,
                  ns         => substr($role_name, 0, 3) eq 'RPT'
                                ? '/'
                                : "project/" . $project->mid};
      Baseliner->model('Baseliner::BaliRoleuser')->create($href)
        unless $self->exists_roleuser($href);

      # If user is JU and current role is 'RA'...
      if (($role_name eq 'RA') && $user_is_ju) {
        _log "user $user_name is JU and also RA in project: " . $project->name;
        my $new_role = BaselinerX::Model::BaliRole->new(role => 'JU');
        $href->{id_role} = $new_role->id;

        Baseliner->model('Baseliner::BaliRoleUser')->create($href)
          unless $self->exists_roleuser($href);
      }
    }
  }

  # Finally, update the relationships for the 2nd and 3rd project levels.
  _log "Updating 2nd and 3rd level of BaliRoleUser...";
  my $roleuser = BaselinerX::Model::BaliRoleUser->new;
  $roleuser->update;
  _log "Update of BaliRoleUser complete.";

  return;
}

sub _cam_role { # Str -> Str Str
  my ($self, $item) = @_;
  my ($cam, $role) = $item =~ /(.+)-(.+)/;
  $cam ||= $item;

  $cam, $role;
}

sub exists_project { # Str -> Bool
  my ($self, $project_name) = @_;
  my $model = Baseliner->model('Baseliner::BaliProject');
  my $rs = $model->search({name      => $project_name,
                           id_parent => {is => undef},
                           nature    => {is => undef}});
  rs_hashref($rs);
  my @data = $rs->all;

  scalar @data ? 1 : 0;
}

sub exists_roleuser { # Int -> Bool
  my ($self, $href) = @_;
  my $model = Baseliner->model('Baseliner::BaliRoleUser');
  my $rs = $model->search($href);
  rs_hashref($rs);
  my @data = $rs->all;

  scalar @data ? 1 : 0;
}

sub insert_project { # Str -> ResultSet
  my ($self, $project_name) = @_;
  my $model = Baseliner->model('Baseliner::BaliProject');
  master_new "project"=>$project_name=>sub{
      my $mid=shift;
      $model->create({mid=>$mid, name => $project_name});
  };


}

sub _ju_usernames { # Undef -> Array
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my $query = qq{
    SELECT DISTINCT(codigo_ju)
               FROM inf_ju
  };
  $har_db->db->array($query);
}

sub delete_non_immutable_data {
  sub _immutable_role_ids { # -> Array
    my $b_role = Baseliner->model('Baseliner::BaliRole');
    my $rs = $b_role->search({'substr(role, 0, 1)' => '#'}, {select => 'id'});
    rs_hashref($rs);
    map { $_->{id} } $rs->all;
  }
  my $rs_roleuser = do { # -> Object
    my @immutable_role_ids = _immutable_role_ids();
    my $b_roleuser = Baseliner->model('Baseliner::BaliRoleuser');
    $b_roleuser->search({id_role => {'!=' => \@immutable_role_ids}});
  };
  $rs_roleuser->delete;
}

1;
