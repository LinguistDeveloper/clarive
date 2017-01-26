package Baseliner::Controller::UserGroup;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;

use experimental 'autoderef', 'switch';

with 'Baseliner::Role::ControllerValidator';

register 'action.admin.user_groups' => { name => 'User groups Admin', };

register 'menu.admin.user_groups' => {
    label    => _loc('User Groups'),
    url_comp => '/usergroup/grid',
    actions  => ['action.admin.user_groups'],
    title    => 'User groups',
    index    => 81,
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

sub update : Local : Does('ACL') : ACL('action.admin.user_groups') {
    my ( $self, $c ) = @_;

    return
      unless my $validated_params = $self->validate_params(
        $c,
        id        => { isa => 'Str',               default => '' },
        groupname => { isa => 'Str' },
        users     => { isa => 'Str|ArrayRef[Str]', default => [] }
      );

    my $mid = delete $validated_params->{id};
    $validated_params->{name} = $validated_params->{groupname};

    my $exists = ci->UserGroup->find_one(
        {
            groupname => $validated_params->{groupname},
            $mid ? ( mid => { '$ne' => $mid } ) : ()
        }
    );

    if ($exists) {
        $c->stash->{json} = {
            success => \0,
            msg     => _loc('Validation failed'),
            errors  => { groupname => _loc('User group name already exists') }
        };
    }
    else {
        try {
            my $usergroup;
            if ($mid) {
                try { $usergroup = ci->new($mid) };
                die 'User group not found' unless $usergroup;

                $usergroup->update($validated_params);
            }
            else {
                $usergroup = ci->UserGroup->new( bl => '*', active => '1', %$validated_params );
            }

            $usergroup->save;
            $usergroup->set_users( _array $validated_params->{users} );

            $c->stash->{json} = { success => \1, msg => _loc('User group saved'), user_id => $usergroup->mid };
        }
        catch {
            my $error = shift;

            $c->stash->{json} = { success => \0, msg => _loc( 'Error saving user group' ) };
        };
    }

    $c->forward('View::JSON');

    return;
}

sub delete : Local : Does('ACL') : ACL('action.admin.user_groups') {
    my ($self, $c) = @_;

    my $p = $c->request->parameters;

    try {
        my $group_id = $p->{id} // _fail( _loc("Missing id") );
        my $group = ci->new($group_id);

        ci->delete($group_id);

        $c->stash->{json} = { success => \1, msg => _loc('User group deleted') };
    }
    catch {
        my $error = shift;

        $c->stash->{json} = { success => \0, msg => _loc( 'Error deleting User group: %1', $error ) };
    };

    $c->forward('View::JSON');

    return;
}

sub roles_projects : Local : Does('ACL') : ACL('action.admin.user_groups') {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $id_user_group = $p->{id};

    my $usergroup = ci->UserGroup->search_ci( mid => "$id_user_group" );
    die 'usergroup not found' unless $usergroup;

    my @rows;
    foreach my $row ( @{ $usergroup->roles_projects } ) {
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

sub toggle_roles_projects : Local : Does('ACL') : ACL('action.admin.user_groups') {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $action           = $p->{action};
    my $id_group         = $p->{id};
    my @projects_checked = _unique _array $p->{projects_checked};
    my @roles_checked    = _unique _array $p->{roles_checked};

    my $usergroup = ci->UserGroup->search_ci( mid => "$id_group" );
    die 'usergroup not found' unless $usergroup;

    $usergroup->toggle_roles_projects(
        action   => $action,
        projects => \@projects_checked,
        roles    => \@roles_checked
    );

    # TODO cache

    $c->stash->{json} = { success => \1, msg => 'ok' };
    $c->forward('View::JSON');

    return;
}

sub delete_roles : Local : Does('ACL') : ACL('action.admin.user_groups') {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $action        = $p->{action};
    my $id_group      = $p->{id};
    my @roles_checked = _unique _array $p->{roles_checked};

    my $usergroup = ci->UserGroup->search_ci( mid => "$id_group" );
    die 'usergroup not found' unless $usergroup;

    $usergroup->delete_roles( roles => \@roles_checked );

    # TODO cache

    $c->stash->{json} = { success => \1, msg => 'ok' };
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

sub duplicate : Local : Does('ACL') : ACL('action.admin.user_groups') {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    try {
        my $usergroup = ci->UserGroup->search_ci(mid => $p->{id_group});
        die 'User group not found' unless $usergroup;

        my $new_groupname_pattern = sprintf 'Duplicate of %s', $usergroup->groupname;
        my $new_groupname = $new_groupname_pattern;

        for ( 1 .. 1000 ) {
            last unless ci->UserGroup->find_one( { groupname => $new_groupname } );
            die 'Infinite loop when duplicating usergroup' if $_ == 1000;

            $new_groupname = $new_groupname_pattern . ' ' . ($_ + 1);
        }

        my $ci_data = {
            bl               => '*',
            active           => '1',
            name             => $new_groupname,
            groupname        => $new_groupname,
            project_security => $usergroup->project_security,
        };

        my $ci = ci->UserGroup->new(%$ci_data);
        $ci->save;
        $ci->set_users( _array( $usergroup->users ) );

        $c->stash->{json} = { success => \1, msg => _loc('User group duplicated') };
    }
    catch {
        $c->stash->{json} = { success => \0, msg => _loc('Error duplicating user group') };
    };

    $c->forward('View::JSON');

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
