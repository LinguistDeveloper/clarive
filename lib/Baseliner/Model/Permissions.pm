package Baseliner::Model::Permissions;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use Array::Utils qw(intersect);
use Try::Tiny;
use experimental 'autoderef', 'smartmatch', 'signatures';
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Type::Model::Actions;

sub role_exists ($self, $role_name) {
    return !!mdb->role->find_one( { role => $role_name }, { _id => 1 } );
}

sub has_role_action ($self, %p) {
    _check_parameters( \%p, qw/role action/ );

    my $role   = $p{role};
    my $action = $p{action};

    if ( grep { $_->{action} eq $action } @{ $role->{actions} } ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub user_has_action ($self, %p) {
    _check_parameters( \%p, qw/username action/ );

    my $username = $p{username};
    my $action = delete $p{action};

    return 1 if $self->is_root( $username );

    my $ret = 0;
    if ( $p{mid} ) {
        my @return = grep { /$action/ } _array($self->user_actions_by_topic(%p)->{positive});
        $ret = !!@return;
    } else {
        my @bl = _array $p{bl};
        push @bl, '*' if !@bl || !grep { $_ eq '*' } @bl;

        $ret = scalar grep {$action eq $_ } $self->_get_actions_from_user($username, @bl);
    }
    if( $p{fail} && !$ret ) {
        _fail _loc 'User %1 does not have permissions to action %2', $username, $action;
    }
    return $ret;
}

sub user_has_read_action ($self, %p) {
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

sub user_has_any_action ($self, %p) {
    _check_parameters( \%p, qw/username action/ );

    my $username = $p{username};
    my $action = $p{action};
    my $bl = $p{bl} // '*';
    return 1 if $self->is_root( $username );
    my @actions = $self->user_actions_list( %p );
    return scalar @actions;
}

sub user_actions_list ($self, %p) {
    _check_parameters( \%p, qw/username/ );

    my $username = $p{username};
    my $action   = delete $p{action} // qr/.*/;
    my $mid      = $p{mid};

    my $regexp_action;

    if ( !ref $action ) {
        $action =~ s/\./\\\./g;
        $action =~ s/%/\.\*/g;
        $regexp_action = qr/$action/;
    }
    elsif ( ref $action eq 'Regexp' ) {
        $regexp_action = $action;
    }
    else {
        return ();
    }

    my @actions;
    if ( $self->is_root($username) ) {
        @actions = map { $_->{key} } BaselinerX::Type::Model::Actions->new->list;
    }
    elsif ($mid) {
        @actions = _array( $self->user_actions_by_topic(%p)->{positive} );
    }
    else {
        my @bl = _array $p{bl};
        push @bl, '*' if !@bl || !grep { $_ eq '*' } @bl;

        @actions = $self->_get_actions_from_user( $username, @bl );
    }

    @actions = grep { $_ =~ $regexp_action } @actions;

    return @actions;
}

sub user_actions_by_topic ($self, %p) {
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
            @negative_actions = intersect(@negative_actions, @role_negative_actions)
        }
        @negative_actions = _unique(@negative_actions);
    }

    return { positive => \@positive_actions, negative => \@negative_actions};
}

sub user_projects ($self, %p) {
    _check_parameters( \%p, qw/username/ );
    _throw 'with_role not supported anymore' if exists $p{with_role};

    return map { "project/$$_{mid}" } ci->project->find->fields( { mid => 1 } )->all if $self->is_root( $p{username} );

    my @ret;
    my $project_security =
      ci->user->find_one( { username => $p{username} }, { project_security => 1 } )->{project_security};
    my @id_roles = keys %{$project_security};
    foreach my $id_role (@id_roles) {
        my @project_types = keys $project_security->{$id_role};
        foreach my $project_type (@project_types) {
            push @ret, "project/$_" for _unique _array( $project_security->{$id_role}->{$project_type} );
        }
    }

    return _unique(@ret);
}

sub user_projects_ids ($self, %p) {
    _check_parameters( \%p, qw/username/ );

    return map { $$_{mid} } ci->project->find->fields( { _id => 0, mid => 1 } )->all if $self->is_root( $p{username} );

    my $user = ci->user->find_one( { username => $p{username}, project_security => { '$exists' => 1, '$type' => 3 } },
        { _id => 0, project_security => 1 } );
    if ($user) {
        my $project_security = $user->{project_security};
        return _unique map { ref $_->{project} eq 'ARRAY' ? @{ $_->{project} } : $_->{project} }
          grep { $_->{project} } values %{$project_security};
    }
    else {
        return ();
    }
}

=head2 user_projects_ids_with_collection( username=>Str )

Returns an array of project ids for the projects the user has access to with their collection

=cut


sub user_projects_ids_with_collection {
    my ( $self, %p ) = @_;

    my $username = $p{username};
    my $with_role = $p{with_role} // 0;
    $p{roles} //= '';

    my $cache_key = { %p, d => 'topic' };
    defined && return ( $with_role ? $_ : values(%$_) ) for cache->get($cache_key);

    my $sec_projects;

    my %ret;
    my $user = ci->user->find_one( { username => $username }, { project_security => 1 } );
    my $project_security = $user->{project_security};

    my @roles = split( /,/, $p{roles} );
    if ( !@roles ) {
        @roles = keys %$project_security;
    }
    my @user_roles = keys %{ $user->{project_security} };

    foreach my $id_role (@user_roles) {
        foreach my $actual_id (@roles) {
            if ( $id_role eq $actual_id ) {
                my @project_types = keys $project_security->{$id_role};
                foreach my $project_type (@project_types) {
                    $project_security->{$id_role}->{$project_type} = [ $project_security->{$id_role}->{$project_type} ]
                      unless ref $project_security->{$id_role}->{$project_type} eq 'ARRAY';

                    map { $ret{$id_role}{$project_type}{$_} = 1 } @{ $project_security->{$id_role}->{$project_type} };
                }
            }
        }
    }
    cache->set( $cache_key, \%ret );
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
        my @filtered_categories = sort grep { exists $cat_filter{$_} } keys %categories_for_role if @filter_categories;
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

sub user_can_topic_by_project ($self, %p) {
    _check_parameters( \%p, qw/username mid/ );

    my $username = $p{username};
    my $mid = $p{mid};

    return 1 if $self->is_root($username);

    my @actions = _array( $self->user_actions_by_topic(%p)->{positive} );
    my $action  = "action.topics."
      . _name_to_id( mdb->topic->find_one( { mid => "$mid" }, { category => 1 } )->{category}->{name} );

    my @actions_found = grep { /^$action\./ } @actions;
}

sub user_roles_for_topic ($self, %p) {
    _check_parameters( \%p, qw/username/ );

    my $username = $p{username};

    my $mid = $p{mid} // '';#_fail "Missing mid" ;
    my $user_security = $p{user_security} // ci->user->find_one( {name => $username}, { project_security => 1, _id => 0} )->{project_security};
    my $topic_security = $p{topic_security};
    $topic_security = mdb->topic->find_one( {mid => "$mid"}, { _project_security => 1, _id => 0} )->{_project_security} if !$topic_security && $mid;

    my @roles_for_topic;

    if ( $topic_security ) {
        my @topic_sec = keys %$topic_security;
        ROLE: for my $role ( keys %$user_security ) {
            my $role_sec_all = $user_security->{$role};
            my @role_sec = keys %$role_sec_all;
            my @common_sec = intersect(@role_sec, @topic_sec);
            for my $sec ( @common_sec ) {
                my @sec_for_role = _array($role_sec_all->{$sec});
                my @sec_for_topic = _array($topic_security->{$sec});
                if ( !intersect( @sec_for_role, @sec_for_topic) ) {
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

sub user_projects_with_action ($self, %p) {
    _check_parameters( \%p, qw/username action/ );

    my $username = $p{username};
    my $action   = $p{action};
    my @bl       = $p{bl} || ('*');

    if ( $self->is_root($username) ) {
        return map { $$_{mid} } ci->project->find->fields( { mid => 1, _id => 0 } )->all;
    }

    my $user = ci->user->find_one( { username => $username }, { project_security => 1 } );

    my @id_roles = keys %{ $user->{project_security} || {} };
    @id_roles = map { $_ } @id_roles;

    my @roles = mdb->role->find( { id => { '$in' => \@id_roles } } )->fields( { _id => 0 } )->all;

    my @res;
    foreach my $role (@roles) {
        if ( grep { $_->{action} eq $action && $_->{bl} ~~ @bl } @{ $role->{actions} } ) {
            push @res, map { ref $_ eq 'ARRAY' ? @$_ : $_ } values %{ $user->{project_security}->{ $role->{id} } };
        }
    }

    return _unique @res;
}

sub user_grants ($self, $username, %p) {
    my @ret;
    my $user = ci->user->find_one({ username=>$username },{ project_security=>1 });
    my $project_security = $user->{project_security};
    my @id_roles = keys $project_security;
    @id_roles = map { $_ } @id_roles;
    my @roles = mdb->role->find({ id=> { '$in'=>\@id_roles } })->fields( { _id=>0, actions=>0 } )->all;
    foreach my $id_role (keys $project_security ){
        foreach my $project_type (keys $project_security->{$id_role}){
            $project_security->{$id_role}->{$project_type} = [ $project_security->{$id_role}->{$project_type} ]
              unless ref $project_security->{$id_role}->{$project_type} eq 'ARRAY';

            foreach my $id_project (@{$project_security->{$id_role}->{$project_type}}){
                my ($actual_role) = grep { $_->{id} eq $id_role } @roles;
                my %role_hash = %$actual_role;
                push @ret, { id_project=>$id_project, ns=>"$project_type/$id_project", id_role=>$id_role, role=>\%role_hash, username=>$user->{username} };
            }
        }
    }
    return @ret;
}

sub user_namespaces ($self, $username) {
    my @perms = $self->user_grants( $username );
    return sort { $a cmp $b } _unique( map { $_->{ns} } @perms );
}

=head2 list

List users that have an action

     action=>Str, [ ns=>Str, bl=>Str ]

 or actions that a user has

     username=>Str, [ bl=>Str ]

=cut
sub list ($self, %p) {
    $p{username} //= '';

    my @ret;
    my $cache_key = ["user:permission:list:$p{username}:", %p ];
    my $cached = cache->get( $cache_key );
    if( ref $cached eq 'ARRAY' ) {
        return @$cached;
    }
    my @bl = $p{bl} || ('*');
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
        @ret = $self->_get_actions_from_user($username, (@bl));
    }else{
        my @users = ci->user->find->fields({ mid=>1, project_security=>1 })->all;
        my @roles = mdb->role->find->all;
        foreach my $user (@users){
            my @id_roles = keys $user->{project_security};
            @id_roles = map { $_ } @id_roles;
            my @user_roles = grep { $_->{id} ~~ @id_roles } @roles;
            foreach my $user_role (@user_roles){
                my @actions;
                if(grep {$_ eq 'any'} @bl){
                    @actions = map { $_->{action} } @{$user_role->{actions}};
                }else{
                    foreach my $act (@{$user_role->{actions}}){
                        if(grep { $_ eq $act->{bl} } @bl){
                            push @actions, $act->{action};
                        }
                    }
                }
                if(grep {$_ eq $action} @actions){
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

sub is_root ($self, $username) {
    my $cached_key = "user:is_root:$username:";
    my $cached = cache->get($cached_key);
    return $cached if defined $cached;

    my $is_root = $username eq 'root'
      || scalar( grep { 'action.admin.root' eq $_ } $self->_get_actions_from_user($username) );

    cache->set( $cached_key, $is_root );

    return $is_root;
}

=head2 user_roles

Returns everything a user has.

=cut
sub user_roles ($self, $username) {
    my @id_roles = $self->user_role_ids($username);
    my @roles;
    foreach my $id (@id_roles){
        my $role = mdb->role->find_one({ id=>$id });
        my @actions = map { $_->{action} } @{ $role->{actions} };
        push @roles, { id=>$role->{id}, role=>$role->{role}, description=>$role->{description}, actions=>[ @actions ] };
    }
    return @roles;
}

sub user_role_ids ($self, $username) {
    my $u = ci->user->find_one({ username=>$username, project_security => {'$exists' => 1, '$type' => 3} },{ project_security=>1 });
    return $u ? keys $u->{project_security} : ();
}

sub users_with_roles ($self, %p) {
    _check_parameters( \%p, qw/roles/ );

    my @roles = _array $p{roles};

    my @ors;
    for my $role (@roles) {
        push @ors, { "project_security.$role" => { '$exists' => '1' } };
    }

    my @users = map { $_->{name} } ci->user->find( { '$or' => \@ors } )->fields( { name => 1 } )->all;
    return @users;
}

sub user_can_search_ci ($self, $username) {
    return 1 if $self->user_is_ci_admin($username);

    return $self->user_has_action( username => $username, action => 'action.search.ci' );
}

sub user_is_ci_admin ($self, $username) {
    return 1 if $self->is_root($username);

    return $self->user_has_action( action => 'action.ci.admin', username => $username );
}

sub user_can_view_ci ($self, $username, $collection = undef) {
    return 1 if $self->user_is_ci_admin($username);

    if ($collection) {
        return 1 if $self->user_has_any_action(
            action   => 'action.ci.admin.%.' . $collection,
            username => $username
        );

        return 1 if $self->user_has_any_action(
            action   => 'action.ci.view.%.' . $collection,
            username => $username
        );
    }

    return 0;
}

sub user_can_admin_ci ($self, $username, $collection = undef) {
    return 1 if $self->user_is_ci_admin($username);

    if ($collection) {
        return 1 if $self->user_has_any_action(
            action   => 'action.ci.admin.%.' . $collection,
            username => $username
        );
    }

    return 0;
}

sub user_can_view_ci_group ($self, $username, $collection = undef) {
    return 1 if $self->user_is_ci_admin($username);

    if ($collection) {
        return 1 if $self->user_has_any_action(
            action   => 'action.ci.%.' . $collection . '.%',
            username => $username
        );
    }

    return 0;
}

sub _get_actions_from_user ($self, $username, @bl) {
    my @final;
    if($username eq 'root' || $username eq 'local/root'){
        @final = Baseliner->model( 'Actions' )->list;
    }else{
        my $user = ci->user->find_one({ name=>$username });
        _fail _loc 'User %1 not found', $username unless $user;
        my @roles = keys %{ $user->{project_security} };
        #my @id_roles = map { $_ } @roles;
        my @actions = mdb->role->find({ id=>{ '$in'=>\@roles } })->fields( {actions=>1, _id=>0} )->all;
        @actions = grep {%{$_}} @actions; ######### DELETE RESULTS OF ACTIONS OF ROLES WITHOUT ACTIONS
        foreach my $f (map { values $_->{actions} } @actions){
            if(@bl){
                if(@bl == 1 && grep {$_ eq '*'} @bl){
                    push @final, $f->{action};
                } elsif (grep {$_ eq $f->{bl}} @bl) {
                    push @final, $f->{action};
                }
            }else{
                push @final, $f->{action};
            }
        }
    }
    return _unique @final;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
