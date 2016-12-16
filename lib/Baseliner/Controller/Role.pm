package Baseliner::Controller::Role;
use Moose;
BEGIN {  extends 'Catalyst::Controller' }

use Try::Tiny;
use Encode;
use 5.010;
use experimental 'autoderef';
use Hash::Diff ();
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use Baseliner::Model::Permissions;
use BaselinerX::Type::Model::Actions;

with 'Baseliner::Role::ControllerValidator';

register 'action.admin.role' => { name => _locl('Admin Roles') };
register 'menu.admin.role' => {
    label    => _locl('Roles'),
    title    => _locl('Roles'),
    url_comp => '/role/grid',
    actions  => ['action.admin.role'],
    index    => 81,
    icon     => Util->icon_path('role')
};
register 'menu.admin.user_role_separator' => { separator => 1, index => 85 };

sub role_detail_json : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $id = $p->{id};

    my $data = [];

    if ( defined $id ) {
        my $role = mdb->role->find_one( { id => "$id" } );

        if ($role) {
            my @actions;
            for my $user_action ( @{ $role->{actions} } ) {
                eval {    # it may fail for keys that are not in the registry
                    my $action = $c->model('Registry')->get( $user_action->{action} );

                    push @actions,
                      {
                        action      => $user_action->{action},
                        description => $action->name,
                        bounds      => $user_action->{bounds},
                        bounds_available => ($action->bounds && @{ $action->bounds}) ? \1 : \0,
                      };
                };
            }

            $data = [
                {
                    id          => $role->{id},
                    name        => $role->{role},
                    description => $role->{description},
                    mailbox     => $role->{mailbox},
                    dashboards  => $role->{dashboards},
                    actions     => [@actions]
                }
            ];
        }
    }

    $c->stash->{json} = { data => $data };
    $c->forward('View::JSON');
}

sub action_info : Local {
    my ($self, $c) = @_;

    my $p = $c->request->parameters;

    my $action         = $p->{action};
    my $current_bounds = _decode_json_safe($p->{current_bounds}, []);

    my $permissions = Baseliner::Model::Permissions->new;
    my $action_info = $permissions->action_info($action);

    if ($action_info) {
        my $bounds = [ map { { key => $_->{key}, name => $_->{name}, depends => $_->{depends} } } @{ $action_info->bounds } ];

        $permissions->map_action_bounds($action, $current_bounds);

        my $info = {
            action => $action,
            bounds => $bounds,
            values => $current_bounds
        };

        $c->stash->{json} = { success => \1, info => $info };
    }
    else {
        $c->stash->{json} = { success => \0 };
    }

    $c->forward('View::JSON');
}

sub bounds : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $action = $p->{action};
    my $bound  = $p->{bound};
    my $filter = _decode_json_safe( $p->{filter} );

    my $permissions = Baseliner::Model::Permissions->new;

    my $data = $permissions->action_bounds_available($action, $bound, %$filter);

    unshift @$data, { id => '', title => _loc('Any') };

    $c->stash->{json} = { data => $data, totalCount => scalar(@$data) };
    $c->forward('View::JSON');
}

sub json : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;
    my ( $start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort  ||= 'role';
    $dir   ||= 'asc';
    $start ||= 0;

    if ( $dir =~ /asc/i ) {
        $dir = 1;
    }
    else {
        $dir = -1;
    }

    my $where = $query ? mdb->query_build(query => $query, fields=>[qw(role description mailbox id)]) : {};
    my $rs = mdb->role->find($where);
    $cnt = $rs->count;
    $rs->skip($start);

    if ( $limit && $limit != -1 ) {
        $rs->limit($limit);
    }
    $rs->sort( $sort ? { $sort => $dir } : { role => 1 } );

    my @rows;
    while ( my $r = $rs->next ) {
        push @rows,
            {
            id          => $r->{id},
            role        => $r->{role},
            description => $r->{description},
            mailbox     => $r->{mailbox},
            dashboards  => $r->{dashboards}
            };
    }

    $c->stash->{json} = { data => \@rows, totalCount => $cnt };
    $c->forward('View::JSON');
}

sub cleanup : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $id = $p->{id} || _fail 'Missing role id';
    my $actions = $p->{actions} || _fail 'Missing actions';
    my @keys = map { $$_{key} || $$_{name} } _array($actions);
    _debug( \@keys );
    mdb->role->update({ id=>"$id" },{ '$pull'=>{ actions=>{ action=>mdb->in(@keys) } } });
    $c->stash->{json} = { success=>\1, msg=>_loc('Deleted') };
    $c->forward('View::JSON');
}

sub action_tree_old : Local {
    my ( $self, $c ) = @_;
    my @actions = $c->model('Actions')->list;
    my %tree;
    foreach my $a ( @actions ) {
        my $key = $a->{key};
        ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
        push @{ $tree{ $folder } }, { id=>$a->{key}, text=>Util->_loc_decoded( $a->{name} ), leaf=>\1 };
    }
    my @tree_final = map { { id=>$_, text=>$_, leaf=>\0, children=>$tree{$_} } } sort keys %tree;
    $c->stash->{json} = \@tree_final;
    $c->forward("View::JSON");
}

sub action_tree : Local {
    my ( $self, $c ) = @_;

    my $params = $c->req->parameters;

    my $id_role = $params->{id_role} // '';
    my $role;

    if ( $id_role && !( $role = mdb->role->find_one( { id => $id_role } ) ) ) {
        $c->stash->{json} = { success => \0 };
        $c->forward("View::JSON");
        return;
    }

    my $permissions = Baseliner::Model::Permissions->new;

    my $model_actions = $self->_build_model_actions;
    my @actions = $model_actions->list;

    if ( length( my $query = $c->req->params->{query} ) ) {
        my @qrs = map { qr/\Q$_\E/i } split /\s+/, $query;
        my @tree_query;
        foreach my $act ( sort { $a->key cmp $b->key } @actions ) {

            #( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
            my $key = $act->key;
            ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
            my $name = $act->name;
            my $txt  = "$key,$name";
            if ( List::MoreUtils::all( sub { $txt =~ $_ }, @qrs ) ) {
                my $icon = '/static/images/icons/action.svg';
                if ( $role && $permissions->role_has_action( $role, $key ) ) {
                    $icon = '/static/images/icons/checkbox.svg';
                }

                push @tree_query,
                  {
                    id   => $key,
                    text => _loc( $name ne $key ? "$name" : "$key" ),
                    bounds_available => ($act->bounds && @{ $act->bounds}) ? \1 : \0,
                    icon => $icon,
                    leaf => \1
                  };
            }
        }
        $c->stash->{json} = \@tree_query;
        $c->forward("View::JSON");
        return;
    }

    my $cached_tree = cache->get("roles:tree:$id_role:");

    my @tree_final;
    if ($cached_tree) {
        @tree_final = _array $cached_tree;
    }
    else {
        my %folders;
        for my $act ( sort { $a->key cmp $b->key } @actions ) {
            my $key    = $act->key;
            my @kp     = split /\./, $key;
            my $perm   = pop @kp;
            my $folder = pop @kp;
            my $parent = join '.', @kp;
            my $fkey   = $parent ? "$parent.$folder" : $folder;

            $folders{$fkey} //= {
                key       => $fkey,
                text      => _loc($folder),
                leaf      => \0,
                draggable => \0,
                icon      => '/static/images/icons/action_folder.svg',
                parents   => \@kp
            };

            my $icon = '/static/images/icons/action.svg';

            my $text = $act->{name};
            if ( $role && $permissions->role_has_action( $role, $key) ) {
                if (!$folders{$fkey}->{_modified}) {
                    $folders{$fkey}->{_modified}++;
                    $folders{$fkey}->{icon} = '/static/images/icons/file.svg';
                }

                $icon = '/static/images/icons/checkbox.svg';
            }

            my $node = {
                text             => _loc($text),
                id               => $key,
                key              => $key,
                bounds_available => ( $act->bounds && @{ $act->bounds } ) ? \1 : \0,
                icon             => $icon,
                leaf             => \1
            };

            push @{ $folders{$fkey}{children} }, $node;
        }

        # now create intermediate folders
        my $push_parent;
        $push_parent = sub {
            my ($fkey)  = @_;

            my $fnode   = $folders{$fkey};
            my $parents = delete $$fnode{parents};
            if ( $parents && @$parents ) {
                my $parent_name = pop @$parents;
                my $parent = join '.', @$parents, $parent_name;

                $folders{$parent} //= {
                    key       => $parent,
                    text      => _loc($parent_name),
                    icon      => '/static/images/icons/action_folder.svg',
                    draggable => \0,
                    leaf      => \0,
                    parents   => $parents
                };

                push @{ $folders{$parent}{children} }, $fnode;
                $push_parent->($parent);
            }
            else {
                if ( !$fnode->{_modified} && $fnode->{children} && grep { $_->{_modified} } @{ $fnode->{children} } ) {
                    $fnode->{_modified}++;
                    $fnode->{icon} = '/static/images/icons/file.svg';
                }
            }
        };

        $push_parent->($_) for sort keys %folders;

        @tree_final = @{ $folders{'action'}{children} || [] };

        cache->set( "roles:tree:$id_role:", \@tree_final );
    }

    $c->stash->{json} = \@tree_final;
    $c->forward("View::JSON");
}

sub update : Local {
    my ( $self, $c ) = @_;

    return
      unless my $p = $self->validate_params(
        $c,
        id          => { isa => 'Str',           default => undef },
        name        => { isa => 'Str' },
        description => { isa => 'Str',           default => undef },
        mailbox     => { isa => 'Str',           default => undef },
        dashboards  => { isa => 'StrOrArrayRef', default => [] },
        role_actions => { isa => 'ArrayJSON', default => [], default_on_error => 1 },
      );

    my $name = $p->{name};
    my $id   = $p->{id};

    if ( mdb->role->find_one( { role => $name, $id ? ( id => { '$ne' => $id } ) : () } ) ) {
        $c->stash->{json} = {
            success => \0,
            msg     => _loc('Validation failed'),
            errors  => { name => _loc('Role with this name already exists') }
        };
        $c->forward('View::JSON');
        return;
    }

    my $row = {
        id          => $id,
        role        => $p->{name},
        description => $p->{description},
        mailbox     => $p->{mailbox},
        dashboards  => $p->{dashboards},
        actions     => []
    };

    foreach my $action ( _array $p->{role_actions} ) {
        my $key = $action->{action};
        my @bounds = _array $action->{bounds};

        foreach my $bound (@bounds) {
            if (delete $bound->{_deny}) {
                $bound->{_deny} = 1;
            }

            foreach my $key (keys %$bound) {
                next if $key eq '_deny';

                delete $bound->{$key} if $bound->{$key} eq '' || $key =~ m/^_/;
            }
        }

        my @bounds_uniq;
        for (my $i = 0; $i < @bounds; $i++) {
            my $current = $bounds[$i];

            my $uniq = 1;
            for (my $j = $i + 1; $j < @bounds; $j++) {
                my $diff = Hash::Diff::diff($current, $bounds[$j]);
                if (!%$diff) {
                    $uniq = 0;
                    last;
                }
            }

            next unless $uniq;

            push @bounds_uniq, $current;
        }

        push @bounds_uniq, {} unless @bounds_uniq;

        push @{ $row->{actions} }, {
            action => $key,
            bounds => \@bounds_uniq
        };
    }

    if ( $id && !mdb->role->find_one( { id => "$id" }, { _id => 1 } ) ) {
        $c->stash->{json} = { success => \0, msg => _loc( 'Unknown role `%1`', $id ) };
        $c->forward('View::JSON');
        return;
    }

    if ( !$id ) {
        $id = $row->{id} = '' . mdb->seq('role');
        mdb->role->insert($row);

        $c->stash->{json} = { success => \1, id => $id, msg => _loc('Role created') };
    }
    else {
        mdb->role->update( { id => "$id" }, $row );
        $c->stash->{json} = { success => \1, id => $id, msg => _loc('Role modified') };
    }

    cache->remove("roles:tree:$id:")    if $id;
    cache->remove(":role:actions:$id:") if $id;
    cache->remove(':role:ids:');
    cache->remove( { d => 'security' } );
    cache->remove( { d => "topic:meta" } );

    $c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    if ($p->{delete_confirm} && $p->{delete_confirm} eq '1'){
        eval {
            mdb->role->remove({ id=>"$p->{id_role}" });

            #borramos roles del project_security de los usuarios que tengan ese rol
            my @users = ci->user->find({"project_security.$p->{id_role}"=>{'$exists'=>1}})->fields({project_security=>1,mid=>1, _id=>0})->all;
            foreach my $user (@users){
                #quitar de project security del usuario ese rol que es $p->{id_role}
                my $project_security = $user->{project_security};
                delete $project_security->{$p->{id_role}};
                my $ci = ci->new($user->{mid});
                $ci->update(project_security=>$project_security);
            }
        };
        if( $@ ) {
            warn $@;
            $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
        } else {
            $c->stash->{json} = { success => \1 };
        }
        cache->remove("roles:tree:$p->{id_role}:");
        cache->remove(':role:ids:');
        cache->remove({ d=>'security' });
        cache->remove({ d=>"topic:meta" });
        $c->forward('View::JSON');
    }
    else{
        my @role_users =
          ci->user->find( { "project_security.$p->{id_role}" => { '$exists' => 1 } } )->fields( { name => 1 } )
          ->sort( { name => 1 } )->all;

        my @user_names = map { $_->{name} } @role_users;

        $c->stash->{json} = { success => \1, users => \@user_names };
        $c->forward('View::JSON');
    }
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        my $r = mdb->role->find( { id=>$p->{id_role} } )->next;
        if( $r ) {
            delete $r->{_id};
            my $id_duplicated_role = $r->{id};
            my $new_role_title = "Duplicate of " . $r->{role};
            my $num_of_duplicates = 2;
            $r->{id} = mdb->seq('role');
            while (mdb->role->find( { role => $new_role_title} )->next) {
                $new_role_title = "Duplicate of " . $r->{role} . " " . $num_of_duplicates++;
            }
            $r->{role}  = $new_role_title;
            mdb->role->insert($r);
            my @dashboards = mdb->dashboard->find()->all;
            foreach my $dashboard (@dashboards){
                my $roles = $dashboard->{role};
                if (grep { $_==$id_duplicated_role } @$roles ){
                    push $roles, $r->{id};
                    mdb->dashboard->update({ _id=>$dashboard->{_id} }, $dashboard);
                }
            }
            my @workflows = mdb->workflow->find()->all;
            foreach my $workflow (@workflows){
                delete $workflow->{_id};
                $workflow->{id_role} = $r->{id};
                mdb->workflow->insert( $workflow );
            }
        }
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
    } else {
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    cache->remove(':role:ids:');
    $c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/role_grid.js';
}

sub all : Local {
    my ( $self, $c ) = @_;
    my @rs = mdb->role->find()->all;
    my @roles = map {
        $_->{role_name} = "$_->{description} ($_->{role})";
        $_
    } @rs;
    $c->stash->{json} = { data=>\@roles, totalCount=>scalar @roles };
    $c->forward('View::JSON');
}


sub roleusers : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my @data;
        my $role_id = ''.$p->{id_role};
        my @role_users = ci->user->find({"project_security.$role_id"=>{'$exists'=>1}})->all;
        foreach my $user (@role_users){
            my @project_types = keys $user->{project_security}->{$role_id};
            my @user_projects;
            foreach my $project_type (@project_types){
                push @user_projects, @{$user->{project_security}->{$role_id}->{$project_type}};
            }
            my @projects;
            my @colls = map { Util->to_base_class($_) } packages_that_do( 'Baseliner::Role::CI::Project' );
            foreach my $col (@colls){
                push @projects, ci->$col->find({ mid=>{'$in'=>\@user_projects} })->all;
            }
            @projects = sort { $a->{name} cmp $b->{name} } @projects;
            push @data, { user=>$user->{username}, projects=>join ', ', map { $_->{name}} @projects };
        }
        @data =  sort { $a->{user} cmp $b->{user} } @data;
        $c->stash->{json} = { success => \1, data=>\@data, totalCount=>scalar @data };

    } catch {
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
    };
    cache->remove({ d=>'security' });
    cache->remove({ d=>"topic:meta" });
    $c->forward('View::JSON');
}

sub roleprojects : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $role_id = ''.$p->{id_role};
    try {
        my @role_users = ci->user->find({"project_security.$role_id"=>{'$exists'=>1}})->all;
        my %projects_users;
        my @data;
        foreach my $user (@role_users){
            my @project_types = keys $user->{project_security}->{$role_id};
            my @user_projects;
            foreach my $project_type (@project_types){
                push @user_projects, @{$user->{project_security}->{$role_id}->{$project_type}};
            }
            my @projects;
            my @colls = map { Util->to_base_class($_) } packages_that_do( 'Baseliner::Role::CI::Project' );
            foreach my $col (@colls){
                push @projects, ci->$col->find({ mid=>mdb->in(@user_projects) })->all;
            }
            map {
                if(exists $projects_users{$_->{name}}){
                    push $projects_users{$_->{name}}, $user->{username};
                } else {
                    $projects_users{$_->{name}} = [$user->{username}];
                }
            } @projects;
        }
        foreach my $elem (keys %projects_users){
            my @ord = _unique _array( $projects_users{ $elem } );
            @ord = sort @ord;
            my $users_txt = join ', ', @ord;
            push @data, {project=>$elem, users=>$users_txt};
        }
        @data = sort { $a->{project} cmp $b->{project} } @data;
        $c->stash->{json} = { success => \1, data=>\@data, totalCount=>scalar @data };
    } catch {
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
    };
    cache->remove({ d=>'security' });
    cache->remove({ d=>"topic:meta" });
    $c->forward('View::JSON');
}

sub actions : Local {
    my ( $self, $c ) = @_;

    my @actions;
    my @invalid_actions;
    my $p            = $c->req->params;
    my $role         = mdb->role->find_one( { id => $p->{role_id} } );
    my $role_actions = $role->{actions};

    for my $act (@$role_actions) {
        my $key = $act->{action};
        try {
            my $action = Baseliner::Core::Registry->get($key);
            my $str = { name => $action->name, key => $key };
            push @actions, $str;
        }
        catch {
            push @invalid_actions, { name => $key, key => '' };
        };
    }

    $c->stash->{json} = { actions => \@actions, invalid_actions => \@invalid_actions };
    $c->forward('View::JSON');
}

sub _build_model_actions {
    my $self = shift;

    return BaselinerX::Type::Model::Actions->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
