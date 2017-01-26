package Baseliner::Controller::User;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use File::Copy ();
use GD::Image;
use Capture::Tiny qw(capture);
use Locale::Country qw(all_country_names country2code);
use XML::Simple;
use DateTime::TimeZone qw(all_names);
use Baseliner::IdenticonGenerator;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_log _debug _error _loc _locl _fail _throw _file _dir _array _unique _warn _encode_json);

with 'Baseliner::Role::ControllerValidator';

use experimental 'switch', 'autoderef';

register 'config.user.global' => {
    preference => 1,
    desc       => _locl('Global Preferences'),
    metadata   => [
        {   id      => 'language',
            label   => _locl('Language'),
            type    => 'combo',
            default => Clarive->config->{default_lang},
            store   => [ 'es', 'en' ]
        },
    ]
};
register 'config.user.view' => {
    preference => 1,
    desc       => _locl('View Preferences'),
    metadata   => [
        {   id      => 'theme',
            label   => _locl('Theme'),
            type    => 'combo',
            default => Clarive->config->{default_theme},
            store   => [ 'gray', 'blue', 'slate' ]
        },
    ]
};
register 'action.admin.users' => { name => _locl('User Admin'), };

register 'menu.admin.users' => {
    label    => _locl('Users'),
    url_comp => '/user/grid',
    actions  => ['action.admin.users'],
    title    => _locl('Users'),
    index    => 80,
    icon     => '/static/images/icons/user.svg'
};

register 'event.user.create' => {
    text        => 'New user created: %2',
    description => _locl('New user'),
    vars        => [ 'username', 'realname', 'email' ]
};

sub preferences : Local {
    my ( $self, $c ) = @_;
    my @config = $c->model('Registry')
        ->search_for( key => 'config', preference => 1 );
    $c->stash->{ns}    = 'user/' . ( $c->user->username || $c->user->id );
    $c->stash->{bl}    = '*';
    $c->stash->{title} = _loc('User Preferences');
    if (@config) {
        $c->stash->{metadata} = [ map { $_->metadata } @config ];
        $c->stash->{ns_query}
            = { does => 'Baseliner::Role::Namespace::User' };
        $c->forward('/config/form_render');
    }
}

sub actions : Local {
    my ( $self, $c ) = @_;
    $c->stash->{username} = $c->username;
    $c->stash->{template} = '/comp/user_actions.mas';
}

sub info : Local {
    my ( $self, $c, $username ) = @_;
    $c->stash->{swAsistentePermisos} = 0;

    if ( $username eq '' ) {
        $username = $c->username;
        $c->stash->{swAsistentePermisos} = 1;
    }
    my $u = $c->model('Users')->get($username);
    if ( ref $u ) {
        my $user_data = $u->{data} || {};
        $c->stash->{username} = $username;
        $c->stash->{realname} = $u->{realname};
        $c->stash->{alias}    = $u->{alias};
        $c->stash->{email}    = $u->{email};
        $c->stash->{phone}    = $u->{phone};

        # Data from LDAP, or other user data providers:
        $c->stash->{$_} ||= $user_data->{$_} for keys %$user_data;
    }
    $c->stash->{template} = '/comp/user_info.mas';
}

sub infodetail : Local {
    my ( $self, $c ) = @_;

    my $p        = $c->request->parameters;
    my $id_user = $p->{id};
    my $username = $p->{username};

    my $authorized = 1;
    my $msg        = '';

    my @actions;
    my @datas;
    my $data;
    my $is_user_admin = $self->_is_user_admin($c);
    my $own_user = $username && $username eq $c->username;

    my @rows;
    if ( $is_user_admin || $own_user ) {
        my ( $start, $limit, $query, $dir, $sort, $cnt )
            = ( @{$p}{qw/start limit query dir sort/}, 0 );
        $sort ||= 'role';
        $dir  ||= 'asc';
        if ( $dir =~ /asc/i ) {
            $dir = 1;
        }
        else {
            $dir = -1;
        }

        my $user = ci->user->find( { '$or' => [{mid => $id_user}, {username => $username }] } )->next;
        my @roles;
        if ( $user->{project_security} ) {
            @roles = keys $user->{project_security};
            @roles = map {$_} @roles;
        }
        my $roles_from_user = mdb->role->find( { id => { '$in' => \@roles } } )->fields(
            {   role        => 1,
                description => 1,
                id          => 1,
                _id         => 0
            }
        )->sort( $sort ? { $sort => $dir } : { role => 1 } );
        while ( my $r = $roles_from_user->next ) {
            my $rs_user = ci->user->find(
                {   username                    => $username,
                    "project_security.$r->{id}" => { '$exists' => 1 }
                }
            )->next;
            my @roles = keys $rs_user->{project_security};

            my @user_projects;
            my @colls = map { Util->to_base_class($_) } Util->packages_that_do('Baseliner::Role::CI::Project');
            foreach my $col (@colls) {
                @user_projects = ( @user_projects, _array $rs_user->{project_security}->{ $r->{id} }->{$col} );
            }
            my @projects;
            foreach my $prjid (@user_projects) {
                my $str;
                my $parent;
                my $allpath;
                my $nature;
                my $project = ci->find($prjid);

                if ( $project && $project->{name} && $project->{active} ) {
                    if ( $project->{nature} ) {
                        $str = $project->{name} . ' (' . $project->{nature} . ')';
                    }
                    else {
                        $str = sprintf( '<img style="vertical-align:middle;" src="%s"/> %s', $project->icon,
                            $project->name );
                    }
                    push @projects, $str;
                }
            }
            @projects = sort(@projects);

            my @jsonprojects;
            foreach my $project (@projects) {
                my $str = { name => $project };
                push @jsonprojects, $str;
            }
            my $projects_txt = \@jsonprojects;

            if (@jsonprojects) {
                push @rows,
                  {
                    id           => $r->{id},
                    id_role      => $r->{id},
                    role         => $r->{role},
                    description  => $r->{description},
                    projects     => $projects_txt,
                    account_type => ( $r->{account_type} // 'regular' )
                  };
            }
        }
    }
    else {
        $authorized = 0;
        $msg = _loc( "User %1 is not authorized to query user details", $c->username );
    }

    if ($authorized) {
        $c->stash->{json} = { data => \@rows };
    }
    else {
        $c->stash->{json} = { msg => $msg };
    }

    $c->forward('View::JSON');
}

sub user_data : Local {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;

    my $username
        = $params->{username} && $self->_is_user_admin($c)
        ? $params->{username}
        : $c->username;
    try {
        my $user = ci->user->search_ci( username => $username );
        _fail _loc( 'User not found: %1', $username ) unless $user;
        $c->stash->{json} = {
            data      => $user,
            msg       => 'ok',
            languages => $c->installed_languages,
            success   => \1
        };
    }
    catch {
        my $err = shift;
        $c->stash->{json} = { msg => "$err", success => \0 };
    };
    $c->forward('View::JSON');
}

sub user_info : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $username = $p->{username};

    try {
        if ( !$username ) {
            _fail _loc('Missing parameter username');
        }
        my $user = ci->user->find( { username => $username } )->fields(
            {   username => 1,
                active   => 1,
                realmane => 1,
                alias    => 1,
                phone    => 1,
                mid      => 1,
                _id      => 0
            }
        )->next;
        _fail _loc( 'User not found: %1', $c->username ) unless $user;
        $c->stash->{json} = { %$user, msg => 'ok', success => \1 };
    }
    catch {
        my $err = shift;
        $c->stash->{json} = { msg => "$err", success => \0 };
    };
    $c->forward('View::JSON');
}

sub infoactions : Local {
    my ( $self, $c ) = @_;
    my $p          = $c->request->parameters;
    my $username   = $p->{username};
    my $id_role    = $p->{id_role};
    my $authorized = 1;
    my $msg        = '';

    my @actions;
    my @datas;
    my $data;

    my $is_user_admin = $self->_is_user_admin($c);
    my $is_role_admin = $self->_is_role_admin($c);
    my $own_user = $username && $username eq $c->username;

    if ($id_role) {
        if ($is_role_admin) {
            my $rs_actions
                = mdb->role->find( { id => $id_role } )->next->{actions};
            foreach my $rs ( _array $rs_actions) {
                my $desc = $rs->{action};
                eval {    # it may fail for keys that are not in the registry
                    my $action = $c->model('Registry')->get( $rs->{action} );
                    $desc = $action->name;
                };
                push @actions,
                    {
                    action      => $rs->{action},
                    description => $desc,
                    bl          => $rs->{bl}
                    };
            }
        }
        else {
            $authorized = 0;
            $msg
                = _loc( "User "
                    . $c->username
                    . " is not authorized to query role actions" );
        }
    }
    else {
        if ( $is_user_admin || $own_user ) {
            my @user_roles
                = map {$_}
                keys ci->user->find_one( { name => $username } )
                ->{project_security};
            my @roles
                = mdb->role->find( { id => { '$in' => \@user_roles } } )->all;
            my @res;
            foreach my $role (@roles) {
                push @res, @{ $role->{actions} };
            }

            my @datas
                = values +{ map { ( "$_->{action}_$_->{bl}" => $_ ) } @res };

            foreach $data (@datas) {
                my $desc = $data->{action};
                eval {    # it may fail for keys that are not in the registry
                    my $action
                        = $c->model('Registry')->get( $data->{action} );
                    $desc = $action->name;
                };
                push @actions,
                    {
                    action      => $data->{action},
                    description => $desc,
                    bl          => $data->{bl}
                    };
            }
        }
        else {
            $authorized = 0;
            $msg
                = _loc( "User "
                    . $c->username
                    . " is not authorized to query user actions" );
        }
    }

    if ($authorized) {
        $c->stash->{json} = { data => \@actions };
    }
    else {
        $c->stash->{json} = { msg => $msg };
    }
    $c->forward('View::JSON');
}

sub update : Local : Does('ACL') : ACL('action.admin.users') {
    my ( $self, $c ) = @_;

    return
      unless my $validated_params = $self->validate_params(
        $c,
        id           => { isa => 'Str',               default => '' },
        username     => { isa => 'Str' },
        pass         => { isa => 'Str',               default => '' },
        realname     => { isa => 'Str',               default => '' },
        alias        => { isa => 'Str',               default => '' },
        email        => { isa => 'Str',               default => '' },
        phone        => { isa => 'Str',               default => '' },
        account_type => { isa => 'Str',               default => 'regular' },
        groups       => { isa => 'Str|ArrayRef[Str]', default => [] }
      );

    my $mid = delete $validated_params->{id};
    $validated_params->{name} = $validated_params->{username};
    $validated_params->{password} = ci->user->encrypt_password( $validated_params->{username}, ( $validated_params->{pass} // '' ) );

    my $exists = ci->user->find_one(
        {
            username => $validated_params->{username},
            $mid ? ( mid => { '$ne' => $mid } ) : ()
        }
    );

    if ($exists) {
        $c->stash->{json} = {
            success => \0,
            msg     => _loc("Validation failed"),
            errors  => { username => _loc('User name already exists') }
        };
    }
    else {
        try {
            my $user;
            if ($mid) {
                $user = ci->new($mid);
                die 'User not found' unless $user;

                $user->update($validated_params);
            }
            else {
                $user = ci->user->new( bl => '*', active => '1', %$validated_params );
            }

            $user->save;

            $c->stash->{json} = { success => \1, msg => _loc('User saved'), user_id => $user->mid };

            my $username = $user->username;
            cache->remove(qr/:$username:/);
            cache->remove( { d => 'security' } );
            cache->remove( { d => "topic:meta" } );
            cache->remove( { d => "topic" } );
        }
        catch {
            my $error = shift;

            $c->stash->{json} = { success => \0, msg => _loc( 'Error saving user: %1', $error ) };
        };
    }

    $c->forward('View::JSON');

    return;
}

sub delete : Local : Does('ACL') : ACL('action.admin.users') {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $id       = $p->{id};
    my $username = $p->{username};

    try {
        my $user = ci->user->search_ci( '$or' => [ { mid => $id }, { username => $username } ] );
        die 'User not found' unless $user;

        $user->delete;

        $c->stash->{json} = { success => \1, msg => _loc('User deleted') };
    }
    catch {
        my $error = shift;

        $c->stash->{json} = { success => \0, msg => _loc( 'Error deleting User: %1', $error ) };
    };

    $c->forward('View::JSON');

    return;
}

sub roles_projects : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $id_user = $p->{id};

    my $user = ci->user->search_ci( mid => "$id_user" );
    die 'user not found' unless $user;

    my $is_user_admin = $self->_is_user_admin($c);
    my $own_user = $user->username && $user->username eq $c->username;

    die 'access denied' unless $is_user_admin || $own_user;

    my @rows;
    foreach my $row ( @{ $user->roles_projects } ) {
        push @rows,
          {
            id          => $row->{role}->{id},
            id_role     => $row->{role}->{id},
            role        => $row->{role}->{role},
            description => $row->{role}->{description},
            projects    => [ map { { name => $_->name, icon => $_->icon } } @{ $row->{projects} } ],
        };
    }

    $c->stash->{json} = { data => \@rows };
    $c->forward('View::JSON');

    return;
}

sub toggle_roles_projects : Local : Does('ACL') : ACL('action.admin.users') {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $action           = $p->{action};
    my $id_user          = $p->{id};
    my @projects_checked = _unique _array $p->{projects_checked};
    my @roles_checked    = _unique _array $p->{roles_checked};

    my $user = ci->user->search_ci( mid => "$id_user" );
    die 'user not found' unless $user;

    $user->toggle_roles_projects(
        action   => $action,
        projects => \@projects_checked,
        roles    => \@roles_checked
    );

    my $username = $user->username;
    cache->remove(qr/:$username:/);
    cache->remove( { d => 'security' } );
    cache->remove( { d => "topic:meta" } );
    cache->remove( { d => "topic" } );

    $c->stash->{json} = { success => \1, msg => 'ok' };
    $c->forward('View::JSON');

    return;
}

sub delete_roles : Local : Does('ACL') : ACL('action.admin.users') {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $action        = $p->{action};
    my $id_user       = $p->{id};
    my @roles_checked = _unique _array $p->{roles_checked};

    my $user = ci->user->search_ci( mid => "$id_user" );
    die 'user not found' unless $user;

    $user->delete_roles(roles => \@roles_checked);

    my $username = $user->username;
    cache->remove(qr/:$username:/);
    cache->remove( { d => 'security' } );
    cache->remove( { d => "topic:meta" } );
    cache->remove( { d => "topic" } );

    $c->stash->{json} = { success => \1, msg => 'ok' };
    $c->forward('View::JSON');

    return;
}

sub actions_list : Local {
    my ( $self, $c ) = @_;

    my @data;
    for my $role ( $c->model('Permissions')->user_roles( $c->username ) ) {
        for my $action ( _array $role->{actions} ) {
            push @data,
                {
                role        => $role->{role},
                description => $role->{description},
                action      => $action
                };
        }
    }
    $c->stash->{json} = { data => \@data, totalCount => scalar(@data) };
    $c->forward('View::JSON');
}

=head2 application_json

List the user applications (projects)

=cut

sub application_json : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my @rows;
    my $mask  = $p->{mask};
    my $query = $p->{query};
    $query and $query =~ s{\s+}{.*}g;    # convert query in regex

    foreach my $ns (
        Baseliner->model('Permissions')->user_namespaces( $c->username ) )
    {
        my ( $domain, $item ) = Util->ns_split($ns);
        next unless $item;
        next unless $domain =~ /application/;
        next if $query && $item !~ m/$query/i;
        next if $mask  && $item !~ m/$mask/i;
        push @rows,
            {
            name => $item,
            ns   => $ns
            };
    }
    $c->stash->{json} = {
        totalCount => scalar @rows,
        data       => \@rows
    };
    $c->forward('View::JSON');
}

=head2 project_json

List the user applications (projects)

=cut

sub project_json : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my @rows;
    my $mask  = $p->{mask};
    my $query = $p->{query};
    $query and $query =~ s{\s+}{.*}g;    # convert query in regex

    foreach my $ns (
        Baseliner->model('Permissions')->user_namespaces( $c->username ) )
    {
        my ( $domain, $item ) = ns_split($ns);
        next unless $item;
        next unless $domain =~ /application/;
        next if $query && $item !~ m/$query/i;
        next if $mask  && $item !~ m/$mask/i;
        push @rows,
            {
            name => $item,
            ns   => $ns
            };
    }
    $c->stash->{json} = {
        totalCount => scalar @rows,
        data       => \@rows
    };
    $c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;

    #$c->forward('/namespace/load_namespaces');
    $c->forward('/user/can_surrogate');
    $c->forward('/user/can_maintenance');
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/user_grid.js';
}

sub can_surrogate : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
    $c->stash->{can_surrogate} = $c->model('Permissions')->user_has_action( $c->username, 'action.surrogate' );
}

sub can_maintenance : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;

    $c->stash->{can_maintenance} = $self->_is_user_admin($c);
}

sub projects_list : Local {
    my ( $self, $c ) = @_;
    my $id             = $c->req->params->{node};
    my $project        = $c->req->params->{project};
    my $id_project     = $c->req->params->{id_project};
    my $parent_checked = $c->req->params->{parent_checked} || 0;

    my @colls = map { Util->to_base_class($_) }
        Util->packages_that_do('Baseliner::Role::CI::Project');
    my @datas
        = mdb->master_doc->find( { collection => mdb->in(@colls), active => '1' } )
        ->fields( { name => 1, description => 1, mid => 1 } )
        ->sort( { name => 1 } )->all;
    my @tree;
    foreach my $data (@datas) {
        push @tree,
            {
            text => $data->{name}
                . ( $data->{nature} ? " (" . $data->{nature} . ")" : '' ),
            nature      => $data->{nature}      ? $data->{nature}      : "",
            description => $data->{description} ? $data->{description} : "",
            url         => 'user/projects_list',
            data        => {
                id_project     => $data->{mid},
                project        => $data->{name},
                parent_checked => 0,
            },
            icon    => ci->new( $data->{mid} )->icon,
            leaf    => \1,
            checked => \0
            };
    }

    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub list : Local : Does('Ajax') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my ( $start, $limit, $query, $dir, $sort, $cnt )
        = ( @{$p}{qw/start limit query dir sort/}, 0 );

    $start ||= 0;
    $limit ||= 100;

    $sort ||= 'username';
    $dir  ||= 'asc';
    if ( $dir =~ /asc/i ) {
        $dir = 1;
    }
    else {
        $dir = -1;
    }

    my $where = $query
        ? mdb->query_build(
        query  => $query,
        fields => [qw(username realname alias)]
        )
        : {};

    $where->{active} = '1' if $p->{active_only};

    my $rs = ci->user->find($where)->fields(
        {   username      => 1,
            realname      => 1,
            account_type  => 1,
            alias         => 1,
            email         => 1,
            active        => 1,
            phone         => 1,
            mid           => 1,
            language_pref => 1,
            _id           => 0,
            ts            => 1
        }
    );
    $rs->sort( $sort ? { $sort => $dir } : { username => 1 } );
    if ($limit && $limit != -1) {
        $rs->limit($limit);
    }
    $rs->skip($start);

    $cnt = ci->user->find($where)->count();

    my @rows = ();

    for my $row ( $rs->all ) {
        my $ci = ci->new( $row->{mid} );
        my @groups = map { $_->{mid} } $ci->parents( where => { collection => 'UserGroup'});

        push @rows, {
            id     => $ci->mid,
            groups => \@groups,
            %{$row}
        };
    }

    if ( $p->{only_data} ) {
        $c->stash->{json} = \@rows;
    }
    else {
        $c->stash->{json} = { data => \@rows, totalCount => $cnt };
    }
    $c->forward('View::JSON');
}

sub change_pass : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $username = $p->{username} // $c->username;
    my $row = ci->user->find( { username => $username, active => mdb->true } )
        ->next;
    if ($row) {
        if ( ci->user->encrypt_password( $username, $p->{oldpass} ) eq
            $row->{password} )
        {
            if ( $p->{newpass} ) {
                my $user = ci->new( $row->{mid} );
                $user->update(
                    password => ci->user->encrypt_password(
                        $username, $p->{newpass}
                    )
                );
                $c->stash->{json}
                    = { msg => _loc('Password changed'), success => \1 };
            }
            else {
                $c->stash->{json} = {
                    msg     => _loc('You must introduce a new password'),
                    failure => \1
                };
            }
        }
        else {
            $c->stash->{json}
                = { msg => _loc('Password incorrect'), failure => \1 };
        }
    }
    else {
        $c->stash->{json} = {
            msg     => _loc( 'Error changing Password %1', shift() ),
            failure => \1
        };
    }

    $c->forward('View::JSON');
}

sub change_dashboard : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $username = $c->username;
    my $row      = ci->user->find_one(
        { username => $username, active => mdb->true } );

    if ($row) {
        my $user = ci->new( $row->{mid} );
        $user->update( dashboard => $p->{dashboard} );
        $c->stash->{json}
            = { msg => _loc('Default dashboard changed'), success => \1 };
    }
    else {
        $c->stash->{json} = {
            msg     => _loc( 'Error changing default dashboard %1', shift() ),
            failure => \1
        };
    }

    $c->forward('View::JSON');
}

sub repl_config : Local {
    my ( $self, $c ) = @_;

    my $username = $c->username;

    my $row = ci->user->find_one(
        { username => $username, active => mdb->true } );

    if ($row) {
        $c->stash->{json} = { data => $row->{repl} };
    }
    $c->forward('View::JSON');
}

sub update_repl_config : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my @fields = qw(lang syntax out theme);

    my $username = $c->username;

    my $row = ci->user->find_one(
        { username => $username, active => mdb->true } );

    if ($row) {
        my $user = ci->new( $row->{mid} );

        for my $field (@fields) {
            $user->repl->{$field} = $p->{$field}
                if defined $p->{$field};
        }

        $user->save;
        $c->stash->{json} = { data => $user->{repl} };
    }
    $c->forward('View::JSON');
}

sub avatar : Local {
    my ( $self, $c, $username, $dummy_filename ) = @_;

    if ( !$dummy_filename ) {
        $dummy_filename = $username;
        $username       = $c->username;
    }

    my $default_icon = "root/static/images/icons/user.png";

    my $file = try {
        my $file = _dir( $c->path_to("/root/identicon") );
        $file->mkpath unless -d $file;

        $file = _file( $file, $username . ".png" );
        unless ( -e $file ) {
            my $identicon_generator
                = $self->_build_identicon_generator( default_icon => $c->path_to($default_icon) );
            my $png = $identicon_generator->identicon;

            my $fh = $file->openw or _fail $!;
            binmode $fh;
            print $fh $png;
            close $fh;
        }

        return $file;
    }
    catch {
        my $err = shift;

        _log "Identicon failed: $err";

        return $c->path_to($default_icon);
    };

    if ( defined $file ) {
        $c->serve_static_file($file);
    }
    else {
        _throw 'Avatar generation failed badly';
    }

    $c->res->content_type('image/png');

    return;
}

sub avatar_refresh : Local {
    my ( $self, $c, $username ) = @_;

    $username ||= $c->username;

    if ( $username ne $c->username && !$self->_is_user_admin($c) ) {
        _fail _loc
          'Cannot change avatar for user %1: user %2 not administrator',
          $username, $c->username;
    }

    try {
        my $avatar = _file( $c->path_to("/root/identicon"), $username . '.png' );
        unlink $avatar or _fail "Error removing previous avatar '$avatar': $!";
        $c->stash->{json} =
          { success => \1, msg => _loc('Avatar refreshed') };
    }
    catch {
        my $err = shift;
        _error "Error refreshing avatar: " . $err;
        $c->stash->{json} = { success => \0, msg => $err };
    };

    $c->forward('View::JSON');
}

sub avatar_upload : Local {
    my ( $self, $c, $username ) = @_;

    my $p  = $c->req->params;
    my $fh = $c->req->body;

    $username //= $c->username;

    _log "Uploading avatar";

    if ( $username ne $c->username && !$self->_is_user_admin($c) ) {
        _fail _loc
          'Cannot change avatar for user %1: user %2 not administrator',
          $username, $c->username;
    }

    try {
        my $dir = _dir( $c->path_to("/root/identicon") );
        $dir->mkpath;

        my $avatar = _file( $dir, $username . '.png' );

        _debug "Avatar file=$avatar";

        File::Copy::copy( $fh, "$avatar" ) or _fail "Error saving uploaded avatar: $!";

        my $image;
        capture { $image = GD::Image->new("$avatar") or _fail "Error initializing GD object: $!" };

        # TODO: this probably should be configurable in global config
        my $width  = 32;
        my $height = 32;

        my $image_resized = GD::Image->new( $width, $height );
        $image_resized->copyResampled( $image, 0, 0, 0, 0, $width, $height, $image->width, $image->height );

        open my $fh, '>', "$avatar" or _fail "Error resizing avatar: $!";
        print $fh $image_resized->png;
        close $fh;

        $c->stash->{json} =
          { success => \1, msg => _loc('Changed user avatar') };
    }
    catch {
        my $err = shift;

        _error "Error uploading avatar: " . $err;

        $c->stash->{json} = { success => \0, msg => $err };
    };

    $c->forward('View::JSON');

    return;
}

sub _is_user_admin {
    my ( $self, $c, $username, $action ) = @_;

    my $permissions = Baseliner::Model::Permissions->new;

    return $permissions->user_has_action( $c->username, 'action.admin.users' );
}

sub _is_role_admin {
    my ( $self, $c, $username, $action ) = @_;

    my $permissions = Baseliner::Model::Permissions->new;

    return $permissions->user_has_action( $c->username, 'action.admin.role' );
}

sub duplicate : Local : Does('ACL') : ACL('action.admin.users') {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    try {
        my $user = ci->user->search_ci(mid => $p->{id_user});
        die 'User not found' unless $user;

        my $new_username_pattern = sprintf 'Duplicate of %s', $user->username;
        my $new_username = $new_username_pattern;

        for ( 1 .. 1000 ) {
            last unless ci->user->find_one( { username => $new_username } );
            die 'Infinite loop when duplicating user' if $_ == 1000;

            $new_username = $new_username_pattern . ' ' . ($_ + 1);
        }

        my $ci_data = {
            name             => $new_username,
            bl               => '*',
            username         => $new_username,
            realname         => $user->realname,
            alias            => $user->alias,
            email            => $user->email,
            phone            => $user->phone,
            active           => '1',
            project_security => $user->project_security,
            groups           => [ map { $_->mid } _array $user->groups ]
        };

        my $ci = ci->user->new(%$ci_data);
        $ci->save;

        $c->stash->{json} = { success => \1, msg => _loc('User duplicated') };
    }
    catch {
        $c->stash->{json} = { success => \0, msg => _loc('Error duplicating user') };
    };

    $c->forward('View::JSON');

    return;
}

sub country_info : Local {
    my ( $self, $c ) = @_;
    my @countries;
    my $i   = 0;
    my $xml = XML::Simple->new;
    my $zones_file = $c->path_to("/data/zones.xml");
    my $str;
    try {
        if ( !-e $zones_file ) {
            _fail _loc('Error: File not found');
        }
        my $zones = $xml->XMLin( "$zones_file" );
        for my $country (all_country_names()) {
            my $code     = country2code($country);
            my $currency = $zones->{CcyNtry}[$i]{Ccy} or _fail "Error to find the currency";
            my $decimal  = $zones->{CcyNtry}[$i]{Decimal} or _fail "Error to find the decimal";
            $i++;
            my $data_country = [ $code, $country, $currency, $decimal ];
            push @countries, $data_country;
        }

        $c->stash->{json} = { success => \1, msg => _loc('Country info success'), data => \@countries };
    }

    catch {
        my $err = shift;

        $c->stash->{json} = { success => \0, msg => $err };
    };

    $c->forward('View::JSON');
}

sub timezone_list : Local {
    my ( $self, $c ) = @_;
    my @tzs;

    for my $tz ( DateTime::TimeZone->all_names ) {
       my $timezone = [$tz,$tz];
        push @tzs, $timezone;
    }
    $c->stash->{json} = { data => \@tzs };
    $c->forward('View::JSON');
}

sub _build_identicon_generator {
    my $self = shift;

    return Baseliner::IdenticonGenerator->new(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
