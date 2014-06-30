package Baseliner::Model::Permissions;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Data::Dumper;
use Baseliner::Sugar;
use Baseliner::Model::Users;

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
    my $role;
    if($role = mdb->role->find({ role=>$name })->next){
        mdb->role->update({ role=>$name }, {'$set' => { id=>$role->{id}, role=>$name, description=>$description } } );
    } else {
        mdb->role->insert({ id=>mdb->seq('role'), role=>$name, description=>$description });
    }
    mdb->role->find({ role=>$name })->next;
    return mdb->role->find({ role=>$name })->next;
}

=head2 role_exists $role_name

Returns a role row or undef if it doesn't exist.

=cut
sub role_exists {
    my ($self, $role_name ) = @_;
    my $role = dbm->role->find({ role=>$role_name })->next;
    return ref $role;
}

=head2 add_action $action, $role_name

Adds an action to a role.

=cut
sub add_action {
    my ($self, $action, $role_name, %p ) = @_;
    my $bl = $p{bl} || '*';
    my $role = mdb->role->find({ role=>$role_name })->next;
    if( ref $role ) {
        if(grep { $_->{action} eq $action } @{$role->{actions}}) {
            die _loc( 'Action %1 already belongs to role %2', $action, $role_name );
        } else {
            push @{ $role->{actions} }, { action => $action, bl=>$bl };
            mdb->role->update({ role=>$role->{role} }, $role ); 
            return $role;
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
    my $role = mdb->role->find({ role=>$role_name })->next;
    if( ref $role ) {
        #my $actions = $role->bali_roleactions->search({ action=>$action })->delete;
        my @actions = grep { !($action eq $_->{action} && $bl eq $_->{bl}) } @{$role->{actions}};
        $role->{actions} = \@actions;
        mdb->role->update({ id=>$role->{id} }, $role);
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
        my $role = mdb->role->find({ id=>$p{id} })->next;
        die _loc( 'Role with id "%1" not found', $p{id} ) unless ref $role;
        my $role_name = $role->{role};
        mdb->role->remove({ role=>$role_name, id=>$p{id} });
        return $role_name;
    } else {
        my @role_names;
        my @roles = mdb->role->find({ role=>$p{role} })->all;
        unless( @roles ) {
            die _loc( "Role with id '%1' or name '%2' not found", $p{id}, $p{role} );
        } else {
            foreach my $role (@roles){
                push @role_names, $role->{role};
                mdb->role->remove({ id=>$role->{id} });
            }
        }
        return @role_names;
    }
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = delete $p{action};

    if ( $p{mid} ) {
        my @return = grep { /$action/ } $self->user_actions_by_topic(%p);
        return @return;
    } else {
        push my @bl, _array $p{bl}, '*';
        return 1 if $self->is_root( $username ) && $action ne 'action.surrogate';
        return scalar grep {$action eq $_ } Baseliner->model('Users')->get_actions_from_user($username, @bl);      
    }
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_read_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = $p{action};

    return 1 if $self->is_root( $username );
    my @roles = keys ci->user->find({username => $username})->next->{project_security};

    my @actions;

    for my $role ( @roles ) {
        my @role_actions = _array(cache->get(":role:actions:$role:"));
        if (!@role_actions){
            push @actions, map { $_->{action} } @{mdb->role->find({id=>$role})->next->{actions}};
            cache->set(":role:actions:$role:",\@actions);
            #_debug "NO CACHE for :role:actions:$role:";
        } else {
            push @actions, @role_actions;
            #_debug "CACHE HIT for :role:actions:$role:";
        }
        @actions = grep { $_ eq $action } @actions;
    }

    my $has_action;
    if (scalar @roles == scalar @actions) {
     $has_action = 1;
    } else {
     $has_action = 0;
    }
    return $has_action;
}

sub user_has_any_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = $p{action};
    my $bl = $p{bl} // '*';  
    return 1 if $self->is_root( $username );
    my @actions = $self->user_actions_list( %p );
    return scalar @actions;
}

sub user_actions_list {
    my ( $self, %p ) = @_;
    _check_parameters( \%p, qw/username/ );
    my $username = $p{username};
    my $actionSQL = $p{action};
    my $action   = delete $p{action} // qr/.*/;
    my $mid = $p{mid};
    my $regexp_action;

    if ( !ref $action ) {
        $action =~ s/\./\\\./g;
        $action =~ s/%/\.\*/g;
        $regexp_action = qr/$action/;
    } elsif ( ref $action eq 'Regexp' ) {
        $regexp_action = $action;
    } else {
        return ();
    }
    push my @bl, _array $p{bl}, '*';
    my @actions;
    if ( $self->is_root( $username ) ) {
        @actions = map { $_->{key} } Baseliner->model( 'Actions' )->list;
    } elsif ( $mid ) {
        @actions = $self->user_actions_by_topic( %p );
    } else {
        @actions = Baseliner->model('Users')->get_actions_from_user( $username, @bl );
    } ## end else [ if ( $self->is_root( $username...))]
    return grep { $_ =~ $regexp_action } @actions;
} ## end sub user_actions_list

sub user_actions_by_topic {
    my ( $self, %p ) = @_;

    my @return;

    my @roles = $self->user_roles_for_topic( %p );
    for my $role ( @roles ) {
        my @actions = _array(cache->get(":role:actions:$role:"));
        if ( !@actions ) {
           @actions = map { $_->{action} } @{mdb->role->find({id=>$role+0})->next->{actions}};
           cache->set(":role:actions:$role:",\@actions);
        } else {
            #_debug "CACHE HIT for :role:actions:$role:";
        }
        push @return, @actions;
    }
    return _unique @return;
}

=head2 user_has_project( username=>Str, project_name=>Str | project_id )

Returns an array of ns for the projects the user has access to.

=cut
sub user_has_project {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};
    my $qr=qr{^\/$};
    return 1 if $self->is_root( $p{username} );
    if( my $name = delete $p{project_name} or delete $p{project}) {
        my @ns=$self->user_projects_names( %p );
        return 1 if scalar grep /$qr/, @ns;
        return scalar grep /^$name$/, @ns;
    } elsif( my $id = delete $p{project_id} ) {
        my @ns=$self->user_projects_ids( %p );
        return 1 if scalar grep /$qr/, @ns;
        return scalar grep /$id/,@ns
    } # añadir el if para project
    return 0;
}

=head2 user_projects( username=>Str )

Returns an array of ns for the projects the user has access to, 
ie, if the user has ANY role in them.

=cut
sub user_projects {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};
    _throw 'with_role not supported anymore' if exists $p{with_role};
    return map{ "project/$$_{mid}" } ci->project->find->fields({mid=>1})->all if $self->is_root($p{username});
    my @ret;
    my $project_security = ci->user->find({ username=>$p{ username } })->next->{project_security};
    my @id_roles = keys $project_security;
    foreach my $id_role (@id_roles){
        my @project_types = keys $project_security->{$id_role};
        foreach my $project_type (@project_types){
            push @ret, "project/$_" for _unique _array( $project_security->{$id_role}->{$project_type} );
        }
    }
    return _unique( @ret );
}

=head2 user_projects_ids( username=>Str )

Returns an array of project ids for the projects the user has access to.

=cut
sub user_projects_ids {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};
    return map{ $$_{mid} } ci->project->find->fields({mid=>1})->all if $self->is_root($p{username});
    return _unique map { values $_->{project} } values ci->user->find({ username=>$p{username} })->next->{project_security};
}

=head2 user_projects_ids_with_collection( username=>Str )

Returns an array of project ids for the projects the user has access to with their collection

=cut


sub user_projects_ids_with_collection {
    my ( $self, %p ) = @_;
    my $sec_projects;
    my $with_role = $p{with_role} // 0;
    my $username = $p{username};
    $p{roles} //= '';
    my @roles = split(/,/, $p{roles} );
    my %ret;
    my $user = ci->user->find({ username=>$username })->next;
    my $project_security = $user->{project_security};
    if(!@roles){
        @roles = keys $project_security;
    }
    my @user_roles = keys $user->{project_security};

    foreach my $id_role (@user_roles){
        foreach my $actual_id (@roles){
            if($id_role == $actual_id+0){
                my @project_types = keys $project_security->{$id_role};
                foreach my $project_type (@project_types){
                    map { $ret{$id_role}{$project_type}{$_} = 1 } @{$project_security->{$id_role}->{$project_type}};
                }
            }
        }
    }
    return \%ret;
}

sub user_can_topic_by_project {
    my ($self,%p)=@_; 
    my $username = $p{username};
    my $mid = $p{mid} // _fail('Missing mid');
    return 1 if $self->is_root($username);
    my @proj_coll_roles = $self->user_projects_ids_with_collection(%p);
    my $where = { mid=>"$mid" };
    my @ors;
    for my $proj_coll_ids ( @proj_coll_roles ) {
        my $wh = {};
        while( my ($k,$v) = each %{ $proj_coll_ids || {} } ) {
            $wh->{"_project_security.$k"} = { '$in'=>[ undef, keys %{ $v || {} } ] } ;
        }
        push @ors, $wh;
    }
    $where->{'$or'} = \@ors;
    return !!mdb->topic->find($where)->count;
}

sub user_roles_for_topic {
    my ($self,%p)=@_; 
    my $username = $p{username};
    my $mid = $p{mid};
    my $proj_coll_roles = $self->user_projects_ids_with_collection(%p, with_role => 1);
    my @roles;
    for my $role ( keys %{$proj_coll_roles} ) {
        my $where = { mid=>"$mid" };
        my $proj_coll_ids = $proj_coll_roles->{$role};
        while( my ($k,$v) = each %{ $proj_coll_ids || {} } ) {
            $where->{"_project_security.$k"} = { '$in'=>[ undef, keys %{ $v || {} } ] }; 
        }
        #_log _dump $where;
        push @roles, $role if !!mdb->topic->find($where)->count;
    }
    return @roles;
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
    if( $self->is_root($username) ) {
        return map { $$_{mid} } ci->project->find->fields({ mid=>1, _id=>0 })->all;
    }
    my $user = ci->user->find({ username=>$username })->next;
    my @id_roles = keys $user->{project_security};
    @id_roles = map { $_+0 } @id_roles;
    my @roles = mdb->role->find({ id=> { '$in'=>\@id_roles } })->fields( { _id=>0 } )->all;
    my @res;
    foreach my $role (@roles){
        if(grep { $_->{action} eq $action and $_->{bl} eq $bl } @{$role->{actions}}){
            push @res, values $user->{project_security}->{$role->{id}};
        }
    }
    return _unique map { values $_ } @res;
}


sub all_projects {
    map { $_->{mid} } ci->project->find()->fields({ _id=>0, mid=>1 })->all;
}

=head2 user_grants $username [ action=>Str, ns=>Str ]

Returns a list of roles a user has.

=cut
sub user_grants {
    my ($self, $username, %p ) = @_;
    my @ret;
    my $user = ci->user->find({ username=>$username })->next;
    my $project_security = $user->{project_security};
    my @id_roles = keys $project_security;
    @id_roles = map { $_+0 } @id_roles;
    my @roles = mdb->role->find({ id=> { '$in'=>\@id_roles } })->fields( { _id=>0, actions=>0 } )->all;
    foreach my $id_role (keys $project_security ){
        foreach my $project_type (keys $project_security->{$id_role}){
            foreach my $id_project (@{$project_security->{$id_role}->{$project_type}}){
                my ($actual_role) = grep { $_->{id} eq $id_role } @roles;  
                my %role_hash = %$actual_role;
                push @ret, { id_project=>$id_project, ns=>"$project_type/$id_project", id_role=>$id_role, role=>\%role_hash, username=>$user->{username} };
            }
        }
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
    my @ret;
    my $cache_key = ["user:permission:list:$p{username}:", %p ];
    my $cached = cache->get( $cache_key );
    if( ref $cached eq 'ARRAY' ) {
        return @$cached;
    }
    my $bl = $p{bl} || 'any';
    my $username = $p{username};
    my $action = $p{action};

    $p{action} or $p{username} or die _loc( 'No action or username specified' );

    # if its root, gimme all actions period.
    if( $p{username} && $self->is_root( $p{username} ) ) {
        my @ret = map { $_->{key} } Baseliner->model('Actions')->list;
        cache->set( $cache_key, \@ret );
        return @ret;
    }
    
    if($username){
        @ret = Baseliner->model('Users')->get_actions_from_user($username, ($bl));
    }else{
        my @users = ci->user->find->all;
        my @roles = mdb->role->find->all;
        foreach my $user (@users){
            my @id_roles = keys $user->{project_security};
            @id_roles = map { 0+$_ } @id_roles;
            my @user_roles = grep { $_->{id} ~~ @id_roles } @roles;
            foreach my $user_role (@user_roles){
                my @actions;
                if($bl eq 'any'){
                    @actions = map { $_->{action} } @{$user_role->{actions}};
                }else{
                    foreach my $act (@{$user_role->{actions}}){
                        if($act->{bl} eq $bl){
                            push @actions, $act->{action};
                        }
                    }
                }
                if($action ~~ @actions){
                    push @ret, $user->{mid};
                }
            }
        }
    }
    return _unique @ret;
}

=head2 is_root

Return true if a user has the root action C<action.admin.root>.
Or if its username is 'root'

=cut
our $root_username;

sub is_root {
    my ( $self, $username ) = @_;
    $username or die _loc('Missing username');
    my $cached_key = "user:is_root:$username:";
    my $cached = cache->get($cached_key);
    return $cached if defined $cached;
    my $is_root = 
        $username eq 'root' 
        || scalar( grep { 'action.admin.root' eq $_ } Baseliner->model('Users')->get_actions_from_user($username) );
    cache->set( $cached_key, $is_root );
    return $is_root;
}

=head2 user_roles

Returns everything a user has.

=cut
sub user_roles {
    my ( $self, $username ) = @_;
    my @id_roles = $self->user_role_ids($username);
    my @roles;
    foreach my $id (@id_roles){
        my $role = mdb->role->find({ id=>0+$id })->next;
        my @actions = map { $_->{action} } @{ $role->{actions} };
        push @roles, { id=>$role->{id}, role=>$role->{role}, description=>$role->{description}, actions=>[ @actions ] };
    }
    return @roles;
}

sub user_role_ids {
    my ( $self, $username ) = @_;
    $username or _throw 'Missing parameter username';	
    my $u = ci->user->find_one({ username=>$username });
    return $u ? keys $u->{project_security} : ();
}

=head2 all_users

List all users that have roles

=cut
sub all_users {
    my ( $self ) = @_;
    my @ret;
    my @users = ci->user->find->all;
    foreach my $user (@users){
        if (keys $user->{project_security}){
            push @ret, $user->{username};
        }
    }
    @ret;
}

sub users_with_roles {
    my ( $self, %p ) = @_;
    my @roles = _array $p{roles};
    my $include_root = $p{include_root} // 1;
    my $mid = $p{mid};
    my @users;

    my $topic           = mdb->topic->find_one( { mid => $mid } );
    my $proj_coll_roles = $topic->{_project_security};

    my $where;
    my @ors;
    
    if ( $proj_coll_roles ) {    
        for my $role (@roles) {
            my @ands;
            my $wh = {};
            $wh->{"project_security.$role"} = { '$ne' => undef };
            push @ands, $wh;
            for my $proj ( keys %{$proj_coll_roles} ) {
                $wh->{"project_security.$role.$proj"} = 
                  { '$in' => [ undef, _array $proj_coll_roles->{$proj} ] };
                push @ands, $wh;
            }
            push @ors, { '$and' => \@ands };
        }
    } else {
        for my $role ( @roles ) {
            my $wh;
            $wh->{"project_security.$role"} = { '$ne' => undef };
            push @ors, $wh;
        }
    }
    $where->{'$or'} = \@ors;
    @users = map { $_->{name} } BaselinerX::CI::user->search_cis(%$where);

    my @root_users;
    if ( $include_root ) {      
        my @root_ids;
        my @all_roles = mdb->role->find->all;
        foreach my $role (@all_roles){
             if(grep { $_->{action} eq 'action.admin.root' } @{$role->{actions}}){
                push @root_ids, $role->{id};
             }
        }
        my @where = map { { "project_security.$_"=>{'$exists'=> '1' } } } @root_ids;
        @root_users = map { $_->{name} } ci->user->find({'$or' =>\@where})->all;

    }
    return @users, @root_users;
}

1;
