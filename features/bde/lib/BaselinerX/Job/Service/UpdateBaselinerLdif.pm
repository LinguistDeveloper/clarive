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

=head2 init

Parametros:

    group => {}
    user_groups => {}
    user_filter => <regex> (undef,opcional) - filtra los usuarios que se cargan
    delete_users => Bool (0,opcional) - flag que indica que se debe borrar BaliUser al principio
    delete_roleusers => Bool (0,opcional) - flag que indica que se debe borrar BaliRoleuser al principio

=cut 
sub init {
    my ($self, $c, $config) = @_;
    my %user_groups = %{$config->{user_groups}};
    my $user_filter = $config->{user_filter}; # ejecuta para solo este usuario
    if( length $user_filter ) {
        _log "Filtro usuario=$user_filter";
        $user_filter = qr/$user_filter/i;
    }

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
    my %projects = DB->BaliProject->search({ id_parent=>undef, nature=>undef })->hash_on('name');
    _log "Total de projectos en BBDD: " . scalar keys %projects;
    _debug "Proyectos en BBDD: " . join ',',sort keys %projects;
    my @group_cams = _unique map { substr($_, 0, 3) } keys %{$config->{group}}; 
    _debug "CAMs detectados en los LDIF de grupo: " . join',',sort @group_cams;
    my @missing_projects = grep { !exists $projects{$_} } @group_cams; 
    _log "Total de projectos que faltan en BBDD: " . scalar @missing_projects;
    if( @missing_projects ) {
        _log "Proyectos a actualizar: " . join ', ', @missing_projects;
        $self->insert_project($_) for @missing_projects;
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

    #    infroox: ya no se borra todo, la carga es progresiva
    # We have to delete all users and their roles as they can be deleted from the
    # ldif files. Meaning that they shouldn't exist in the database.
    #_log "Deleting users and their roles...";
    _log("Borrando usuarios delete_users=true"),Baseliner->model('Baseliner::BaliUser')->delete if $config->{delete_users};
    _log("Borrando roleuser delete_roleusers=true"),$self->delete_non_immutable_data if $config->{delete_roleusers};
    #_log "Users and roles deleted.";

    my %current_users = DB->BaliUser->search->hash_on('username');

    _log "Getting JU users...";
    my %ju_usernames = map { lc $_ => undef } $self->_ju_usernames;
    _log join ', ', sort keys %ju_usernames;

    my @ldif_users; # lista de usuarios encontrados en LDIF, para luego borrar los que sobran
    my %ldif_roleusers; # tuplas de usuario-role-proyecto que viene en el LDIF

    # cache de roles-usuario
    my %roleusers;
    map { $roleusers{ $_->{username} }{ $_->{id_role} }{ $_->{id_project} } = undef } DB->BaliRoleuser->search->hashref->all;

    # cache de roles
    my %roles = map { $_->{role} = $_ } DB->BaliRole->hashref->all;

    # cache de proyectos (reorganiza el hash_on de mas arriba)
    %projects = map { $_ => $projects{$_}->[0] } keys %projects;

    for my $user_name (sort keys %user_groups) {
        next if $user_filter && $user_name !~ $user_filter;
        _log "Processing: ".$user_name;;
    
        # New user object. Remember that a new user is created automatically if
        # the username is not found in the table.
        $user_name = lc($user_name);
        push @ldif_users, $user_name;
        if( ! exists $current_users{ $user_name } ) {
            _log "Usuario no encontrado: $user_name. Lo creamos...";
            my $user = BaselinerX::Model::BaliUser->new(username => $user_name);
            _log "Usuario CREADO: $user";
            $user->mid;  # Lazy update...
        }

        # Is the user contained in JU list?
        my $user_is_ju = exists $ju_usernames{ $user_name };
        _log $user_is_ju ? "user $user_name is JU" : "user $user_name is not JU";

        # These are all the roles that apply to the given user:
        for my $item (@{$user_groups{uc($user_name)}}) {
            my ($cam, $role_name) = $self->_cam_role($item);
            $role_name ||= 'RO';  # Default, read-only role.
            $role_name = "$cam-$role_name" if $cam eq 'RPT';

            # tira de cache, para reducir queries al minimo, excepto cuando hay que crear proyectos o roles
            my $role_id = $roles{$role_name}{id} // ( $roles{$role_name}{id}=BaselinerX::Model::BaliRole->new(role => $role_name)->id );
            my $project = $projects{$cam} // ( $projects{$cam} = do {
                my $p = BaselinerX::Model::BaliProject->new(name => $cam);
                { id=>$p->id, name=>$p->name }
            } );

            _debug "ROLE-ID $role_name => $role_id";

            _throw "ERROR: no se ha podido crear el rol $role_name" unless defined $role_id;
            _throw "ERROR: no se ha podido crear el proyecto $cam" unless defined $project;

            # So now we have the objects for both the user, cam and role. Let's do
            # some magic.
            my $is_rpt = substr($role_name, 0, 3) eq 'RPT';
            _debug sprintf( "$user_name %s RPT", ($is_rpt ? 'es' : 'no es') );
  
            my $href = {username   => $user_name,
                        id_role    => $role_id,
                        id_project => $is_rpt ? 0 : $project->{mid},
                        ns         => $is_rpt  
                                      ? '/'
                                      : "project/" . $project->{mid}};
  
            $ldif_roleusers{ $href->{username} }{ $href->{id_role} }{ $href->{id_project} } = undef; # preparar tuple para el borrado posterior
          
            if( ! exists $roleusers{ $href->{username} }{ $role_id }{ $project->{mid} } 
             && ! exists  $roleusers{ $href->{username} }{ $role_id }{ 0 } ) {   # 0 quiere decir "todos", lo mismo que NS=/
                _log "Creating $item for $user_name ($role_name): " . _dump($href);
                DB->BaliRoleuser->create($href);   # find_or_create seria mas seguro, pero tarda mas
                $roleusers{ $href->{username} }{ $href->{id_role} }{ $href->{id_project} } = undef; # actualizar
            } else {
                _debug "EXISTE: $user_name => $role_name en $project->{name}";
            }

            # los JU vienen como RA, hay que cruzarlos con los datos del Formulario de INF
            # If user is JU and current role is 'RA'...
            if( $role_name eq 'RA' && $user_is_ju) {
                _log "user $user_name is JU and also RA in project: " . $project->{name};
                $role_name = 'JU';
                my $new_role_id = $roles{'JU'}{id} // ( $roles{'JU'}{id}=BaselinerX::Model::BaliRole->new(role => 'JU')->id );

                $href->{id_role} = $new_role_id;
             
                $ldif_roleusers{ $href->{username} }{ $href->{id_role} }{ $href->{id_project} } = undef; # preparar tuple para el borrado posterior

                if( ! exists $roleusers{ $href->{username} }{ $href->{id_role} }{ $project->{mid} } 
                && ! exists  $roleusers{ $href->{username} }{ $href->{id_role} }{ 0 } ) {   # 0 quiere decir "todos", lo mismo que NS=/
                    _log "Creating $item for $user_name (RA-JU): " . _dump( $href );;
                    DB->BaliRoleuser->create($href);   # find_or_create seria mas seguro, pero tarda mas
                    $roleusers{ $href->{username} }{ $href->{id_role} }{ $href->{id_project} } = undef; # actualizar
                }
            }
        }
    }

    # borrar usuarios que no vienen en el LDIF
    if( @ldif_users ) {
        if( $user_filter ) {
            _log "Borrado de usuarios no realizado - con user_filter ($user_filter) no hay borrado";
        } else {
            _log "Borrando users: " . join ',',@ldif_users;
            DB->BaliUser->search({ -not=>{ username => { -in => \@ldif_users } } })->delete;
        }
    }

    # borrar role-user que no vienen en el LDIF
    if( %ldif_roleusers  ) {
        if( $user_filter ) {
            _log "Borrado de roleuser no realizado - con user_filter ($user_filter) no hay borrado";
        } else {
            _log "Borrando role-users que no vienen en el LDIF: " . join ',', sort keys %ldif_roleusers;
            my $rs_protected_roles = DB->BaliRole->search({'substr(role, 0, 1)' => '#'}, {select => 'id'});
            _log "ID ROLE protegidos por empezar por almoadilla: " . join ',', map { $_->{id} } $rs_protected_roles->hashref->all;
            for my $row ( DB->BaliRoleuser->search({ -not => { id_role=> { -in => $rs_protected_roles->as_query } }  })->hashref->all ) {
                if( ! exists $ldif_roleusers{ $row->{username} }{ $row->{id_role} }{ $row->{id_project} } ) {
                    _log "Borrando role-user: $row->{username}, id_role: $row->{id_role}, id_project: $row->{id_project}";
                    DB->BaliRoleuser->search( $row )->delete;
                }
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

# infroox: deprecated, slow
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
  master_new "project"=>$project_name=>sub{
      my $mid=shift;
      DB->BaliProject->create({mid=>$mid, name => $project_name});
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
