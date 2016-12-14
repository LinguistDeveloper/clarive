package Baseliner::Controller::UserGroup;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN { extends 'Catalyst::Controller' }
use experimental 'autoderef', 'switch';

register 'action.admin.user_groups' => { name => 'User groups Admin', };

register 'menu.admin.user_groups' => {
    label    => _loc('User Groups'),
    url_comp => '/usergroup/grid',
    actions  => ['action.admin.user_groups'],
    title    => 'User groups',
    index    => 80,
    icon     => '/static/images/icons/users.svg'
};

sub infodetail : Local {
    my ( $self, $c ) = @_;
    my $p         = $c->request->parameters;
    my $groupname = $p->{groupname};

    my $authorized = 1;
    my $msg        = '';

    my @rows;
    my ( $start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );

    $sort ||= 'role';
    $dir  ||= 'asc';

    if ( $dir =~ /asc/i ) {
        $dir = 1;
    } else {
        $dir = -1;
    }

    my $usergroup = ci->UserGroup->find( { groupname => $groupname } )->next;
    my @roles;

    if ( $usergroup->{project_security} ) {
        @roles = keys $usergroup->{project_security};
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
        my $rs_group
            = ci->UserGroup->find( { groupname => $groupname, "project_security.$r->{id}" => { '$exists' => 1 } } )
            ->next;
        my @usergroup_projects;
        my @colls = map { Util->to_base_class($_) } packages_that_do('Baseliner::Role::CI::Project');

        foreach my $col (@colls) {
            @usergroup_projects = ( @usergroup_projects, _array $rs_group->{project_security}->{ $r->{id} }->{$col} );
        }

        my @projects;

        foreach my $prjid (@usergroup_projects) {
            my $str;
            my $project = ci->find($prjid);

            if ( $project and $project->{name} ) {
                if ( $project->{nature} ) {
                    $str = $project->{name} . ' (' . $project->{nature} . ')';
                } else {
                    $str = $project->{name};
                }
            } else {
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

        push @rows, {
            id          => $r->{id},
            id_role     => $r->{id},
            role        => $r->{role},
            description => $r->{description},
            projects    => $projects_txt
        };
    }

    $c->stash->{json} = { data => \@rows };
    $c->forward('View::JSON');

    return;
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my $action = $p->{action} // _fail( _loc("Missing action") );

    my $projects_checked         = $p->{projects_checked};
    my $projects_parents_checked = $p->{projects_parents_checked};
    my $roles_checked            = $p->{roles_checked};
    my $project;

    given ($action) {
        when ('add') {

            try {
                _fail( _loc("Missing groupname") ) if !$p->{groupname};

                my $row = ci->UserGroup->find( { groupname => $p->{groupname}, active => mdb->true } )->next;

                if ( !$row ) {
                    my $group_mid;

                    my $ci_data = {
                        name      => $p->{groupname},
                        bl        => '*',
                        groupname => $p->{groupname},
                        active    => '1'
                    };

                    my $ci = ci->UserGroup->new(%$ci_data);

                    $ci->gen_project_security( $projects_checked, $roles_checked );
                    $group_mid = $ci->save;
                    $ci->set_users( _array( $p->{users} ) );
                    $c->stash->{json} = { msg => _loc('User group added'), success => \1, user_id => $group_mid };

                } else {
                    $c->stash->{json} = {
                        msg => _loc('Group name already exists.  Specify another group name'),
                        success => \0
                    };
                }
            }
            catch {
                $c->stash->{json} = { msg => _loc( 'Error adding User group: %1', shift() ), success => \0 };
            }
        }
        when ('update') {

            try {
                my $type_save    = $p->{type} // _fail( _loc("Missing update type") );
                my $usergroup_id = $p->{id}   // _fail( _loc("Missing group mid") );
                my $usergroup = ci->UserGroup->search_ci( mid => $usergroup_id );

                _fail( _loc("Group not found") ) if !$usergroup;

                if ( $type_save eq 'group' ) {
                    my $old_groupname = $usergroup->groupname;

                    if ( $old_groupname ne $p->{groupname} ) {
                        my $usergroup_ci = ci->UserGroup->find_one( { groupname => $p->{groupname} } );

                        if ($usergroup_ci) {
                            _fail( _loc("Group name already exists.  Specify another group name") );
                        }
                    }

                    $usergroup->update( active => $p->{active} ) if $p->{active};
                    $usergroup->update( name => $p->{groupname}, groupname => $p->{groupname} );
                    $usergroup->save;
                    $usergroup->set_users( _array( $p->{users} ) );

                    $c->stash->{json} = { msg => _loc('User group modified'), success => \1, user_id => $usergroup_id };
                } else {
                    _debug 'Re-generating group project security...';
                    $usergroup->gen_project_security( $projects_checked, $roles_checked );
                    $usergroup->save;
                    $usergroup->set_users( _array( $p->{users} ) );

                    $c->stash->{json} = { msg => _loc('User group modified'), success => \1, group_id => $p->{id} };
                }
            }
            catch {
                $c->stash->{json} = { msg => _loc( 'Error modifying user group: %1', shift() ), success => \0 };
            }
        }
        when ('delete') {
            try {
                my $group_id = $p->{id} // _fail( _loc("Missing id") );
                my $group = ci->new($group_id);

                ci->delete($group_id);

                $c->stash->{json} = { success => \1, msg => _loc('User group deleted') };
            }
            catch {
                $c->stash->{json} = { success => \0, msg => _loc( 'Error deleting User group: %1', shift() ) };
            }
        } ## end when ( 'delete' )
        when ('delete_roles_projects') {
            try {
                _fail( _loc("Missing id") ) if !$p->{id};

                my $rs;
                my @colls = map { Util->to_base_class($_) } packages_that_do('Baseliner::Role::CI::Project');
                my $orig_ps = ci->UserGroup->find_one( { mid => $p->{id} } )->{project_security};

                if ($roles_checked) {
                    if ($projects_checked) {
                        my @usergroup_projects;
                        my @ns_projects = _unique _array $projects_checked;

                        foreach my $role ( _array $roles_checked) {
                            my $rs_group;
                            my @where = map { { "project_security.$role.$_" => { '$in' => \@ns_projects } } } @colls;

                            $rs_group = ci->UserGroup->find_one(
                                { mid => $p->{id}, "project_security.$role" => { '$exists' => 1 }, '$or' => \@where } );

                            foreach my $coll (@colls) {
                                push @usergroup_projects,
                                    map { $role . '/' . $coll . '/' . $_ }
                                    _array $rs_group->{project_security}->{$role}->{$coll};
                            }
                        }

                        my %tmp;
                        @tmp{@ns_projects} = ();

                        my @usergroup_projects_erased = grep {
                            $_ =~ /(?<urole>.+)\/(?<collection>.+)\/(?<pid>.+)/;
                            my $pid = $+{pid};
                            exists $tmp{$pid}
                        } @usergroup_projects;

                        foreach my $p_id_ns (@usergroup_projects_erased) {
                            $p_id_ns =~ /(?<urole>.+)\/(?<collection>.+)\/(?<pid>.+)/;
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
                            } else {
                                delete $orig_ps->{$role}{$pcol};
                                my @values = values $orig_ps->{$role};
                                delete $orig_ps->{$role} if !@values;
                            }
                        }

                    } else {
                        #delete all projects with $role for $user_name
                        delete @$orig_ps{ _array $roles_checked};
                    }
                } else {

                    my @usergroup_projects;
                    my $usergroup = ci->UserGroup->find_one( { mid => $p->{id} } );
                    my @roles = keys $usergroup->{project_security};

                    foreach my $role (@roles) {
                        foreach my $coll (@colls) {
                            push @usergroup_projects,
                                map { $role . '/' . $coll . '/' . $_ }
                                _array $usergroup->{project_security}->{$role}->{$coll};
                        }
                    }

                    my @ns_projects = _unique _array $projects_checked;
                    my %tmp;

                    @tmp{@ns_projects} = ();

                    my @usergroup_projects_erased = grep {
                        my $pid;
                        if ( $_ =~ /(?<urole>.+)\/(?<ucol>.+)\/(?<pid>.+)/ ) {
                            $pid = $+{pid};
                        }
                        exists $tmp{$pid}
                    } @usergroup_projects;

                    foreach my $p_id_ns (@usergroup_projects_erased) {
                        $p_id_ns =~ /(?<urole>.+)\/(?<collection>.+)\/(?<pid>.+)/;
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
                        } else {
                            delete $orig_ps->{$role}{$pcol};
                            my @values = values $orig_ps->{$role};
                            delete $orig_ps->{$role} if !@values;
                        }
                    }
                }

                # regenerate project security for all users TODO work with my ci only
                my $usergroup_ci = ci->new( $p->{id} );

                $usergroup_ci->update( project_security => $orig_ps );
                $usergroup_ci->set_users( _array( $p->{users} ) );

                $c->stash->{json} = { msg => _loc('User group modified'), success => \1 };
            }
            catch {
                $c->stash->{json} = { success => \0, msg => _loc( 'Error modifying user group: %1', shift() ) };
            }
        }
    }
    $c->forward('View::JSON');

    return;
}

sub actions_list : Local {
    my ( $self, $c ) = @_;

    my @data;
    for my $role ( $c->model('Permissions')->user_roles( $c->username ) ) {
        for my $action ( _array $role->{actions} ) {
            push @data, { role => $role->{role}, description => $role->{description}, action => $action };
        }
    }
    $c->stash->{json} = { data => \@data, totalCount => scalar(@data) };
    $c->forward('View::JSON');

    return;
}

sub grid : Local {
    my ( $self, $c ) = @_;

    #$c->forward('/namespace/load_namespaces');
    $c->forward('/user/can_surrogate');
    $c->forward('/user/can_maintenance');
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/user_group_grid.js';

    return;
}

sub list : Local : Does('Ajax') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my ( $start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );

    $start ||= 0;
    $limit ||= 100;

    $sort ||= 'groupname';
    $dir  ||= 'asc';
    if ( $dir =~ /asc/i ) {
        $dir = 1;
    } else {
        $dir = -1;
    }

    my $where = $query ? mdb->query_build( query => $query, fields => [qw(groupname realname alias)] ) : {};

    $where->{active} = '1' if $p->{active_only};

    my $rs = ci->UserGroup->find($where)->fields(
        {   groupname     => 1,
            realname      => 1,
            alias         => 1,
            email         => 1,
            active        => 1,
            phone         => 1,
            mid           => 1,
            language_pref => 1,
            _id           => 0
        }
    );
    $rs->sort( $sort ? { $sort => $dir } : { groupname => 1 } );
    $rs->skip($start);

    if ( $limit && $limit != -1 ) {
        $rs->limit($limit);
    }

    $cnt = ci->UserGroup->find($where)->count();

    my @rows = ();

    for my $row ( $rs->all ) {
        my $ci         = ci->new( $row->{mid} );
        my @ci_users   = $ci->children( where => { collection => 'user'}, docs_only => 1);
        my @users      = map { $_->{mid} } @ci_users;
        my @user_names = map { $_->{name} } @ci_users;

        push @rows, {
            id         => $ci->mid,
            users      => \@users,
            user_names => \@user_names,
            %{$row}
        };
    }

    if ( $p->{only_data} ) {
        $c->stash->{json} = \@rows;
    } else {
        $c->stash->{json} = { data => \@rows, totalCount => $cnt };
    }
    $c->forward('View::JSON');

    return;
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    try {
        my $r = ci->UserGroup->search_ci( mid => $p->{id_group} );
        if ($r) {
            my $usergroup;
            my $new_usergroup;
            my $row;
            my $cont = 2;

            $new_usergroup = "Duplicate of " . $r->name;
            $row = ci->UserGroup->find( { groupname => $new_usergroup, active => mdb->true } )->next;

            while ($row) {
                $new_usergroup = "Duplicate of " . $r->name . " " . $cont++;
                $row = ci->UserGroup->find( { groupname => $new_usergroup, active => mdb->true } )->next;
            }

            if ( !$row ) {
                my $usergroup_mid;
                my $ci_data = {
                    name             => $new_usergroup,
                    bl               => '*',
                    active           => '1',
                    project_security => $r->project_security,
                };

                my $ci = ci->UserGroup->new(%$ci_data);
                $usergroup_mid = $ci->save;

                my @users = $r->users();
                $ci->set_users(@users);

                $c->stash->{json} = { msg => _loc("UserGroup duplicated"), success => \1, user_id => $usergroup_mid };
            }
        } else {
            $c->stash->{json} = { success => \0, msg => _loc("Missing id_group or group not found") };
        }
    }
    catch {
        $c->stash->{json} = { success => \0, msg => _loc( 'Error duplicating userGroup: %1', shift ) };
    };

    $c->forward('View::JSON');

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
