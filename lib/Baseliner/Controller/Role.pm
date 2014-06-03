package Baseliner::Controller::Role;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use JSON::XS;
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
        my $r = mdb->role->find({ id=>0+$id })->next;
        for my $user_action (@{$r->{actions}}){
            eval { # it may fail for keys that are not in the registry
                my $action = $c->model('Registry')->get( $user_action->{action} );
                push @actions, { action=>$user_action->{action}, description=>$action->name, bl=>$user_action->{bl} };
            };
        }
        if( $r ) {
            $c->stash->{json} = { data=>[{  id=>$r->{id}, name=>$r->{role}, description=>$r->{description}, mailbox=>$r->{mailbox}, actions=>[ @actions ] }]  };
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
    $rs->skip($start);
    $rs->limit($limit);
    $rs->sort($sort ? { $sort => $dir } : { role => 1 });
    $cnt = mdb->role->count();

    my @rows;
    while( my $r = $rs->next ) {
        my $rs_actions = $r->{actions};
        my @actions;
        for my $act (@$rs_actions){
            try {
                my $action = $c->model('Registry')->get( $act->{action} );
                my $str = { name=>$action->name,  key=>$act->{action} };
                $str->{bl} = $act->{bl} if $act->{bl} ne '*';
                push @actions, $str;
            } catch {
                push @actions, { name=>$act->{action}, key=>'' };
            };
        }
        my $actions_txt = \@actions;
        next if $query
            && !query_array($query, $r->{role}, $r->{description}, $r->{mailbox}, map { values %$_ } @actions );
        
        # if the query has a dot, filter actions
        if( defined $query && $query =~ /\./ ) {
            @actions = grep { $a = join ',', values %$_; $a =~ /$query/i } @actions;
        }

        push @rows,
          {
            id          => $r->{id},
            role        => $r->{role},
            actions     => $actions_txt,
            description => $r->{description},
            mailbox => $r->{mailbox}
          }
    }
    $c->stash->{json} = { data => \@rows, totalCount => $cnt };     
    $c->forward('View::JSON');
}

sub action_tree_old : Local {
    my ( $self, $c ) = @_;
    my @actions = $c->model('Actions')->list;
    my %tree;
    foreach my $a ( @actions ) {
        my $key = $a->{key};
        ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
        push @{ $tree{ $folder } }, { id=>$a->{key}, text=>_loc_decoded( $a->{name} ), leaf=>\1 }; 
    }
    my @tree_final = map { { id=>$_, text=>$_, leaf=>\0, children=>$tree{$_} } } sort keys %tree;
    $c->stash->{json} = \@tree_final;
    $c->forward("View::JSON");
}

sub action_tree : Local {
    my ( $self, $c ) = @_;
    my $cached = Baseliner->cache_get( "roles:actions:");

    my @actions;

    if ( $cached ) {
        _log "LO ENCUENTRO";
        @actions = _array $cached;
    } else {
        _log "NO LO ENCUENTRO";
        @actions = $c->model('Actions')->list;
        Baseliner->cache_set( "roles:actions:", \@actions);        
    }

    my @tree_final;
    my %tree;

    my $cached_tree = Baseliner->cache_get( "roles:tree:");

    if ( $cached_tree ) {
        @tree_final = _array $cached_tree;
    } else {

        my $children_of;

        $children_of = sub {
            my ( $parent, @actions ) = @_;
            my $children;

            for my $action ( @actions ) {

                my $key = $action->{key};
                next if $key !~ /^$parent\.(.*)/; # skip if not children

                my @tokens = split /\./, $1; # split in tokens
                my $name = shift @tokens;
                my $id = $parent.".".$name; # add myself to parent
                
                next if $tree{$id}; # skip if already in tree
                $tree{$id}=1; # declarate myself as in tree

                if ( @tokens ) { # not a leaf
                    push @$children, { id=>$id, text => $name, leaf=>\0, children=> $children_of->($id, @actions) };
                } else { # a leaf
                    push @$children, { id=>$id, text => sprintf( "%s (%s)",_loc_decoded( $action->{name} ), $id) , leaf=>\1 };
                }

            }
            return [ sort { $a->{id} cmp $b->{id} } _array $children ];
        };

        foreach my $key ( sort map { $_->{key} } @actions ) {
            ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
            next if $tree{$folder};
            $tree{$folder}=1;
            
            if ( $folder ne $key ) {
                my $children = $children_of->( $folder, @actions );
                push @tree_final, { id=>$folder, text=>$folder, leaf=>\0, children => $children };
            } else {
                push @tree_final, { id=>$key, text => $key, leaf=>\1 };
            }
        };
        Baseliner->cache_set( "roles:tree:", \@tree_final);
    };
    $c->stash->{json} = \@tree_final;
    $c->forward("View::JSON");
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        my $role_actions = decode_json(encode('UTF-8', $p->{role_actions}));
        my $row = {  role=>$p->{name}, description=>$p->{description}, mailbox=>$p->{mailbox}, actions=>$role_actions };
        $row->{id} = $p->{id}+0 if $p->{id} >= 0;
        if ($p->{id} < 0){
            $row->{id} = mdb->seq('role')+0;
            mdb->role->insert($row);
        }else{
            mdb->role->update( { id=>$row->{id}+0 }, $row );
        }
        Baseliner->cache_remove(":role:actions:$p->{id}:") if $p->{id};
        Baseliner->cache_remove(':role:ids:');
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error modifying the role ").$@  };
    } else { 
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    $c->forward('View::JSON');  
}

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        mdb->role->romove({ id=>$p->{id_role}+0 });
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
    } else { 
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    Baseliner->cache_remove(':role:ids:');
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
                if (grep { 0+$_==$id_duplicated_role } @$roles ){
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
    Baseliner->cache_remove(':role:ids:');
    $c->forward('View::JSON');  
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/role_grid.mas';
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
        my $role_id = $p->{id_role}+0;
        my @role_users = ci->user->find({"project_security.$role_id"=>{'$exists'=>mdb->true}})->all;
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
    $c->forward('View::JSON');  
}

sub roleprojects : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $role_id = $p->{id_role}+0;
    try {
        my @role_users = ci->user->find({"project_security.$role_id"=>{'$exists'=>mdb->true}})->all;
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
    $c->forward('View::JSON');  
}

1;
