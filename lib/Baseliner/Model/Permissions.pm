package Baseliner::Model::Permissions;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use Array::Utils qw(intersect);
use Scalar::Util qw(blessed);
use Try::Tiny;
use Class::Load qw(load_class);
use experimental 'signatures';
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_unique _array _throw _warn _fail _loc _locl _check_parameters _unique);
use BaselinerX::Type::Model::Actions;

register 'action.admin.root' => { name => _locl('Root action - can do anything') };

sub role_has_action ($self, $role, $action) {
    if ( !ref $role ) {
        $role = mdb->role->find_one( { id => $role } );

        return 0 unless $role;
    }

    if ( grep { $_->{action} eq $action } @{ $role->{actions} } ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub user_projects_ids ($self, $username) {
    return map { $$_{mid} } ci->project->find->fields( { _id => 0, mid => 1 } )->all
      if $self->is_root($username);

    my $user = ci->user->find_one( { username => $username, project_security => { '$exists' => 1, '$type' => 3 } },
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

sub user_security_dimensions_map ($self, $username) {
    if ( $self->is_root($username) ) {
        return {};
    }

    my $user = ci->user->find_one( { username => $username }, { _id => 0, project_security => 1 } );

    my $project_security = $user->{project_security};

    my $map = {};
    foreach my $id_role ( keys %$project_security ) {
        foreach my $security_dimension ( keys %{ $project_security->{$id_role} } ) {
            my @values = _array $project_security->{$id_role}->{$security_dimension};

            $map->{$security_dimension}->{$_} = 1 for @values;
        }
    }

    return $map;
}

sub user_security_dimension ($self, $username, $dimension_name) {
    my $map = $self->user_security_dimensions_map($username);

    my $dimension = $map->{$dimension_name};
    return () unless $dimension;

    return sort keys %$dimension;
}

sub user_grants ($self, $username, %p) {
    my @ret;
    my $user             = ci->user->find_one( { username => $username }, { project_security => 1 } );
    my $project_security = $user->{project_security};
    my @id_roles         = keys %{$project_security};
    @id_roles = map { $_ } @id_roles;
    my @roles = mdb->role->find( { id => { '$in' => \@id_roles } } )->fields( { _id => 0, actions => 0 } )->all;
    foreach my $id_role ( keys %{$project_security} ) {
        foreach my $project_type ( keys %{ $project_security->{$id_role} } ) {
            $project_security->{$id_role}->{$project_type} = [ $project_security->{$id_role}->{$project_type} ]
              unless ref $project_security->{$id_role}->{$project_type} eq 'ARRAY';

            foreach my $id_project ( @{ $project_security->{$id_role}->{$project_type} } ) {
                my ($actual_role) = grep { $_->{id} eq $id_role } @roles;
                my %role_hash = %$actual_role;
                push @ret,
                  {
                    id_project => $id_project,
                    ns         => "$project_type/$id_project",
                    id_role    => $id_role,
                    role       => \%role_hash,
                    username   => $user->{username}
                  };
            }
        }
    }
    return @ret;
}

sub user_namespaces ($self, $username) {
    my @perms = $self->user_grants($username);
    return sort { $a cmp $b } _unique( map { $_->{ns} } @perms );
}

sub user_roles_ids ($self, $username, %options) {
    if ( $self->is_root($username) ) {
        return map { $_->{id} } mdb->role->find->fields( { _id => 0, id => 1 } )->all();
    }

    my $user = ci->user->find_one( { name => $username } );
    _fail _loc 'User %1 not found', $username unless $user;

    my $user_security = $user->{project_security} || {};

    my @want_security;
    push @want_security, $options{security} if $options{security};

    if ( my @topics_mids = _array $options{topics} ) {
        my @topics =
          mdb->topic->find( { mid => { '$in' => \@topics_mids } }, { _project_security => 1, _id => 0 } )->all;
        return () unless @topics;

        foreach my $topic (@topics) {
            if ( my $topic_security = $topic->{_project_security} ) {
                push @want_security, $topic_security;
            }
        }
    }

    my @roles;

  ROLE: foreach my $id_role ( keys %$user_security ) {
        foreach my $want_security (@want_security) {
            if ( !$self->match_security( $user_security->{$id_role}, $want_security ) ) {
                next ROLE;
            }
        }

        push @roles, $id_role;
    }

    return sort @roles;
}

sub user_roles ($self, $username, %options) {
    my @ids = $self->user_roles_ids( $username, %options );
    return () unless @ids;

    return mdb->role->find( { id => mdb->in(@ids) } )->all;
}

sub is_root ($self, $username) {
    my $is_root = $username eq 'root' || do {
        my $user = ci->user->find_one( { name => $username } );
        _fail _loc 'User %1 not found', $username unless $user;

        my @roles_ids;
        foreach my $id_role ( keys %{ $user->{project_security} || {} } ) {
            push @roles_ids, $id_role;
        }

        !!mdb->role->find( { id => { '$in' => \@roles_ids }, 'actions.action' => 'action.admin.root' } )
          ->fields( { _id => 0, id => 1 } )->all;
    };

    return $is_root;
}

sub action_info ($self, $action_key) {
    my $action_info = Baseliner::Core::Registry->get($action_key);
    return unless $action_info && blessed($action_info);

    return $action_info;
}

sub action_bounds_available ($self, $action_key, $bound_key, %filter) {
    my @data;

    my $action_info = $self->action_info($action_key);
    if ( $action_info ) {
        my $bounds = $action_info->bounds;

        if ($bounds && @$bounds) {
            my ($bound) = grep { $_->{key} eq $bound_key } @$bounds;

            if ( $bound && ( my $handler = $bound->{handler} ) ) {
                my ( $class, $method ) = split /=/, $handler, 2;

                load_class($class);

                my $instance = $class->new;
                @data = $instance->$method(%filter);
            }
        }
    }

    return \@data;
}

sub map_action_bounds ($self, $action_key, $role_bounds, %options) {
    my $action = $self->action_info($action_key);
    return unless $action;

    foreach my $bound ( @{ $action->bounds } ) {
        my @ids =
          grep { defined $_ && length $_ } _unique map { $_->{ $bound->{key} } } @{ $role_bounds };
        next unless @ids;

        if ( my $handler = $bound->{handler} ) {
            my ( $class, $method ) = split /=/, $handler, 2;

            load_class($class);

            my $instance = $class->new;
            my %bound_map = map { $_->{id} => $_->{title} } $instance->$method( id => \@ids );

            foreach my $role_bound ( @$role_bounds ) {
                $role_bound->{ '_' . $bound->{key} . '_title' } = $bound_map{ $role_bound->{ $bound->{key} } }
                  // $role_bound->{ $bound->{key} };
            }
        }
    }

    return $role_bounds;
}

sub user_actions ($self, $username) {
    my @actions;

    if ( $self->is_root($username) ) {
        @actions =
          map { { action => $_->{key} } } BaselinerX::Type::Model::Actions->new->list;
    }
    else {
        my @roles_ids = $self->user_roles_ids($username);

        my $query = { id => { '$in' => \@roles_ids } };

        my @actions_by_roles =
          mdb->role->find($query)->fields( { actions => 1, bounds => 1, _id => 0 } )->all;

        foreach my $actions_by_role (@actions_by_roles) {
            foreach my $action ( @{ $actions_by_role->{actions} } ) {
                my $action_info = Baseliner::Core::Registry->get( $action->{action} );
                next unless $action_info && blessed($action_info);

                push @actions, { action => $action->{action} };

                foreach my $extend ( _array $action_info->extends ) {
                    push @actions, { action => $extend };
                }
            }
        }
    }

    @actions =
      sort { $a->{action} cmp $b->{action} } @actions;

    return \@actions;
}

sub user_actions_map ($self, $username) {
    my $actions = $self->user_actions($username);

    my $map = {};

    foreach my $action (@$actions) {
        my @bounds = _array $action->{bounds};

        my $is_any = !@bounds;

        if ($is_any) {
            $map->{ $action->{action} } = {};
        }
        else {
            push @{ $map->{ $action->{action} }->{bounds} }, @bounds;

        }

        if ( my $extends = $action->{extends} ) {
            foreach my $extend (@$extends) {
                if ($is_any) {
                    $map->{$extend} = {};
                }
                else {
                    push @{ $map->{$extend}->{bounds} }, @bounds;
                }
            }
        }
    }

    return $map;
}

sub user_action ($self, $username, $action_key, %options) {
    if ( $self->is_root($username) ) {
        return {
            bounds   => [],
            projects => [ map { $_->{mid} } ci->project->find->fields( { mid => 1, _id => 0 } )->all ]
        };
    }

    my @roles_ids = $self->user_roles_ids( $username, %options );

    my $action_info = Baseliner::Core::Registry->get($action_key);
    unless ( $action_info && blessed($action_info) ) {
        _warn qq{Unknown action '$action_key'};
        return;
    }

    my $bounds = $options{bounds};

    my @bounds_available = map { $_->{key} } _array $action_info->bounds;

    if ( !@bounds_available && $bounds ) {
        _fail qq{Action '$action_key' does not support boundaries};
    }

    my $query_empty_bounds = [
        { 'actions.bounds' => { '$exists' => 0 } },
        { 'actions.bounds' => '' },
        { 'actions.bounds' => undef },
        { 'actions.bounds' => {} },
    ];

    my @query_bounds = ();
    if ( $bounds && $bounds ne '*' ) {
        foreach my $key (@bounds_available) {
            my $value = $bounds->{$key};

            if ($value) {
                if ( $value ne '*' ) {
                    push @query_bounds, "actions.bounds.$key" => { '$in' => [ $value, undef ] };
                }
            }
            else {
                push @query_bounds, "actions.bounds.$key" => { '$exists' => 0 };
            }
        }
    }

    my @action_keys = ($action_key);
    push @action_keys, _array $action_info->extensions;

    my $aggregate_query = [
        { '$match'  => { id => { '$in' => \@roles_ids }, 'actions.action' => mdb->in(@action_keys) } },
        { '$unwind' => '$actions' },
        @bounds_available ? ( { '$unwind' => '$actions.bounds' } ) : (),
        {
            '$match' => {
                'actions.action' => mdb->in(@action_keys),
                @bounds_available
                ? (
                    'actions.bounds._deny' => undef,
                    $bounds
                    ? ( '$or' => [ {@query_bounds}, @$query_empty_bounds ] )
                    : ( '$or' => $query_empty_bounds )
                  )
                : ()
            }
        },
        {
            '$group' => {
                "_id"     => '$_id',
                'id'      => { '$push' => '$id' },
                "actions" => { '$push' => '$actions' },
            }
        },
    ];

    my $roles = mdb->role->aggregate($aggregate_query);

    my %allow_roles;
    my %deny_roles;
    foreach my $role (_array $roles) {
        my ($id) = _array $role->{id};
        $allow_roles{$id} = $role;
    }

    if ( @$roles && $bounds ) {
        my $deny_roles = mdb->role->aggregate(
            [
                { '$match'  => { id => { '$in' => \@roles_ids }, 'actions.action' => mdb->in(@action_keys) } },
                { '$unwind' => '$actions' },
                { '$unwind' => '$actions.bounds' },
                {
                    '$match' => {
                        'actions.action'       => mdb->in(@action_keys),
                        'actions.bounds._deny' => 1,
                        @query_bounds
                    }
                },
                {
                    '$group' => {
                        "_id"     => '$_id',
                        'id'      => { '$push' => '$id' },
                        "actions" => { '$push' => '$actions' },
                    }
                },
            ]
        );

        if (@$deny_roles) {
            foreach my $role (_array $deny_roles) {
                my ($id) = _array $role->{id};
                $deny_roles{$id} = $role;
            }

            ROLE: foreach my $role_id (keys %allow_roles) {
                last unless $deny_roles{$role_id};

                my @allow_bounds = map { _array $_->{bounds} } @{ $allow_roles{$role_id}->{actions} };
                my @deny_bounds  = map { _array $_->{bounds} } @{ $deny_roles{$role_id}->{actions} };

                if ($bounds eq '*') {
                    my $all_denied = 1;
                    foreach my $allow_bound (@allow_bounds) {
                        if (!$self->_is_bound_denied($allow_bound, \@deny_bounds)) {
                            $all_denied = 0;
                            last;
                        }
                    }

                    if ($all_denied) {
                        delete $allow_roles{$role_id};
                    }
                }
                else {
                    if ($self->_is_bound_denied($bounds, \@deny_bounds)) {
                        delete $allow_roles{$role_id};
                    }
                }
            }
        }
    }

    return unless %allow_roles;

    my $user = ci->user->find_one( { username => $username }, { project_security => 1 } );
    return unless $user;

    my @projects_ids;
    foreach my $id_role ( keys %allow_roles ) {
        my $project_security = $user->{project_security}->{$id_role};
        next unless $project_security;

        my $projects = $project_security->{project};

        push @projects_ids, _array $projects;
    }

    my $action = {};

    if (@bounds_available) {
        my @bounds;
        my @bounds_denied;
      ROLE: foreach my $id ( keys %allow_roles ) {
            my $role = $allow_roles{$id};

            foreach my $action ( @{ $role->{actions} } ) {
                my $bounds = $action->{bounds};
                next unless $bounds;

                my @new_bounds = _array $bounds;
                if ( grep { !%$_ } @new_bounds ) {
                    if ($deny_roles{$id}) {
                        my @negative_bounds =
                          map { _array $_->{bounds} } map { _array $_->{actions} } _array $deny_roles{$id};

                        if (@negative_bounds) {
                            push @bounds, {};
                            push @bounds_denied, @negative_bounds;
                        }

                        next;
                    }

                    @bounds = ();
                    last ROLE;
                }

                push @bounds, _array @new_bounds;
            }
        }

        $action->{bounds}        = [];
        $action->{bounds_denied} = [];

        if (@bounds_denied) {
            foreach my $bound_denied (@bounds_denied) {
                foreach my $bound (@bounds) {
                    if ( !$self->_is_bound_denied( $bound, [$bound_denied] ) ) {
                        push @{ $action->{bounds} }, $bound;

                        delete $bound_denied->{_deny};
                        push @{ $action->{bounds_denied} }, $bound_denied;
                    }
                }
            }
        }
        else {
            $action->{bounds} = \@bounds;
        }

        $action->{bounds}        = [ grep { %$_ } _array $action->{bounds} ];
        $action->{bounds_denied} = [ grep { %$_ } _array $action->{bounds_denied} ];
    }

    $action->{projects} = [ _unique @projects_ids ];

    return $action;
}

sub user_has_action ($self, $username, $action_key, %options) {
    return 1 if $self->is_root($username);

    my $action = $self->user_action( $username, $action_key, %options );
    return 0 unless $action;

    return 1;
}

sub user_has_any_action ($self, $username, $action_pattern, %options) {
    return 1 if $self->is_root($username);

    if ( $action_pattern =~ s{\%}{.*}g ) {
        my @roles_ids = $self->user_roles_ids($username);

        my @roles = mdb->role->find( { id => { '$in' => \@roles_ids }, 'actions.action' => qr/^$action_pattern/ } )
          ->fields( { _id => 0, id => 1 } )->all;

        return @roles ? 1 : 0;
    }

    return $self->user_has_action( $username, $action_pattern, %options );
}

sub match_security ($self, $restricted_security, $available_security) {
    $available_security //= {};

    my @dimensions = sort keys %{$restricted_security};
    return 0 unless @dimensions;

    foreach my $dimension (@dimensions) {
        my @restrictions = _array $restricted_security->{$dimension};
        my @available = _array $available_security->{$dimension};

        if ( $dimension eq 'project' && @available == 0 ) {
            return 1;
        }

        my @intersect = intersect @restrictions, @available;

        return 0 unless @intersect;
    }

    return 1;
}

sub user_has_security ($self, $username, $security) {
    if ( $self->is_root($username) ) {
        return 1;
    }

    return 1 unless defined $security;

    my $user = ci->user->find_one( { username => $username }, { project_security => 1, _id => 0 } );
    return 0 unless $user;

    my $user_security = $user->{project_security};

    foreach my $id_role ( keys %$user_security ) {
        my $role_security = $user_security->{$id_role};

        return 1 if $self->match_security($role_security, $security);
    }

    return 0;
}

sub inject_security_filter ($self, $username, $where) {
    if ( $self->is_root($username) ) {
        return;
    }

    my $user = ci->user->find_one( { username => $username }, { project_security => 1, _id => 0 } );
    my $user_security = $user->{project_security};

    my @filter;
    foreach my $id_role ( sort keys %$user_security ) {
        my @dimensions = sort keys %{ $user_security->{$id_role} };

        my @subfilter;
        foreach my $dimension (@dimensions) {
            my @extra;

            if ( $dimension eq 'project' ) {
                push @extra, undef;
            }

            push @subfilter,
              { "_project_security.$dimension" =>
                  { '$in' => [ _unique @extra, _array $user_security->{$id_role}->{$dimension} ] } };
        }

        push @filter, { '$and' => \@subfilter };
    }

    if (@filter) {
        $where->{'$or'} = [ { _project_security => undef }, @filter ];
    }
    else {
        $where->{_project_security} = undef;
    }
}

sub inject_project_filter ($self, $username, $action_key, $where, %options) {
    if ( $self->is_root($username) ) {
        if (my @values = _array $options{filter}) {
            $where->{projects} = mdb->in(@values);
        }

        return;
    }

    my $action = $self->user_action($username, $action_key, bounds => '*');
    die "Action '$action_key' not allowed for user '$username'" unless $action;

    if (my @projects = _array $action->{projects}) {
        $where->{projects} = mdb->in( @projects );
    }

    if (my $filter = $options{filter}) {
        my @allowed_values = $where->{projects} ? _array $where->{projects}->{'$in'}  : ();

        my @want_values = _array $filter;
        if (@want_values) {
            @want_values = intersect @want_values, @allowed_values;

            $where->{projects} = mdb->in(@want_values);
        }
    }
}

sub filter_bounds ($self, $username, $action_key, $filters) {
    if ( $self->is_root($username) ) {
        return $filters;
    }

    my $action = $self->user_action($username, $action_key, bounds => '*');
    die "Action '$action_key' not allowed for user '$username'" unless $action;

    my $filtered = {};

    if (my @bounds = _array $action->{bounds}) {
        foreach my $key (keys %$filters) {
            my @allowed = map { $_->{$key} } @bounds;
            my @want = _array $filters->{$key};

            $filtered->{$key} = [intersect @allowed, @want];
        }
    }
    elsif (my @bounds_denied = _array $action->{bounds_denied}) {
        foreach my $key (keys %$filters) {
            my @denied = map { _array $_->{$key} } @bounds_denied;
            my @want = _array $filters->{$key};

            my @to_remove = intersect @denied, @want;
            foreach my $want (@want) {
                if ( !grep { $want eq $_ } @to_remove ) {
                    push @{ $filtered->{$key} }, $want;
                }
            }
        }
    }
    else {
        $filtered = $filters;
    }

    return $filtered;
}

sub inject_bounds_filters ($self, $username, $action_key, $where, %options) {
    if ( $self->is_root($username) ) {
        if ( my $filters = $options{filters} ) {
            foreach my $filter ( keys %$filters ) {
                my @values = _array $filters->{$filter};
                next unless @values;

                $where->{$filter} = mdb->in(@values);
            }
        }
    }
    else {

        my $action = $self->user_action( $username, $action_key, bounds => '*' );
        die "Action '$action_key' not allowed for user '$username'" unless $action;

        if ( my @bounds = _array $action->{bounds} ) {
            foreach my $key ( keys %{ $bounds[0] } ) {
                $where->{$key} = mdb->in( map { $_->{$key} } @bounds );
            }
        }

        if ( my @bounds_denied = _array $action->{bounds_denied} ) {
            foreach my $key ( keys %{ $bounds_denied[0] } ) {
                $where->{$key} = mdb->nin( map { $_->{$key} } @bounds_denied );
            }
        }

        if ( my $filters = $options{filters} ) {
            foreach my $filter ( keys %$filters ) {
                my @allowed_values = $where->{$filter} ? _array $where->{$filter}->{'$in'}  : ();
                my @denied_values  = $where->{$filter} ? _array $where->{$filter}->{'$nin'} : ();

                my @want_values = _array $filters->{$filter};
                next unless @want_values;

                if (@allowed_values) {
                    @want_values = intersect @allowed_values, @want_values;
                    $where->{$filter} = mdb->in(@want_values);
                }
                elsif (@denied_values) {
                    my @to_remove = intersect @denied_values, @want_values;

                    if (@to_remove) {
                        my @filtered_values;
                        foreach my $value (@want_values) {
                            if ( !grep { $value eq $_ } @to_remove ) {
                                push @filtered_values, $value;
                            }
                        }

                        if (@filtered_values) {
                            $where->{$filter} = mdb->in(@filtered_values);
                        }
                        else {
                            $where->{$filter} = [];
                        }
                    }
                    else {
                        $where->{$filter} = mdb->in(@want_values);
                        delete $where->{$filter}->{'$nin'};
                    }
                }
                else {
                    $where->{$filter} = mdb->in(@want_values);
                }
            }
        }
    }

    if (my $map = $options{map}) {
        foreach my $key (keys %$map) {
            my $mapped_key = $map->{$key};
            next unless $mapped_key && $where->{$key};

            $where->{$mapped_key} = delete $where->{$key};
        }
    }
}

sub users_with_roles ($self, %p) {
    _check_parameters( \%p, qw/roles/ );

    my @roles    = _array $p{roles};
    my @security = _array $p{security};

    my @ors;
    for my $role (@roles) {
        push @ors, { "project_security.$role" => { '$exists' => '1' } };

        foreach my $security (@security) {
            foreach my $dimension (keys %$security) {
                $ors[-1]->{"project_security.$role.$dimension"} = { '$in' => [ _array $security->{$dimension} ] };
            }
        }
    }

    my @users = map { $_->{name} } ci->user->find( { '$or' => \@ors } )->fields( { name => 1 } )->all;
    return @users;
}

sub users_with_action ($self, $action_key) {
    my $action_info = Baseliner::Core::Registry->get($action_key);
    unless ( $action_info && blessed($action_info) ) {
        _fail qq{Unknown action '$action_key'};
    }

    my @action_keys = ($action_key);
    push @action_keys, _array $action_info->extensions;

    my @roles = mdb->role->find( { 'actions.action' => mdb->in(@action_keys) } )->all;
    return () unless @roles;

    my @roles_ids = map { $_->{id} } @roles;

    return $self->users_with_roles( roles => \@roles_ids );
}

sub _is_bound_denied {
    my $self = shift;
    my ( $bound, $deny_bounds ) = @_;

    return 0 unless %$bound;

    foreach my $deny_bound ( _array $deny_bounds) {
        my $match = 1;
        foreach my $key ( keys %$deny_bound ) {
            next if $key =~ /^_/;

            if ( defined( $bound->{$key} ) ) {
                if ( $bound->{$key} ne $deny_bound->{$key} ) {
                    $match = 0;
                }
            }
            else {
                $match = 0;
            }
        }

        return 1 if $match;
    }

    return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
