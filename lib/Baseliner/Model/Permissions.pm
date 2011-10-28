package Baseliner::Model::Permissions;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Data::Dumper;

=head1 NAME

Baseliner::Model::Permissions - Role and action management

=head1 DESCRIPTION

This module has several utilities to manage users' actions and roles. 

=head1 ACTIONS

=head2 action.admin.root

This is the master action that allows a user to do anything in the system.

=cut

register 'action.admin.root' => { name=>'Root action - can do anything' };

=head1 METHODS

=head2 create_role $name, $description

Creates a Role

=cut
sub create_role {
    my ($self, $name, $description ) = @_;

    $description ||= _loc( 'The %1 role', $name );

    my $role = Baseliner->model('Baseliner::BaliRole')->find_or_create({ role=>$name });
    $role->description( $description );
    $role->update;
    return $role;
}

=head2 role_exists $role_name

Returns a role row or undef if it doesn't exist.

=cut
sub role_exists {
    my ($self, $role_name ) = @_;
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    return ref $role;
}

=head2 add_action $action, $role_name

Adds an action to a role.

=cut
sub add_action {
    my ($self, $action, $role_name, %p ) = @_;
	my $bl = $p{bl} || '*';
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    if( ref $role ) {
        my $actions = $role->bali_roleactions->search({ action=>$action })->first;
        if( ref $actions ) {
            die _loc( 'Action %1 already belongs to role %2', $action, $role_name );
        } else {
            return $role->bali_roleactions->create({ action => $action, bl=>$bl });
        }
    } else {
        die _loc( 'Role %1 not found', $role_name );
    }
}

=head2 remove_action $action, $role_name

Removes an action from a role.

=cut
sub remove_action {
    my ($self, $action, $role_name, %p ) = @_;
	my $bl = $p{bl} || '*';
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    if( ref $role ) {
        my $actions = $role->bali_roleactions->search({ action=>$action })->delete;
    } else {
        die _loc( 'Role %1 not found', $role_name );
    }
}

=head2 delete_role [ id=>Int or role=>Str ]

Deletes a role by role id or by role name.

=cut
sub delete_role {
    my ( $self, %p ) = @_;
    
    if( $p{id} ) {
        my $role = Baseliner->model('Baseliner::BaliRole')->find({ id=>$p{id} });

        die _loc( 'Role with id "%1" not found', $p{id} ) unless ref $role;

        my $role_name = $role->role;
        $role->delete;
        return $role_name;
    } else {
        my @role_names;
        my $roles = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} });
        unless( ref $roles ) {
            die _loc( 'Role with id "%1" or name "%2" not found', $p{id}, $p{role} );
        } else {
            while( my $role = $roles->next ) {
                push @role_names, $role->role;
                $role->delete;
            }
        }
        return @role_names;
    }
}

=head2 grant_role username=>Str, role=>Str, [ ns=>Str, bl=>Str ]

Grants a role to a user. Optionally for a given project (ns). 

=cut
sub grant_role {
    my ($self, %p ) = @_;

    $p{ns} ||= '/';
    $p{bl} ||= '*';  #TODO not used here

    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} })->first;
    unless( ref $role ) {
        $role = $self->create_role( $p{role} )
          or die "Could not create role '$p{role}'";
    } 

    # search 
    my $row = Baseliner->model('Baseliner::BaliRoleuser')->search({
        username => $p{username},
        ns => $p{ns},
        id_role => $role->id,
    })->first;
    
    # create
    unless( ref $row ) {
        my $row = Baseliner->model('Baseliner::BaliRoleuser')->create({
            username => $p{username},
            ns => $p{ns},
            id_role => $role->id,
        });
        $row->update;
    }
    return 1 if ref $row;
}

=head2 deny_role  username=>Str, role=>Str, [ ns=>Str, bl=>Str ]

Takes a role away (revoke) from user. 

=cut
sub deny_role {
    my ($self, %p ) = @_;

    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} })->first;

    die _loc( 'Role %1 not found', $p{role} ) unless ref $role;

    my $deniable = Baseliner->model('Baseliner::BaliRoleuser')->search({
        username => $p{username},
        id_role => $role->id,
    });

    die _loc( 'User %1 does not have role %2', $p{username}, $p{role} ) unless ref $role;

    my $denied;
    while( my $row = $deniable->next ) {
        if( $p{ns} && !$p{bl} ) {
            $row->delete if ns_match( $row->ns, $p{ns} );
            $denied++; 
        }
        elsif( ! $p{ns} && $p{bl} ) {
            $row->delete if $row->bl eq $p{bl};
            $denied++; 
        }
        elsif( $p{ns} && $p{bl} ) {
            $row->delete
                if ( $row->bl eq $p{bl} && ns_match( $row->ns, $p{ns} ) );
            $denied++; 
        }
        else {
            $row->delete;
            $denied++; 
        }
    }
    return $denied;
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action   = $p{action};
    return 1 if $self->is_root( $username ) && $action ne 'action.surrogate';
    my @users = $self->list( action=> $action, ns=>$p{ns}, bl=>$p{bl} );

    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$username }, { prefetch=>['role'] } );
    rs_hashref( $rs );
	my $mail="";
	if ( my $r=$rs->next ) {
		$mail = $r->{role}->{mailbox} ;
    }

	my $ret = 0;
    $ret = scalar grep(/$mail/, @users) if $mail;
	$ret += scalar grep /$username/, @users;
    return $ret;
}


#### Ricardo (21/6/2011): Listado de proyectos para los que el usuario tiene una acci�n 
#### Javi (6/7/2011): A�ado filtro por bl [opcional] -- Puede no tener una acci�n en alg�n entorno p.ej action.job.create 

sub user_projects_with_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action   = $p{action};
    my $bl       = $p{bl}||'*';
	my $bl_filter=qq{ AND bl = '$bl' } if $bl ne '*';
    my @granted_projects = [];
    
    my @root_users = $self->list( action=> 'action.admin.root' );

	if ( grep /$username/, @root_users ) {
		@granted_projects = $self->all_projects();
	} else {
		my $db = new Baseliner::Core::DBI( { model => 'Baseliner' } );
		my @data = $db->array( qq{ 
				select distinct replace(NS, 'project/','')
				from BALI_ROLE r, BALI_ROLEUSER ru, BALI_ROLEACTION ra
				WHERE   r.ID = ru.ID_ROLE AND
	        	r.ID = ra.ID_ROLE AND 
	        	username = '$username' AND
	        	action = '$action'
				$bl_filter
	        	ORDER BY 1
			}
        );
		if ( @data && $data[0] eq '/') {
			@granted_projects = $self->all_projects();
		} else {
			@granted_projects = @data;
		}
	}
	return wantarray?@granted_projects:\@granted_projects;
}

#### Ricardo (21/6/2011): Listado de todos los proyectos
sub all_projects {
	my @projects = [];
	my $rs = Baseliner->model('Baseliner::BaliProject')->search( undef, { select=>['id'] } );
	rs_hashref($rs);
	
	@projects = map {
		$_->{id}
	} $rs->all;
	
	return @projects;
}



=head2 user_grants $username [ action=>Str, ns=>Str ]

Returns a list of roles a user has.

=cut
sub user_grants {
    my ($self, $username, %p ) = @_;
    my $root_user = $self->is_root( $username );
    my $where = {};
    $where->{username} = $username unless $root_user;
    $p{action} and $where->{action} = $p{action};
    $p{ns} and $where->{action} = $p{ns};
	my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search( $where, { prefetch=>['role'] } );
	rs_hashref( $rs );
    my @ret;
    while( my $r = $rs->next ) {
        $root_user and $r->{username} = $username;
        push @ret, $r;
    }
    if( $root_user ) {  # no duplicates
        my %grant;
        $grant{ join(',', values %$_ ) } = $_ for @ret;
        @ret = values %grant;
    }

    return @ret;
}

=head2 user_namespaces

Returns a list of ns from roleuser,
which means that there's some role in there

=cut
sub user_namespaces {
    my ($self, $username ) = @_;
    my @perms = Baseliner->model('Permissions')->user_grants( $username );
	return sort { $a cmp $b } _unique( map { $_->{ns} } @perms );
}

=head2 list

List users that have an action

     action=>Str, [ ns=>Str, bl=>Str ]

 or actions that a user has

     username=>Str, [ bl=>Str ]

=cut
sub list {
    my ( $self, %p ) = @_;
    my $ns = defined $p{ns} ? $p{ns} : 'any';
	ref $ns eq 'ARRAY' and _throw "Parameter ns: ARRAY of namespaces not supported yet.";
    my $bl = $p{bl} || 'any';

    $p{recurse} = defined $p{recurse} ? $p{recurse} : 1;
    $p{action} or $p{username} or die _loc( 'No action or username specified' );

	# if its root, gimme all actions period.
    return map { $_->{key} } Baseliner->model('Actions')->list
      if $p{username} && $self->is_root( $p{username} );

	# build query
    my $query = $p{action}
        ? { action=> [ -or => [ $p{action}, { -like => "$p{action}.%" } ] ] }
        : { username=>$p{username} };
	
	$query->{bl} = [ -or => [ $bl, '*' ] ]
		unless $bl eq 'any';

	$query->{ns} = [ -or => [ $ns, '/' ] ]
		unless $ns eq 'any';

	# search roles
    my $roles = Baseliner->model('Baseliner::BaliRole')->search(
        $query,
        { join     => ['bali_roleusers', 'bali_roleactions'],
		  prefetch=>[ $p{action} ? 'bali_roleusers' : 'bali_roleactions']
		}
    );

	$roles->result_class('DBIx::Class::ResultClass::HashRefInflator');

	# now, foreach role
    my @list;
    while( my $role = $roles->next ) {
		my $role_name = $role->{role};
		# if asked for, don't include certain roles
		next if $p{role_filter} and ! grep( /$role_name/i, _array($p{role_filter}) );
		# return either users or roles, depending on the query
		my $data= $p{action} ? $role->{bali_roleusers} : $role->{bali_roleactions};
		
        push @list,
			# map { $p{action} ? $_->{username} : $_->{action} }
            map { $p{action} ? ( $role->{mailbox} ? $role->{mailbox} : $_->{username} ) : $_->{action} }
            grep { $p{username} ? 1 : $ns eq 'any' ? 1 : ns_match( $_->{ns}, $ns) }
            _array( $data );
    }

    # recurse $self->list on parents
    if( $p{recurse} && $ns ne 'any' ) {
        my $item = Baseliner->model('Namespaces')->get( $ns );
        _throw "No he podido encontrar el item '$ns'" unless ref $item;
		if (blessed $item && $item->does('Baseliner::Role::Namespace') ) {
			for my $parent ( _array $item->parents ) {		
				next if $parent eq '/';
				push @list,
				$self->list(
					ns          => $parent,
					bl          => $bl,
					role_filter => $p{role_filter},
					recurse     => 0,
					(
						$p{action}
						? ( action => $p{action} )
						: ( username => $p{username} )
					)
				);
			}
		}
    }
    # _log "LIST: $p{username} got \n";_log Dumper _unique @list;
    return _unique @list;
}

=head2 is_root

Return true if a user has the root action C<action.admin.root>.
Or if its username is 'root'

=cut
sub is_root {
    my ( $self, $username ) = @_;
    $username or die _loc('Missing username');
    return 1 if $username eq 'root';

	return Baseliner->model('Baseliner')->dbi->value(qq{
		select count(*) 
		from bali_roleaction ra,     
		     bali_role r,     
		     bali_roleuser ru 
		where   ru.username = ?         
		        and ra.action = 'action.admin.root' 
		        and r.id = ru.id_role 
		        and r.id = ra.id_role				
	},$username);
}

=head2 role $role

Returns an array of actions for a given role.

=cut
sub role {
    my ( $self, $role ) = @_;
	$role or _throw 'Missing argument role';	
	my @roles;
    my $rs = Baseliner->model('Baseliner::BaliRole')->search({ role => $role });
    while( my $role = $rs->next ) {
		my @actions;
        my $actions = $role->bali_roleactions;
        while( my $action = $actions->next ) {
            push @actions, $action->action;
        }
		push @roles, { role=>$role->role, description=>$role->description, actions=>[ @actions ] };
    }
	return shift @roles;
}

=head2 user_roles

Returns everything a user has.

=cut
sub user_roles {
    my ( $self, $username ) = @_;
	$username or _throw 'Missing parameter username';	
	my @roles;
    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username => $username });

    while( my $r = $rs->next ) {
        my $role = $r->id_role;
        my $ns = $r->ns;
		my @actions;
        my $actions = $role->bali_roleactions;
        while( my $action = $actions->next ) {
            push @actions, $action->action;
        }
		push @roles, { role=>$role->role, ns=>$ns, description=>$role->description, actions=>[ @actions ] };
    }
	# _log "user_roles: $username got \n";_log Dumper _unique @roles;
	return @roles;
}

=head2 all_users

List all users that have roles

=cut
sub all_users {
    my ( $self ) = @_;
	my @users;
	my $rs = Baseliner->model('Baseliner::BaliRoleUser')->search;
	return unless ref $rs;
	while( my $r = $rs->next ) {
		push @users, $r->username;
	}
	return _unique @users;
}

=head2 user_has_action_fast

Checks a user has an action... only faster. 

=cut
sub user_has_action_fast {
    my ( $self, %p ) = @_;
	my $username = delete $p{username};
	return unless $username;
	return 1 if $self->is_root( $username );
	return grep { $username eq $_ } $self->list( %p );
}

sub user_projects_for_action {
    []
}

1;
