package Baseliner::Controller::Role;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use Try::Tiny;
use utf8;
use Encode;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.admin.role' => { name=>'Admin Roles' };
register 'menu.admin.role' => { label => 'Roles', url_comp=>'/role/grid', actions=>['action.admin.role'], title=>'Roles', index=>81,
    icon=>'/static/images/icons/users.gif' };
register 'menu.admin.user_role_separator' => { separator=>1, index=>85 };

sub role_detail_json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my @actions;
    if( defined $id ) {
        my $r = mdb->role->find_one({ id=>"$id" });
        for my $user_action (@{$r->{actions}}){
            eval { # it may fail for keys that are not in the registry
                my $action = $c->model('Registry')->get( $user_action->{action} );
                push @actions, { action=>$user_action->{action}, description=>$action->name, bl=>$user_action->{bl} };
            };
        }
        if( $r ) {
            $c->stash->{json} = { data=>[{  id=>$r->{id}, name=>$r->{role}, description=>$r->{description}, mailbox=>$r->{mailbox}, dashboards=>$r->{dashboards}, actions=>[ @actions ] }]  };
            $c->forward('View::JSON');
        }
    }
}

sub json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    
    $sort ||= 'role';
    $dir ||= 'asc';
    if($dir =~ /asc/i){
        $dir = 1;
    }else{
        $dir = -1;
    }

    $start ||= 0;
    $limit ||= 60;
    my $rs = mdb->role->find();
    $cnt = $rs->count();
    $rs->skip($start);
    $rs->limit($limit);
    $rs->sort($sort ? { $sort => $dir } : { role => 1 });

    my @rows;
    my $reg = $c->registry;
    while( my $r = $rs->next ) {
        my $rs_actions = $r->{actions};
        my @actions;
        my @invalid_actions;
        for my $act (@$rs_actions){
            my $key = $act->{action};
            my $bl = $act->{bl};
            try {
                my $action = $reg->get( $key );
                my $str = { name=>$action->name,  key=>$key };
                $str->{bl} = $bl if $bl ne '*';
                push @actions, $str;
            } catch {
                #my $err = shift;
                #_warn "Invalid Action in Role $$r{id}: $key: $err";
                push @invalid_actions, { name=>$key, key=>'' };
            };
        }
        my $actions_txt = \@actions;
        next if $query
            && !query_array($query, $r->{role}, $r->{description}, $r->{mailbox}, map { values %$_ } @actions, @invalid_actions );
        
        # if the query has a dot, filter actions
        if( defined $query && $query =~ /\./ ) {
            @actions = grep { $a = join ',', values %$_; $a =~ /$query/i } @actions;
        }

        push @rows,
          {
            id          => $r->{id},
            role        => $r->{role},
            actions     => $actions_txt,
            invalid_actions => \@invalid_actions,
            description => $r->{description},
            mailbox => $r->{mailbox},
            dashboards => $r->{dashboards}
          }
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
    my $cached = cache->get( "roles:actions:");

    my @actions;

    if ( $cached ) {
        @actions = _array $cached;
    } else {
        @actions = $c->model('Actions')->list;
        cache->set( "roles:actions:", \@actions);        
    }
    
    if( length( my $query = $c->req->params->{query}) ) {
        my @qrs = map { qr/\Q$_\E/i } split /\s+/, $query;
        my @tree_query;
        foreach my $act ( sort { $a->{key} cmp $b->{key} } @actions ) {
            #( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
            my $key = $act->{key};
            ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
            my $name = $act->{name};
            my $txt = "$key,$name";
            if( List::MoreUtils::all(sub{ $txt =~ $_ }, @qrs) ) {
                #_debug( $act );
                push @tree_query, { id=>$key, text =>( $name ne $key ? "$name" : "$key" ), icon=>'/static/images/icons/lock_small.png', leaf=>\1 };
            }
        }
        $c->stash->{json} = \@tree_query;
        $c->forward("View::JSON");
        return;
    }
    my @tree_final;
    my %tree;

    my $cached_tree = cache->get( "roles:tree:");

    if ( $cached_tree ) {
        @tree_final = _array $cached_tree;
    } else {
        my %folders;
        for my $act ( sort { $a->{key} cmp $b->{key} } @actions ) {
            my $key = $$act{key};
            my @kp = split /\./, $key;
            my $perm = pop @kp;
            my $folder = pop @kp;
            my $parent = join '.',@kp;
            my $fkey = $parent ? "$parent.$folder" : $folder; 
            $folders{$fkey} //= { key=>$fkey, text=>$folder, leaf=>\0, icon=>'/static/images/icons/action_folder.gif', parents=>\@kp };
            my $node = { text=>$$act{name}, id=>$key, key=>$key, icon=>'/static/images/icons/lock_small.png', leaf=>\1 };
            push @{ $folders{$fkey}{children} }, $node;
        }
        # now create intermediate folders
        my $push_parent;
        $push_parent = sub{
            my ($fkey) = @_;
            my $fnode = $folders{$fkey};
            my $parents = delete $$fnode{parents};
            if( $parents && @$parents ) {
                my $pn = pop @$parents;
                my $parent = join '.', @$parents, $pn;
                #say "$fkey INTO $parent";
                $folders{$parent} //= { key=>$parent, text=>$pn, icon=>'/static/images/icons/action_folder.gif', leaf=>\0, parents=>$parents };
                push @{ $folders{$parent}{children} }, $fnode;
                $push_parent->($parent);
            }
        };
        $push_parent->($_) for sort keys %folders;
        @tree_final = @{ $folders{'action'}{children} };
        cache->set( "roles:tree:", \@tree_final);
    };
    $c->stash->{json} = \@tree_final;
    $c->forward("View::JSON");
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $row;
    eval {
        my $role_actions = _decode_json(encode('UTF-8', $p->{role_actions}));
        $row = {  role=>$p->{name}, description=>$p->{description}, mailbox=>$p->{mailbox},dashboards=>$p->{dashboards}, actions=>$role_actions };
        $row->{id} = "$p->{id}" if $p->{id} >= 0;
        if ($p->{id} < 0){
            $row->{id} = ''.mdb->seq('role');
            mdb->role->insert($row);
        }else{
            mdb->role->update( { id=>"$row->{id}" }, $row );
        }
        cache->remove(":role:actions:$p->{id}:") if $p->{id};
        cache->remove(':role:ids:');
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error modifying the role ").$@};
    } else { 
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ), id=> $row->{id}  };
    }
    cache->remove({ d=>'security' });
    cache->remove({ d=>"topic:meta" });
    $c->forward('View::JSON');  
}

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
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
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    cache->remove(':role:ids:');
    cache->remove({ d=>'security' });
    cache->remove({ d=>"topic:meta" });
    $c->forward('View::JSON');  
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        my $r = mdb->role->find( { id=>$p->{id_role} } )->next;
        if( $r ) {
            delete $r->{_id};
            my $id_duplicated_role = $r->{id};
            $r->{role} = $r->{role} . "-" . $r->{id};
            $r->{id} = mdb->seq('role');
            mdb->role->insert($r);
            my $dashboards = mdb->dashboard->find()->all;
            foreach my $dashboard ($dashboards){
                my $roles = $dashboard->{role};
                if (grep { $_==$id_duplicated_role } @$roles ){
                    push $roles, $r->{id};
                    mdb->dashboard->update({ _id=>$dashboard->{_id} }, $dashboard);        
                }    
            }
            my @rs_workflows = mdb->workflow->find();
            foreach my $workflow (@rs_workflows){
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

1;
