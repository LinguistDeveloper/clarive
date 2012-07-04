package BaselinerX::LcController;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = 'lifecycle';

sub tree_topic_get_files : Local {
    my ($self,$c) = @_;
    my @tree;

    my $id_topic = $c->req->params->{id_topic} ;
    my $sw_get_files = $c->req->params->{sw_get_files} ;
    
    if ($sw_get_files){
        my $files = $c->model('Baseliner::BaliTopic')->find($id_topic)->files->search();
            while (my $file = $files->next){
                push @tree, {
                    text       => $file->filename . '(v' . $file->versionid . ')',
                    #url        => '/lifecycle/tree_topic_get_files',
                    data       => {
                       id_file => $file->mid,
                    },
                    #icon       => '/static/images/icons/project_small.png',
                    leaf       => \1,
                    expandable => \0
                };
        }
    }
    else{
        my $files = $c->model('Baseliner::BaliTopic')->find($id_topic)->files->search()->count;
        if ($files > 0){
            push @tree, {
               text       => _loc ('Files'),
               url        => '/lifecycle/tree_topic_get_files',
               data       => {
                  id_topic => $id_topic,
                  sw_get_files =>\1
               },
               icon       => '/static/images/icons/log_16.png',
               leaf       => \0,
               expandable => \1
           };           
        }
    }
    
    


    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}


sub tree_topics_project : Local {
    my ($self,$c) = @_;
    my @tree;

    my $project = $c->req->params->{project} ;
    my $id_project = $c->req->params->{id_project} ;
    my @topics_project = map {$_->{from_mid}} $c->model('Baseliner::BaliMasterRel')->search({ to_mid=>$id_project, collection =>'bali_topic' }, {join => ['master_from']})->hashref->all;
    my $topics = $c->model('Baseliner::BaliTopic')->search( {mid =>\@topics_project} );
    while ( my $topic = $topics->next ) {
        push @tree, {
            text       => $topic->categories->name . ' #' . $topic->mid,
            url        => '/lifecycle/tree_topic_get_files',
            data       => {
               id_topic => $topic->mid
            },
            icon       => '/static/images/icons/topic_lc.png',
            leaf       => \0,
            expandable => \1
        };
    }

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}


sub tree_projects : Local {
    my ( $self, $c ) = @_;
    my @tree;
    my @project_ids = Baseliner->model('Permissions')->all_projects();
    my $rs = Baseliner->model('Baseliner::BaliProject')->search({ mid=>\@project_ids, id_parent=>undef, active=>1 }, { order_by=>{ -asc => \'lower(name)' }  });
    while( my $r = $rs->next ) {
        push @tree, {
            text       => $r->name,
            url        => '/lifecycle/tree_project',
            data       => {
               id_project => $r->mid,
               project    => $r->name,
            },
            icon       => '/static/images/icons/project_small.png',
            leaf       => \0,
            expandable => \1
            };
    }
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
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
            text       => _loc( $node->{name} // $node->{node} ),  # name is official, node is deprecated
            url        => $node->{url} || '/lifecycle/changeset',
            icon       => $node->{icon},
            menu       => $node->{menu},
            data       => {
                project    => $project,
                id_project => $id_project,
                bl         => $node->{bl},
                state_name => $node->{name} // $node->{node},
                %{ $node->{data} || {} }
            },
            leaf       => \0,
            expandable => \0
        };
    }
    # get sub projects TODO make this recurse over the previous controller (or into a model)
    my $rs_prj = $c->model('Baseliner::BaliProject')->search({ id_parent=>$id_project, active=>1 });
    while( my $r = $rs_prj->next ) {
        my $name = $r->nature ? sprintf("%s (%s)", $r->name, $r->nature) : $r->name;
        push @tree, {
            text       => $name,
            url        => '/lifecycle/tree_project',
            data       => {
                id_project => $r->mid,
                project    => $r->name,
            },
            icon       => '/static/images/icons/project_small_child.gif',
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
    my $state_name = $p->{state_name} or _throw 'missing state name';
    my $id_project = $p->{id_project} or _throw 'missing project id';

    # provider-by-provider:
    # get all the changes for this project + baseline
    my @cs;
    for my $provider ( packages_that_do 'Baseliner::Role::LC::Changes' ) {
        #push @cs, $class;
        my $prov = $provider->new( project=>$project );
        my @changes = $prov->list( project=>$project, bl=>$bl, id_project=>$id_project, state_name=>$state_name );
        _log _loc "---- provider $provider has %1 changesets", scalar @changes;
        push @cs, @changes
    }

    # loop through the changeset objects (such as BaselinerX::GitChangeset)
    for my $cs ( @cs ) {
        my $menu = [];
        # get menu extensions (find packages that do)
        # get node menu
        ref $cs->node_menu and push @$menu, _array $cs->node_menu;
        push @tree, {
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

    ## add what's in this baseline 
    my @repos = BaselinerX::Lc->new->project_repos( project=>$project );
    # ( Girl::Repo->new( path=>"$path" ), $rev, $project );

    if ( $bl ne '*' ) {
        push @tree, {
            url  => '/lifecycle/repo',
            icon => '/static/images/icons/repo.gif',
            text => $_->{name},
            leaf => \1,
            data => {
                bl    => $bl,
                name  => $_->{name},
                repo_path  => $_->{path},
                click => {
                    url   => '/lifecycle/repo',
                    type  => 'comp',
                    icon  => '/static/images/icons/repo.gif',
                    title => "$_->{name} - $bl",
                }
              },
        } for @repos;
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub repo : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{ repo } = $p;
    $c->stash->{ template } = '/comp/lifecycle/repo.js' ;
}

sub repo_data : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $repo_path = $p->{repo_path};
    my $path = $p->{path} // '';
    length $path and $path = "$path/";
    my $g = Girl::Repo->new( path=>"$repo_path" );
    my @ls = $g->git->exec( 'ls-tree', '-l', $p->{bl}, $path );
    my $cnt = 100;
    $c->stash->{json} = [
        grep { defined }
        map { 
            my ($attr, $type, $sha, $size, @f) = split /\s+/, $_;
            my $f = join ' ',@f;
            my $file = _file($f);
            $sha = substr( $sha, 0, 8 );
            my $basename = $file->basename;
            $cnt-- > 0
                ? +{
                    path    => "$f",
                    item    => "$basename",
                    size    => $size,
                    version => $sha,
                    leaf    => ( $type eq 'blob' ? \1 : \0 )
                }
                : undef
        } @ls 
    ];
    $c->forward('View::JSON');
}

sub file : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $ref = $p->{ref};
    my $path = $p->{path};
    my $version = $p->{version};
    my $repo_path = $p->{repo_path};
    my $pane = $p->{pane} || 'hist'; # hist, diff, source, blame

    my $res = { pane => $pane };

    # TODO separate concerns, put this in Git Repo provider
    #      Baseliner::Repo->new( 'git:repo@tag:file' )
    my $g = Girl::Repo->new( path=>"$repo_path" );
    if( $pane eq 'hist' ) {
        my @log = $g->git->exec( 'log', '--pretty=oneline', '--decorate', $ref, '--', $path );
        my @formatted_log;
        for (@log) {
            my $rev_data = {};
            $_ =~ /^(.+?)\s\(.*?\)\s(.*)$/;
            my $commit = $1;
            my $revs = $2;
            my $author;
            my $date;
            my @log_data = $g->git->exec( 'rev-list', '--pretty', $commit );
            map {
                if ( $_ =~ /^Author:\s(.*)$/ ) {
                    $author = $1;
                }
                if ( $_ =~ /^Date:\s(.*)$/ ) {
                    $date = $1;
                }

            }
            grep {
                /Author:|Date:/
            } @log_data;
            push @formatted_log, { commit => $commit, revs => $revs, author => $author, date => $date};
        };
        $res->{info} = \@formatted_log;
    }
    elsif( $pane eq 'diff' ) {
        my @log = $g->git->exec( 'diff', $ref, '--', $path );
        $res->{info} = \@log;
    }
    elsif( $pane eq 'source' ) {
        my @log = $g->git->exec( 'cat-file', '-p', $version );
        $res->{info} = \@log;
    }
    
    $c->stash->{json} = $res;
    $c->forward('View::JSON');
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
    my ($user, $pass, $host) = ( 'ICDMPA0', 'FEB01FEB', '192.168.107.2' );

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
        my $vol = $f[0];
        
        next if ($vol eq 'Migrated');

        my ($vol, $unit, $ref, $ext, $used, $fmt, $lrecl, $blksz, $dsorg, $dsname ) = @f;
        _log "FFFFFFFFFFFFFF=" . join ',', @f;
        
        my $is_leaf = @f <= 5 || $unit ne '3390' ;
        my $text = @f < 2 || $unit ne '3390' ? $vol : ( @f <= 5 ? $f[4] : $dsname );

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
    my ($user, $pass, $host) = ( 'ICDMPA0', 'FEB01FEB', '192.168.107.2' );

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
