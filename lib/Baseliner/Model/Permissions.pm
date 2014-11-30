package Baseliner::Model::Permissions;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Data::Dumper;
use Baseliner::Sugar;
use Baseliner::Model::Users;
use Try::Tiny;
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
# XXX deprecated - not used anywhere? strange role name based creation
sub create_role {
    my ($self, $name, $description ) = @_;

    $description ||= _loc( 'The %1 role', $name );
    my $role = mdb->role->find_one({ role=>$name });
    if($role ){
        mdb->role->update({ role=>$name }, {'$set' => { id=>$role->{id}, role=>$name, description=>$description } } );
    } else {
        mdb->role->insert({ id=>mdb->seq('role'), role=>$name, description=>$description });
    }
    return mdb->role->find_one({ role=>$name });
}

=head2 role_exists $role_name

Returns a role row or undef if it doesn't exist.

=cut
sub role_exists {
    my ($self, $role_name ) = @_;
    return !! mdb->role->find_one({ role=>$role_name },{ _id=>1 });  # faster than count
}

=head2 add_action $action, $role_name

Adds an action to a role.

=cut
# XXX deprecated - not used anywhere? strange role name based creation
sub add_action {
    my ($self, $action, $role_name, %p ) = @_;
    my $bl = $p{bl} || '*';
    my $role = mdb->role->find_one({ role=>$role_name });
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
# XXX deprecated - not used anywhere? strange role name based creation
sub remove_action {
    my ($self, $action, $role_name, %p ) = @_;
    my $bl = $p{bl} || '*';
    my $role = mdb->role->find_one({ role=>$role_name });
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
# XXX deprecated - not used anywhere? strange role name based creation
sub delete_role {
    my ( $self, %p ) = @_;
    
    if( $p{id} ) {
        my $role = mdb->role->find_one({ id=>$p{id} });
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
    my $ret = 0;
    return 1 if $self->is_root( $username );

    if ( $p{mid} ) {
        my @return = grep { /$action/ } _array($self->user_actions_by_topic(%p)->{positive});
        $ret = !!@return;
    } else {
        push my @bl, _array $p{bl}, '*';
        return 1 if $username eq 'root';  # root can surrogate always
        return 1 if $self->is_root( $username ) && $action ne 'action.surrogate';
        $ret = scalar grep {$action eq $_ } Baseliner->model('Users')->get_actions_from_user($username, @bl);      
    }
    
    if( $p{fail} && !$ret ) {
        _fail _loc 'User %1 does not have permissions to action %2', $username, $action;
    }
    return $ret;
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_read_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = $p{action};

    return 0 if $self->is_root( $username );
    my @roles = keys ci->user->find_one({username => $username},{ project_security=>1 })->{project_security};

    my @actions;

    for my $role ( @roles ) {
        my @role_actions = _array(cache->get(":role:actions:$role:"));
        if (!@role_actions){
            push @actions, map { $_->{action} } @{mdb->role->find_one({id=>$role},{ actions=>1 })->{actions}};
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
        @actions = _array($self->user_actions_by_topic( %p )->{positive});
    } else {
        @actions = Baseliner->model('Users')->get_actions_from_user( $username, @bl );
    } ## end else [ if ( $self->is_root( $username...))]
    return grep { $_ =~ $regexp_action } @actions;
} ## end sub user_actions_list

sub user_actions_by_topic {
    my ( $self, %p ) = @_;

    my @return;

    my @roles = $self->user_roles_for_topic( %p );

    my %actions_all = map { $_->{id} => [ map { $_->{action} } _array($_->{actions})] } mdb->role->find({ id => mdb->in(@roles)},{ id => 1, actions => 1})->all;
    my %all_negative_actions = map { $_ => [ grep { /\.read$/ } _array($actions_all{$_}) ] } keys %actions_all;

    my @positive_actions = _unique(map { grep { !/\.read$/} _array($actions_all{$_}) } keys %actions_all);
    my @all_keys = keys %actions_all;

    my @negative_actions;

    if ( @all_keys ) {
        @negative_actions = _array($all_negative_actions{$all_keys[0]});

        for my $i ( 1 .. scalar(keys %all_negative_actions) - 1) {
            my @role_negative_actions = _array($all_negative_actions{$all_keys[$i]});
            @negative_actions = Array::Utils::intersect(@negative_actions, @role_negative_actions)
        }
        @negative_actions = _unique(@negative_actions);
    }
    #map {} mdb->role->find({ id => mdb->in(@roles)},{ id => 1, actions => 1})->all     
    # my %roles_actions = map { $$_{id}=>[ map { $$_{action} } grep { defined } _array($$_{actions}) ] } 
    #     mdb->role->find({ id=>mdb->in(@roles) },{ id=>1, actions=>1 })->all;
    
    # for my $role ( @roles ) {
    #     my @actions = _array(cache->get(":role:actions:$role:"));
    #     try{
    #         if ( !@actions ) {
    #            @actions = _array( $roles_actions{$role} ); 
    #            cache->set(":role:actions:$role:",\@actions);
    #         }
    #     }catch{};
    #     push @return, @actions;
    # }
    return { positive => \@positive_actions, negative => \@negative_actions};
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
    my $project_security = ci->user->find_one({ username=>$p{ username } },{ project_security=>1 })->{project_security};
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

    #return _unique map { values $_->{project} } values ci->user->find_one({ username=>$p{username} })->{project_security};
    my $user = ci->user->find_one({ username=>$p{username} });
    if ($user) {
        my $project_security = $user->{project_security} ? $user->{project_security} : undef;
        if ($project_security){
            my @projects;
            return _unique map {  values $_->{project}  } grep { $_->{project} } values %{$project_security};
        }
    }else{
        return undef
    }    
}

=head2 user_projects_ids_with_collection( username=>Str )

Returns an array of project ids for the projects the user has access to with their collection

=cut


sub user_projects_ids_with_collection {
    my ( $self, %p ) = @_;
    my $cache_key = { %p, d=>'topic' };
    my $with_role = $p{with_role} // 0;
    defined && return( $with_role ? $_ : values(%$_) ) for cache->get($cache_key);
    my $sec_projects;
    my $username = $p{username};
    $p{roles} //= '';
    my @roles = split(/,/, $p{roles} );
    my %ret;
    my $user = ci->user->find_one({ username=>$username },{ project_security=>1 });
    my $project_security = $user->{project_security};
    if(!@roles){
        @roles = keys $project_security;
    }
    my @user_roles = keys $user->{project_security};

    foreach my $id_role (@user_roles){
        foreach my $actual_id (@roles){
            if($id_role eq $actual_id){
                my @project_types = keys $project_security->{$id_role};
                foreach my $project_type (@project_types){
                    map { $ret{$id_role}{$project_type}{$_} = 1 } @{$project_security->{$id_role}->{$project_type}};
                }
            }
        }
    }
    cache->set($cache_key,\%ret);
    return $with_role ? \%ret : values %ret;
}

=head2 build_project_security

Generates a mongo where query for the topic collection
from the user project_security.

    @filter_categories - limit categories to this list, otherwise 
      queries for all lists will be generated

The complexity here with roles comes from the fact
that roles' actions allow/deny user access to certain topic
categories only. So we have to multiply:

     project collection x category

=cut
sub build_project_security {
    my ($self,$where,$username,$is_root, @filter_categories) = @_;
    $is_root //= $self->is_root( $username );
    return if !$username || $is_root;
    # TODO stop using category names in permissions
    my %all_categories = map { _name_to_id($_->{name}) => $_->{id} } mdb->category->find->fields({ name=>1, id=>1 })->all;
    my $user_security = $self->user_projects_ids_with_collection( username => $username, with_role=>1);
    my @ors;
    my %cat_filter = map { $_ => '' } @filter_categories;
    my %role_actions = map { $$_{id}=>$$_{actions} } 
        mdb->role->find({ id=>mdb->in(keys $user_security), 'actions.action'=> qr/^action.topics\./  })
        ->fields({ id=>1, actions=>1 })->all;

    # iterate user security
    while ( my ( $id_role, $colls ) = each %$user_security ) {
        my $wh;
        my $count = scalar keys %{ $colls || {} };
        my @actions_by_idrole = map { $_->{action} } _array( $role_actions{$id_role} );
        
        my %categories_for_role;
        for my $action (@actions_by_idrole) {
            my ($category) = $action =~ /action\.topics\.(.*?)\./;
            $categories_for_role{ $all_categories{$category} }=1 if $category && exists $all_categories{$category};
        }
        my @filtered_categories = grep { exists $cat_filter{$_} } keys %categories_for_role if @filter_categories;
        while ( my ( $coll, $collmid ) = each %{ $colls || {} } ) {
            if (@filter_categories) { 
                next unless @filtered_categories;
                $wh->{'category.id'} = { '$in' => \@filtered_categories } ;
            } else {
                my @cfr = keys %categories_for_role;
                next unless @cfr;
                $wh->{'category.id'} = { '$in' => \@cfr };
            }
            if ( $coll eq 'project' && $count gt 1 ) {
                # lax: if collection is project then topics with no project can be seen by all
                $wh->{"_project_security.$coll"} = { '$in' => [ undef, keys %{ $collmid || {} } ] };
            } else {
                # strict: if collection is NOT project, then security is tight, no topics seen
                $wh->{"_project_security.$coll"} = { '$in' => [ keys %{ $collmid || {} } ] };
            }
        } 
        push @ors, $wh if $wh;
    } 
    
    my $where_undef = { '_project_security' => undef };
    push @ors, $where_undef;
    $where->{'$or'} = \@ors;
    if ($where) { 
        my $last_where = $where;
        $where->{'$or'} = \@ors;
        for my $item ( _array $last_where ) {
            while ( my ( $k, $v ) = each %{ $item || {} } ) {
                $where->{$k} = $v;
            }
        }
    }
}

sub user_can_topic_by_project {
    my ($self,%p)=@_; 
    my $username = $p{username};
    my $mid = $p{mid} // _fail('Missing mid');

    return 1 if $self->is_root($username);
    my @actions = _array($self->user_actions_by_topic( %p )->{positive});
    my $action = "action.topics."._name_to_id(mdb->topic->find_one({mid=>"$mid"},{category=>1})->{category}->{name});
    
    return grep { /^$action\./ } @actions;

}
# sub user_can_topic_by_project {
#     my ($self,%p)=@_; 
#     my $username = $p{username};
#     my $mid = $p{mid} // _fail('Missing mid');
#     return 1 if $self->is_root($username);
#     my $where = {};
#      my $is_root = $self->is_root( $username );
#      my @categories;
#      push @categories, mdb->topic->find_one({mid=>"$mid"})->{id_category};
#      $where->{'category.id'} = { '$in' => [ _unique @categories ] };
#      $where->{mid} = $mid;
#      if( $username && ! $is_root){
#          $self->build_project_security( $where, $username, $is_root, @categories );
#      }
#     return !!mdb->topic->find_one($where,{ _id=>1 });  # faster than count
# }

sub user_roles_for_topic {
    my ($self,%p)=@_; 
    my $username = $p{username} // _fail "Missing username";
    my $mid = $p{mid} // '';#_fail "Missing mid" ;
    use Array::Utils;
    my $user_security = $p{user_security} // ci->user->find_one( {name => $username}, { project_security => 1, _id => 0} )->{project_security};
    my $topic_security = $p{topic_security};
    $topic_security = mdb->topic->find_one( {mid => "$mid"}, { _project_security => 1, _id => 0} )->{_project_security} if !$topic_security && $mid;

    my @roles_for_topic;

    if ( $topic_security ) {
        my @topic_sec = keys %$topic_security;
        ROLE: for my $role ( keys %$user_security ) {
            my $role_sec_all = $user_security->{$role};
            my $role_ok = 1;
            my @role_sec = keys %$role_sec_all; 
            # if ( Array::Utils::array_minus(@role_sec, @topic_sec) ) {
            #     #say "El role $role no tiene derechos";
            #     next;
            # } else {
            #     #say "El role $role puede que sí tenga derechos";
            # }
            my @common_sec = Array::Utils::intersect(@role_sec, @topic_sec);
            for my $sec ( @common_sec ) {
                my @sec_for_role = _array($role_sec_all->{$sec});
                my @sec_for_topic = _array($topic_security->{$sec});
                if ( !Array::Utils::intersect( @sec_for_role, @sec_for_topic) ) {
                    #say "El role $role no tiene derechos por $sec";
                    next ROLE;
                }
            }
            push @roles_for_topic, $role;
        }
    } else {
        @roles_for_topic = keys %$user_security;
    }

    return @roles_for_topic;
}

sub user_roles_for_topic_old {
    my ($self,%p)=@_; 
    my $username = $p{username};
    my $mid = $p{mid} // '';
    my $is_root = $self->is_root( $username );
    my $proj_coll_roles = $self->user_projects_ids_with_collection(%p, with_role => 1);
    my @roles;
    for my $role ( keys %{$proj_coll_roles} ) {
        my $where = { mid=>"$mid" };
        my @categories;
        if ($mid){
            my $id_category = mdb->topic->find_one({mid=>"$mid"},{ id_category=>1 })->{id_category};
            push @categories, $id_category if ($id_category);
        }
        $where->{'category.id'} = { '$in' => [ _unique @categories ] };
        if( $username && ! $is_root){
            $self->build_project_security( $where, $username, $is_root, @categories );
        }
        push @roles, $role if !!mdb->topic->find_one($where,{ _id=>1 });
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
    my $user = ci->user->find_one({ username=>$username },{ project_security=>1 });
    my @id_roles = keys $user->{project_security};
    @id_roles = map { $_ } @id_roles;
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
    my $user = ci->user->find_one({ username=>$username },{ project_security=>1 });
    my $project_security = $user->{project_security};
    my @id_roles = keys $project_security;
    @id_roles = map { $_ } @id_roles;
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
    my @perms = $self->user_grants( $username );
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
    my $bl = $p{bl} || '*';
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
        my @users = ci->user->find->fields({ mid=>1, project_security=>1 })->all;
        my @roles = mdb->role->find->all;
        foreach my $user (@users){
            my @id_roles = keys $user->{project_security};
            @id_roles = map { $_ } @id_roles;
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
        my $role = mdb->role->find_one({ id=>$id });
        my @actions = map { $_->{action} } @{ $role->{actions} };
        push @roles, { id=>$role->{id}, role=>$role->{role}, description=>$role->{description}, actions=>[ @actions ] };
    }
    return @roles;
}

sub user_role_ids {
    my ( $self, $username ) = @_;
    $username or _throw 'Missing parameter username';	
    my $u = ci->user->find_one({ username=>$username },{ project_security=>1 });
    return $u ? keys $u->{project_security} : ();
}

=head2 all_users

List all users that have roles

=cut
sub all_users {
    my ( $self ) = @_;
    my @ret;
    my @users = ci->user->find->fields({ mid=>1, username=>1, project_security=>1 })->all;
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

    my $topic = $mid ? mdb->topic->find_one( { mid => $mid } ): {};
    my $proj_coll_roles = $topic->{_project_security} || '';

#    _warn $proj_coll_roles;

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
            $wh->{"project_security.$role"} = {'$exists'=> '1' };
            push @ors, $wh;
        }
    }
    $where->{'$or'} = \@ors;
#    _warn $where;
    @users = map { $_->{name} } ci->user->find($where)->fields({ name=>1 })->all;

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
        @root_users = map { $_->{name} } ci->user->find({'$or' =>\@where})->fields({ name=>1 })->all;

    }
    return @users, @root_users;
}

1;
