package Baseliner::Controller::User;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use File::Copy ();
use GD::Image;
use Baseliner::IdenticonGenerator;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_log _debug _error _loc _fail _throw _file _dir _array _unique);

use experimental 'switch', 'autoderef';

register 'config.user.global' => {
    preference => 1,
    desc       => 'Global Preferences',
    metadata   => [
        {   id      => 'language',
            label   => 'Language',
            type    => 'combo',
            default => Baseliner->config->{default_lang},
            store   => [ 'es', 'en' ]
        },
    ]
};
register 'config.user.view' => {
    preference => 1,
    desc       => 'View Preferences',
    metadata   => [
        {   id      => 'theme',
            label   => 'Theme',
            type    => 'combo',
            default => Baseliner->config->{default_theme},
            store   => [ 'gray', 'blue', 'slate' ]
        },
    ]
};
register 'action.admin.users' => { name => 'User Admin', };

register 'menu.admin.users' => {
    label    => 'Users',
    url_comp => '/user/grid',
    actions  => ['action.admin.users'],
    title    => 'Users',
    index    => 80,
    icon     => '/static/images/icons/user.gif'
};

register 'event.user.create' => {
    text        => 'New user created: %2',
    description => 'User posted a comment',
    vars        => [ 'username', 'realname', 'email' ]
};

sub preferences : Local {
    my ( $self, $c ) = @_;
    my @config = $c->model('Registry')
        ->search_for( key => 'config', preference => 1 );
    $c->stash->{ns}    = 'user/' . ( $c->user->username || $c->user->id );
    $c->stash->{bl}    = '*';
    $c->stash->{title} = _loc 'User Preferences';
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
    my $username = $p->{username};

    my $authorized = 1;
    my $msg        = '';

    my @actions;
    my @datas;
    my $data;
    my $auth     = $c->model('permissions');
    my $can_user = $auth->user_has_action(
        username => $c->username,
        action   => 'action.admin.users'
    );
    my $own_user = $username && $username eq $c->username;

    my @rows;
    if ( $can_user || $own_user ) {
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

        my $user = ci->user->find( { username => $username } )->next;
        my @roles;
        if ( $user->{project_security} ) {
            @roles = keys $user->{project_security};
            @roles = map {$_} @roles;
        }
        my $roles_from_user
            = mdb->role->find( { id => { '$in' => \@roles } } )->fields(
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
            my @colls = map { Util->to_base_class($_) }
                Util->packages_that_do('Baseliner::Role::CI::Project');
            foreach my $col (@colls) {
                @user_projects = (
                    @user_projects,
                    _array $rs_user->{project_security}->{ $r->{id} }->{$col}
                );
            }

            my @projects;
            foreach my $prjid (@user_projects) {
                my $str;
                my $parent;
                my $allpath;
                my $nature;
                my $project = ci->find($prjid);

                if ( $project and $project->{name} ) {
                    if ( $project->{nature} ) {
                        $str = $project->{name} . ' ('
                            . $project->{nature} . ')';
                    }
                    else {
                        $str = $project->{name};
                    }
                }
                else {
                    $str = '';
                }
                push @projects, $str;
            }
            @projects = sort(@projects);

            my @jsonprojects;
            foreach my $project (@projects) {
                my $str = { name => $project };
                push @jsonprojects, $str;
            }
            my $projects_txt = \@jsonprojects;

            push @rows,
                {
                id          => $r->{id},
                id_role     => $r->{id},
                role        => $r->{role},
                description => $r->{description},
                projects    => $projects_txt
                };
        }
    }
    else {
        $authorized = 0;
        $msg
            = _loc( "User "
                . $c->username
                . " is not authorized to query user details" );
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
        = $params->{username} && $c->has_action('action.admin.users')
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

    my $auth      = $c->model('permissions');
    my $can_roles = $auth->user_has_action(
        username => $c->username,
        action   => 'action.admin.roles'
    );
    my $can_user = $auth->user_has_action(
        username => $c->username,
        action   => 'action.admin.users'
    );
    my $own_user = $username && $username eq $c->username;

    if ($id_role) {
        if ($can_roles) {
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
        if ( $can_user || $own_user ) {
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

sub update : Local {
    my ( $self, $c ) = @_;
    my $p                        = $c->request->parameters;
    my $action                   = $p->{action};
    my $projects_checked         = $p->{projects_checked};
    my $projects_parents_checked = $p->{projects_parents_checked};
    my $roles_checked            = $p->{roles_checked};
    my $project;

    given ($action) {
        when ('add') {
            try {
                my $swOk = 1;
                my $row
                    = ci->user->find(
                    { username => $p->{username}, active => mdb->true } )
                    ->next;
                if ( !$row ) {
                    my $user_mid;

                    my $ci_data = {
                        name     => $p->{username},
                        bl       => '*',
                        username => $p->{username},
                        realname => $p->{realname},
                        alias    => $p->{alias},
                        email    => $p->{email},
                        phone    => $p->{phone},
                        active   => '1',
                        password => ci->user->encrypt_password(
                            $p->{username}, $p->{pass}
                        )
                    };

                    my $ci = ci->user->new(%$ci_data);
                    $ci->gen_project_security( $projects_checked,
                        $roles_checked );
                    $ci->password(
                        ci->user->encrypt_password(
                            $p->{username}, $p->{pass}
                        )
                    );
                    $user_mid = $ci->save;
                    $c->stash->{json} = {
                        msg     => _loc('User added'),
                        success => \1,
                        user_id => $user_mid
                    };

                }
                else {
                    $c->stash->{json} = {
                        msg => _loc(
                            'User name already exists, introduce another user name'
                        ),
                        failure => \1
                    };
                }
            }
            catch {
                $c->stash->{json} = {
                    msg     => _loc( 'Error adding User: %1', shift() ),
                    failure => \1
                    }
            }
        }
        when ('update') {
            try {
                my $type_save = $p->{type};
                if ( $type_save eq 'user' ) {
                    my $user;
                    my $user_id = $p->{id};
                    if ( $p->{id} ) {
                        $user = ci->new( $p->{id} );
                    }
                    else {
                        $user = ci->user->search_ci( name => $p->{username} );
                        _fail _loc("User not found") if !$user;
                        $user_id = $user->{mid};
                    }
                    my $old_username = $user->{username};
                    if ( $old_username ne $p->{username} ) {
                        my $user_ci = ci->user->find_one(
                            { username => $p->{username} } );
                        if ($user_ci) {
                            $c->stash->{json} = {
                                msg => _loc(
                                    'User name already exists, introduce another user name'
                                ),
                                failure => \1
                            };
                            _fail _loc(
                                "User name already exists, introduce another user name"
                            );
                        }
                        else {
                            $user_ci = ci->user->find_one(
                                { username => $old_username } );
                            my $user_mid = $user_ci->{mid};

                            my $ci_data = {
                                name     => $p->{username},
                                bl       => '*',
                                username => $p->{username},
                                realname => $p->{realname},
                                alias    => $p->{alias},
                                email    => $p->{email},
                                phone    => $p->{phone},
                                active   => '1',
                                password => ci->user->encrypt_password(
                                    $p->{username}, $p->{pass}
                                ),
                                project_security =>
                                    $user_ci->{project_security}
                            };

                            my $ci       = ci->user->new(%$ci_data);
                            my $user_new = $ci->save;

                            mdb->master_rel->update(
                                { from_mid => "$$p{id}" },
                                { '$set'   => { from_mid => $user_new } },
                                { multiple => 1 }
                            );
                            mdb->master_rel->update(
                                { to_mid   => "$$p{id}" },
                                { '$set'   => { to_mid => $user_new } },
                                { multiple => 1 }
                            );
                            ci->delete($user_mid);
                        }
                    }
                    else {
                        $user->update( realname => $p->{realname} )
                            if $p->{realname};

                        if ( $p->{pass} ) {
                            $user->update(
                                password => ci->user->encrypt_password(
                                    $p->{username}, $p->{pass}
                                )
                            );
                        }
                        $user->update( alias => $p->{alias} ) if $p->{alias};
                        $user->update( email => $p->{email} );
                        $user->update( phone => $p->{phone} ) if $p->{phone};
                        $user->update( active => $p->{active} )
                            if $p->{active};
                        $user->save;
                    }

                    $c->stash->{json} = {
                        msg     => _loc('User modified'),
                        success => \1,
                        user_id => $user_id
                    };
                }
                else {

   # regenerate project security for all users TODO work with my ci only: DONE
                    my $ci = ci->user->search_ci( name => $p->{username} );
                    _fail _loc 'Could not find ci for user %1', $p->{username}
                        unless $ci;
                    _debug 'Re-generating user project security...';
                    $ci->gen_project_security( $projects_checked,
                        $roles_checked );
                    $ci->save;
                    _debug 'Done updating project security.';

                    $c->stash->{json} = {
                        msg     => _loc('User modified'),
                        success => \1,
                        user_id => $p->{id}
                    };
                }
            }
            catch {
                $c->stash->{json} = {
                    msg     => _loc( 'Error modifying User: %1', shift() ),
                    failure => \1
                    }
            }
        }
        when ('delete') {
            try {
                my $user;
                my $user_id = $p->{id};
                if ( length $user_id ) {
                    $user = ci->new($user_id);
                }
                else {
                    $user = ci->user->find( { username => $p->{username} } );
                    _fail _loc("User not found") if !$user;
                    $user_id = $user->{id};
                } ## end else [ if ( $p->{id} ) ]
                ci->delete($user_id);
                $c->stash->{json}
                    = { success => \1, msg => _loc('User deleted') };
            } ## end try
            catch {
                $c->stash->{json} = {
                    failure => \1,
                    msg     => _loc( 'Error deleting User: %1', shift() )
                };
            }
        } ## end when ( 'delete' )
        when ('delete_roles_projects') {
            try {
                my $user_name = $p->{username};
                my $rs;

                my @colls = map { Util->to_base_class($_) }
                    Util->packages_that_do('Baseliner::Role::CI::Project');
                my $orig_ps = ci->user->find( { username => $user_name } )
                    ->next->{project_security};

                if ($roles_checked) {
                    if ($projects_checked) {
                        my @user_projects;
                        my @ns_projects = _unique _array $projects_checked;
                        foreach my $role ( _array $roles_checked) {
                            my $rs_user;
                            my @where = map {
                                { "project_security.$role.$_" =>
                                        { '$in' => \@ns_projects } }
                            } @colls;
                            $rs_user = ci->user->find_one(
                                {   username => $user_name,
                                    "project_security.$role" =>
                                        { '$exists' => 1 },
                                    '$or' => \@where
                                }
                            );

                            foreach my $coll (@colls) {
                                push @user_projects,
                                    map { $role . '/' . $coll . '/' . $_ }
                                    _array $rs_user->{project_security}
                                    ->{$role}->{$coll};
                            }
                        }

                        my %tmp;
                        @tmp{@ns_projects} = ();

                        my @user_projects_erased = grep {
                            $_
                                =~ /(?<urole>.+)\/(?<collection>.+)\/(?<pid>.+)/;
                            my $pid = $+{pid};
                            exists $tmp{$pid}
                        } @user_projects;

                        foreach my $p_id_ns (@user_projects_erased) {
                            $p_id_ns
                                =~ /(?<urole>.+)\/(?<collection>.+)\/(?<pid>.+)/;
                            my $pid  = $+{pid};
                            my $pcol = $+{collection};
                            my $role = $+{urole};
                            my @tmp  = @{ $orig_ps->{$role}{$pcol} };
                            my @new_items;
                            for ( my $i = 0; $i < scalar @tmp; $i++ ) {
                                if ( $tmp[$i] ne $pid ) {
                                    push @new_items, $tmp[$i];
                                }
                            }
                            if (@new_items) {
                                $orig_ps->{$role}{$pcol} = \@new_items;
                            }
                            else {
                                delete $orig_ps->{$role}{$pcol};
                                my @values = values $orig_ps->{$role};
                                delete $orig_ps->{$role} if !@values;
                            }
                        }

                    }
                    else {
                        #delete all projects with $role for $user_name
                        delete @$orig_ps{ _array $roles_checked};
                    }
                }
                else {

                    my @user_projects;
                    my $user
                        = ci->user->find( { username => $user_name } )->next;
                    my @roles = keys $user->{project_security};
                    foreach my $role (@roles) {
                        foreach my $coll (@colls) {
                            push @user_projects,
                                map { $role . '/' . $coll . '/' . $_ }
                                _array $user->{project_security}->{$role}
                                ->{$coll};
                        }
                    }

                    my @ns_projects = _unique _array $projects_checked;
                    my %tmp;
                    @tmp{@ns_projects} = ();

                    my @user_projects_erased = grep {
                        my $pid;
                        if ( $_ =~ /(?<urole>.+)\/(?<ucol>.+)\/(?<pid>.+)/ ) {
                            $pid = $+{pid};
                        }
                        exists $tmp{$pid}
                    } @user_projects;

                    foreach my $p_id_ns (@user_projects_erased) {
                        $p_id_ns
                            =~ /(?<urole>.+)\/(?<collection>.+)\/(?<pid>.+)/;
                        my $pid  = $+{pid};
                        my $pcol = $+{collection};
                        my $role = $+{urole};
                        my @tmp  = @{ $orig_ps->{$role}{$pcol} };
                        my @new_items;
                        for ( my $i = 0; $i < scalar @tmp; $i++ ) {
                            if ( $tmp[$i] ne $pid ) {
                                push @new_items, $tmp[$i];
                            }
                        }
                        if (@new_items) {
                            $orig_ps->{$role}{$pcol} = \@new_items;
                        }
                        else {
                            delete $orig_ps->{$role}{$pcol};
                            my @values = values $orig_ps->{$role};
                            delete $orig_ps->{$role} if !@values;
                        }
                    }
                }

         # regenerate project security for all users TODO work with my ci only
                my $user_ci = ci->new(
                    ci->user->find_one( { username => $user_name } )->{mid} );

                $user_ci->update( project_security => $orig_ps );

                #$ci->save;

                $c->stash->{json}
                    = { msg => _loc('User modified'), success => \1 };
            }
            catch {
                $c->stash->{json} = {
                    success => \0,
                    msg     => _loc( 'Error modifying User: %1', shift() )
                };
            }
        }
    }
    cache->remove(qr/:$p->{username}:/);
    cache->remove( { d => 'security' } );
    cache->remove( { d => "topic:meta" } );
    cache->remove( { d => "topic" } );

    $c->forward('View::JSON');
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
    $c->stash->{can_surrogate} = $c->model('Permissions')->user_has_action(
        username => $c->username,
        action   => 'action.surrogate'
    );
}

sub can_maintenance : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
    $c->stash->{can_maintenance} = $c->model('Permissions')->user_has_action(
        username => $c->username,
        action   => 'action.admin.users'
    );
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
        = mdb->master_doc->find( { collection => mdb->in(@colls) } )
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
    $rs->skip($start);
    $rs->limit($limit);

    $cnt = ci->user->find($where)->count();

    my @rows = map { +{ id => $_->{mid}, %{$_} }; } $rs->all;

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

    if ( $username ne $c->username && !$self->_user_has_action( $c->username, 'action.admin.users' ) ) {
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

    if ( $username ne $c->username && !$self->_user_has_action( $c->username, 'action.admin.users' ) ) {
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

        my $image = GD::Image->new("$avatar") or _fail "Error initializing GD object: $!";

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

sub _user_has_action {
    my $self = shift;
    my ( $username, $action ) = @_;

    my $permissions = Baseliner::Model::Permissions->new;

    if ( $action =~ /%/ ) {
        return $permissions->user_has_any_action( action => $action, username => $username );
    }
    else {
        return $permissions->user_has_action( action => $action, username => $username );
    }
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $r = ci->user->find( { mid => $p->{id_user} } )->next;
        if ($r) {
            my $user;
            my $new_user;

            my $row;
            my $cont = 2;
            $new_user = "Duplicate of " . $r->{username};
            $row      = ci->user->find(
                { username => $new_user, active => mdb->true } )->next;
            while ($row) {
                $new_user = "Duplicate of " . $r->{username} . " " . $cont++;
                $row      = ci->user->find(
                    { username => $new_user, active => mdb->true } )->next;
            }
            if ( !$row ) {
                my $user_mid;

                my $ci_data = {
                    name             => $new_user,
                    bl               => '*',
                    username         => $new_user,
                    realname         => $r->{realname},
                    alias            => $r->{alias},
                    email            => $r->{email},
                    phone            => $r->{phone},
                    active           => '1',
                    project_security => $r->{project_security},
                };

                my $ci = ci->user->new(%$ci_data);
                $user_mid = $ci->save;
                $c->stash->{json} = {
                    msg     => _loc('User added'),
                    success => \1,
                    user_id => $user_mid
                };
            }
            $c->stash->{json}
                = { success => \1, msg => _loc("User duplicated") };
        }
    }
    catch {
        $c->stash->{json}
            = { success => \0, msg => _loc('Error duplicating user') };
    };

    $c->forward('View::JSON');
}

sub _build_identicon_generator {
    my $self = shift;

    return Baseliner::IdenticonGenerator->new(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
