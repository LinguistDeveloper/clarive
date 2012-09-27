package Baseliner::Model::Permissions;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Data::Dumper;
use Baseliner::Sugar;

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


=head2 user_baselines_for_action username=>Str, action=>Str

Returns a list of baslines for a username and action.

=cut
sub user_baselines_for_action  {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines_no_root();
    my $is_root = $self->is_root( $p{username} );
    foreach my $n ( @bl_list ) {
        next unless $is_root or $self->user_has_action( username=>$p{username}, action=>$p{action}, bl=>$n->{bl} );
        my $arr = [ $n->{bl}, $n->{name} ];
        push @bl_arr, $arr;
    }
    return @bl_arr;
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = $p{action};
    push my @bl, _array $p{bl}, '*';
    
    return 1 if $self->is_root( $username ) && $action ne 'action.surrogate';

    return Baseliner->model('Baseliner')->dbi->value(qq{
        select count(*)
        from bali_roleuser ru, bali_roleaction ra
        where ru.USERNAME = ?
          and ru.ID_ROLE = ra.ID_ROLE
          and ra.ACTION = ?
          and ra.bl in (} . join( ',', map { '?' } @bl ) . qq{)
    },$username, $p{action}, @bl);
}

# sub user_has_action {
    # my ($self, %p ) = @_;
    # _check_parameters( \%p, qw/username action/ ); 
    # my $username = $p{username};
    # my $action   = $p{action};
    # return 1 if $self->is_root( $username ) && $action ne 'action.surrogate';
    # my @users = $self->list( action=> $action, ns=>$p{ns}, bl=>$p{bl} );

    # my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$username }, { prefetch=>['role'] } );
    # rs_hashref( $rs );
    # my $mail="";
    # if ( my $r=$rs->next ) {
        # $mail = $r->{role}->{mailbox} ;
    # }

    # my $ret = 0;
    # $ret = scalar grep(/$mail/, @users) if $mail;
    # $ret += scalar grep /$username/, @users;
    # return $ret;
# }

=head2 user_has_project( username=>Str, project_name=>Str | project_id )

Returns an array of ns for the projects the user has access to.

=cut
sub user_has_project {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};

    # is root?
    return 1 if $self->is_root( $p{username} );

    if( my $name = delete $p{project_name} ) {
        return scalar grep /^$name$/, $self->user_projects_names( %p );
    } elsif( my $id = delete $p{project_id} ) {
        return scalar grep /$id/, $self->user_projects_ids( %p );
    }
    return 0;
}

=head2 user_projects( username=>Str )

Returns an array of ns for the projects the user has access to, 
ie, if the user has ANY role in them.

=cut
sub user_projects {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{ username };
    _array( Baseliner->model( 'Baseliner::BaliRoleuser' )
        ->search( { username => $p{username} }, { select => [ 'ns' ] } ) ~~ sub {
        my $rs = shift;
        rs_hashref( $rs );
        [ grep { length } _unique map { $_->{ ns } } $rs->all ];
    } );
}

sub user_projects_query {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{ username };
    Baseliner->model( 'Baseliner::BaliRoleuser' )
        ->search( { username => $p{username} },
        { distinct=>1, select => [ 'id' ] } )->as_query ;
}

=head2 user_projects_ids( username=>Str )

Returns an array of project ids for the projects the user has access to.

=cut
sub user_projects_ids {
    my ( $self, %p ) = @_;
    _unique map { s{^(.*?)/}{}g; $_ } $self->user_projects( %p );
}

=head2 user_projects_names( username=>Str )

Returns an array of project names to which the user has access.

=cut
sub user_projects_names {
    my ( $self, %p ) = @_;
    my @ns = $self->user_projects( %p );
    my @ids=map{ my ($d,$it)=ns_split($_); $it } _array @ns;
    my $rs = Baseliner->model('Baseliner::BaliProject')->search({ mid=>\@ids });
    rs_hashref( $rs );
    my $parentcache;
    my @ret;
    while( my $r = $rs->next ) {
    if (! $r->{id_parent} ) {
        push @ret, qq{application/$r->{name}};
    } else {
        if ( ! $parentcache->{$r->{id_parent}} ) {
            my $parent = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$r->{id_parent} } )->first;
            $parent and $parentcache->{$parent->mid}={
                name    =>$parent->name,
                parent  =>$parent->id_parent,
                id      =>$parent->mid
                };
            }
        if ($r->{nature}) {
            if ( ! $parentcache->{$parentcache->{$r->{id_parent}}->{parent}} ) {
                my $cam = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$parentcache->{$r->{id_parent}}->{parent} } )->first;
                $cam and $parentcache->{$cam->mid}={
                    name   =>$cam->name,
                    parent =>$cam->id_parent,
                    id     =>$cam->mid
                    };
                }
            push @ret, qq{nature/$parentcache->{$parentcache->{$r->{id_parent}}->{parent}}->{name}/$parentcache->{$r->{id_parent}}->{name}/$r->{nature}} ;
        } elsif ($r->{id_parent}) {
            push @ret, qq{subapplication/$parentcache->{$r->{id_parent}}->{name}/$r->{name}};
            }
        }
    }
    return sort { $a cmp $b } _unique( @ret );
    # _unique map { $_->{name} } $rs->all;
}

=head2 user_projects_with_action( username=>Str, action=>[ ... ] )

List of projects for which a user has a given action.

=cut

sub user_projects_with_action {
    my ( $self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ );
    my $username  = $p{username};
    my $action    = $p{action};
    my $bl        = $p{bl} || '*';
    my $level     = $p{level} || 'all';
    my $bl_filter = '';
    $bl_filter = qq{ AND ra.bl in ('$bl','*') } if $bl ne '*';
    my @granted_projects = [];

    if ( $self->is_root($username) ) {
        @granted_projects = $self->all_projects();
    } else {
        my $db = new Baseliner::Core::DBI( { model => 'Baseliner' } );
        my @data = $db->array(
            qq{
                select distinct p.mid
                from BALI_ROLE r, BALI_ROLEUSER ru, BALI_ROLEACTION ra, BALI_PROJECT p
                WHERE  r.ID = ru.ID_ROLE AND
                r.ID = ra.ID_ROLE AND
                username = ? AND
                action = ? AND
                 (
                       ( ru.NS like 'project/%' AND p.mid = to_number( replace( ru.NS, 'project/','' ) ) )
                       OR
                       ( ru.NS = '/' )
                    ) AND
                p.id_parent IS NULL
                $bl_filter
                ORDER BY 1
            }, $username, $action
        );
        if ( @data && $data[0] eq '/' ) {

            # XXX does not apply anymore in any case
            @granted_projects = $self->all_projects();
        } else {

            sub parent_ids {
                my $rs = shift;
                rs_hashref($rs);
                map { $_->{mid} } $rs->all;
            }
            my @natures;
            my @subapls;
            @granted_projects = @data;
            if ( $level eq 'all' || $level ge 2 ) {
                @natures    = parent_ids(
                    scalar Baseliner->model('Baseliner::BaliProject')
                        ->search( { id_parent => \@data, nature => { '=', undef } }, { select => [qw/mid/] } ) );
                @granted_projects = _unique @granted_projects, @subapls
            }

            if ( $level eq 'all' || $level ge 3 ) {
                @subapls    = parent_ids(
                    scalar Baseliner->model('Baseliner::BaliProject')
                        ->search( { id_parent => \@subapls, nature => { '!=', undef } }, { select => [qw/mid/] } ) );
                @granted_projects = _unique @granted_projects, @natures
            }
            @granted_projects =_unique @granted_projects;
        }
    }
    return wantarray ? @granted_projects : \@granted_projects;
}


#### Ricardo (21/6/2011): Listado de todos los proyectos
sub all_projects {
    my @projects = [];
    my $rs = Baseliner->model('Baseliner::BaliProject')->search( undef, { select=>['mid'] } );
    rs_hashref($rs);
    
    @projects = map {
        $_->{mid}
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
        $grant{ join(',', grep { defined } values %$_ ) } = $_ for @ret;
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

=head2 user_namespaces_name

Returns a list of applications from roleuser,
which means that there's some role in there

=cut
sub user_namespaces_name {
    my ($self, $username ) = @_;
    my @perms = Baseliner->model('Permissions')->user_grants( $username );
    my @appId;

    foreach (@perms) {
        push @appId, $1 if ($_->{ns} =~ m{project/(.+)});
        }
        
    my $rs = Baseliner->model('Baseliner::BaliProject')->search( { mid=>{ 'in' => [ _unique @appId ] } } );
    rs_hashref( $rs );
    my @ret;
    my $parentcache;
    while( my $r = $rs->next ) {
        if (! $r->{id_parent} ) {
            push @ret, qq{application/$r->{name}};
        } else {
            if ( ! $parentcache->{$r->{id_parent}} ) {
                my $parent = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$r->{id_parent} } )->first;
                $parent and $parentcache->{$parent->mid}={
                    name=>$parent->name,
                    parent=>$parent->id_parent,
                    id=>$parent->mid
                    };
                }
            if ($r->{nature}) {
                if ( ! $parentcache->{$parentcache->{$r->{id_parent}}->{parent}} ) {
                    my $cam = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$parentcache->{$r->{id_parent}}->{parent} } )->first;
                    $cam and $parentcache->{$cam->mid}={
                        name=>$cam->name,
                        parent=>$cam->id_parent,
                        id=>$cam->mid
                        };
                    }
                push @ret, qq{nature/$parentcache->{$parentcache->{$r->{id_parent}}->{parent}}->{name}/$parentcache->{$r->{id_parent}}->{name}/$r->{nature}} ;
            } elsif ($r->{id_parent}) {
                push @ret, qq{subapplication/$parentcache->{$r->{id_parent}}->{name}/$r->{name}};
                }
            }
        }

    return sort { $a cmp $b } _unique( @ret );
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
            map { $p{action} ? ( $role->{mailbox} ? split ",",$role->{mailbox} : $_->{username} ) : $_->{action} }
            
            ####
            # Ricardo 2011/11/03 ... no hace falta quitar los ns.  Ya están filtrados en la query
            #
            #grep { $p{username} ? 1 : $ns eq 'any' || $ns eq '/' ? 1 : ns_match( $_->{ns}, $ns) }
            #####
            
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
    return 1 if $username eq 'root' || $username eq config_value('root_username'); 

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
        push @roles, { role=>$role->role, ns=>$ns, id_project=>$r->id_project, description=>$role->description, actions=>[ @actions ] };
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

1;
