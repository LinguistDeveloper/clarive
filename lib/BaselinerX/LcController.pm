package BaselinerX::LcController;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = 'lifecycle';

sub tree_projects : Local {
    my ($self,$c) = @_;
    my @tree;
    my @project_ids = Baseliner->model('Permissions')->all_projects();
    my $rs = Baseliner->model('Baseliner::BaliProject')->search({ id=>\@project_ids, id_parent=>undef }, { order_by=>{ -asc => \'lower(name)' }  });
    while( my $r = $rs->next ) {
        push @tree, {
            text       => $r->name,
            url        => '/lifecycle/tree_project',
            data       => {
                id_project => $r->id,
                project    => $r->name,
            },
            icon       => '/static/images/icons/project.gif',
            leaf       => \0,
            expandable => \1
        };
    } 
    $c->stash->{json} = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree_project : Local {
    my ($self,$c) = @_;
    my @tree;

    my $project = $c->req->params->{project} ;
    my $id_project = $c->req->params->{id_project} ;

    # load project lifecycle configuration
    require BaselinerX::Lc;
    my $lc = BaselinerX::Lc->new->lc_for_project( $id_project );
    for my $node ( @$lc ) {
        next if exists $node->{active} && ! $node->{active};
        my $type = $node->{type};
        push @tree, {
            #id         => $node->{type} . ':' . $id,
            text       => _loc( $node->{node} ),
            url        => $node->{url} || '/lifecycle/changeset',
            icon       => $node->{icon},
            data       => {
                project    => $project,
                id_project => $id_project,
                bl         => $node->{bl},
                %{ $node->{data} || {} }
            },
            leaf       => \0,
            expandable => \0
        };
    }
    # get sub projects TODO make this recurse over the previous controller (or into a model)
    my $rs_prj = $c->model('Baseliner::BaliProject')->search({ id_parent=>$id_project });
    while( my $r = $rs_prj->next ) {
        my $name = $r->nature ? sprintf("%s (%s)", $r->name, $r->nature) : $r->name;
        push @tree, {
            text       => $name,
            url        => '/lifecycle/tree_project',
            data       => {
                id_project => $r->id,
                project    => $r->name,
            },
            icon       => '/static/images/icons/project.gif',
            leaf       => \0,
            expandable => \1
        };
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub changeset : Local {
    my ($self,$c) = @_;
    my @tree;

    my $p = $c->req->params;
    my $bl = $p->{bl} or _throw "Missing bl";
    my $project = $p->{project} or _throw 'missing project';
    my $id_project = $p->{id_project} or _throw 'missing project id';

    # get all the changes for this project + baseline
    my @cs;
    for my $provider ( packages_that_do 'Baseliner::Role::LC::Changes' ) {
        #push @cs, $class;
        my $prov = $provider->new( project=>$project );
        my @changes = $prov->list( project=>$project, bl=>$bl, id_project=>$id_project );
        _log _loc "---- provider $provider has %1 changesets", scalar @changes;
        push @cs, @changes
    }

    for my $cs ( @cs ) {
        my $menu = [];
        # get menu extensions (find packages that do)
        # get node menu
        ref $cs->node_menu and push @$menu, _array $cs->node_menu;
        push @tree, {
            #id         => $cs->node_id || rand(99999999999999999),
            url        => $cs->node_url,
            data       => $cs->node_data,
            parent_data => { id_project=>$id_project, bl=>$bl, project=>$project }, 
            menu       => $menu,
            icon       => $cs->icon,
            text       => $cs->text || $cs->name,
            leaf       => \0,
            expandable => \0
        };
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    if( $p->{favorites} eq 'true' ) {
        $c->forward( 'tree_favorites' );
    } elsif( $p->{show_workspaces} eq 'true' ) {
        $c->forward( 'tree_workspaces' );
    } else {
        $c->forward( 'tree_all' );
    }
    $c->forward( 'View::JSON' );
}

sub tree_all : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $query = $p->{query};
    my $node = $p->{node};

    if( $node eq '/' ) { 
        $c->forward('tree_projects');
    } else {
        my ( $type, $node ) = $node =~ /^(.*?)\:(.*)$/;
        if( $type ) {   # dispatch based on node "domain"
            $c->stash->{node} = $node;
            $c->forward( $type );
        } else {
            $c->forward('tree_lifecycle');
        }
    }

    #my @projects = Baseliner->model('Permissions')->user_projects_with_action(
        #username=>$c->username, action=>'' 
    #);
}

sub tree_favorites : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my @tree;
    my $favs = [ map { $_->kv } sort { $a->{ns} <=> $b->{ns} }
        kv->find( provider => 'lifecycle.favorites.' . $c->username )->all ];

    for my $node ( @$favs ) {
        ! $node->{menu} and delete $node->{menu}; # otherwise menus don't work
        push @tree, $node;
    }
    $c->stash->{json} = \@tree;
}

sub agent_ftp : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $dir = $p->{dir};

    # TODO : from user workspace repo
    my ($user, $pass, $host) = ( 'ICDMPA0', 'ENER12A', '192.168.107.2' );

    my @tree;

    my @path;
    push @path, $p->{curr} // '//' . $user;
    push @path, $dir if $dir && $dir ne '/';
    my $path = join '.', @path;
    _log "FTP path $path";

    use Net::FTP; 
    my $ftp=Net::FTP->new( $host );
    $ftp->login( $user, $pass );
    $ftp->cwd( $path ); 
    my $k = 0;
    for my $i ( $ftp->dir ) {
        next if $k++ == 0;
        my @f = split /[\s|\t]+/, $i;
        my ($vol, $unit, $ref, $ext, $used, $fmt, $lrecl, $blksz, $dsorg, $dsname ) = @f;
        _log "FFFFFFFFFFFFFF=" . join ',', @f;
        my $is_leaf = @f <= 5 ;
        my $text = @f < 2 ? $vol : ( @f <= 5 ? $f[4] : $dsname );

        my $node = {
            text => $text, 
            url => 'lifecycle/agent_ftp',
            data => { curr=>$path, dir=>$text },
            leaf => $is_leaf,
        };
        if( $is_leaf ) {
            $node->{data}{click} = {
                url      => '/comp/lifecycle/view_file.js',
                repo_dir => $node->{repo_dir},
                type     => 'comp',
                icon     => '/static/images/icons/page.gif',
                title    => $text,
            };
        }
        push @tree, $node;
    }
    $c->stash->{json} = \@tree;
    $c->forward( 'View::JSON' );
}

sub view_file : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $path = $p->{curr};
    my $remote = $p->{dir};
    my $local = _tmp_file;

    # TODO : from user workspace repo
    my ($user, $pass, $host) = ( 'ICDMPA0', 'ENER12A', '192.168.107.2' );

    use Net::FTP; 
    my $ftp=Net::FTP->new( $host );
    $ftp->login( $user, $pass );
    $ftp->cwd( $path );
    $ftp->get( $remote, $local );
    my $data = _file( $local )->slurp;
    unlink $local;
    $c->stash->{json} = { data=>$data };
    $c->forward( 'View::JSON' );
}

sub list_workspaces : Private {
    my ($self, %args) = @_;

    +{
        text => '192.168.107.2:ICDMPA0',
        leaf => \0,
        url  => '/lifecycle/agent_ftp',
        data => { dir=>'/' },
        icon => '/static/images/icons/workspace.png',
        expandable => \1,
    };
}

sub tree_workspaces : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my @tree;
    my $wks = [ map { $_->kv } sort { $a->{ns} <=> $b->{ns} }
        kv->find( provider => 'lifecycle.workspaces.' . $c->username )->all ];

    # XXX
    push @tree, $self->list_workspaces;

    for my $node ( @$wks ) {
        push @tree, $node;
    }
    $c->stash->{json} = \@tree;
}

sub favorite_add : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        # create the id for the user
        my $domain = 'lifecycle.favorites.' . $c->username;
        my $id = time . '.' .  int rand(9999);
        # delete empty ones
        $p->{$_} eq 'null' and delete $p->{$_} for qw/data menu/;
        # decode data structures
        defined $p->{$_} and $p->{$_} = _decode_json( $p->{$_} ) for qw/data menu/;
        $p->{id_favorite} = $id;
        kv->set( ns=>"$domain/$id", data=>$p );
        { success=>\1, msg=>_loc("Favorite added ok") }
    } catch {
        { success=>\0, msg=>shift() }
    };
    $c->forward( 'View::JSON' );
}

sub favorite_del : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        my $domain = 'lifecycle.favorites.' . $c->username;
        my $ns = "$domain/" . $p->{id} ;
        kv->delete( ns=>$ns ) if $p->{id};
        { success=>\1, msg=>_loc("Favorite removed ok") }
    } catch {
        { success=>\0, msg=>shift() }
    };
    $c->forward( 'View::JSON' );
}
1;
