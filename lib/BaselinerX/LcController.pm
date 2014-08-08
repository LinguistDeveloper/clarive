package BaselinerX::LcController;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use utf8;
require Girl;

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = 'lifecycle';

register 'action.project.see_lc' => { name => 'User can access the project lifecycle' };

sub tree_topic_get_files : Local {
    my ($self,$c) = @_;
    my @tree;

    my $id_topic = $c->req->params->{id_topic} ;
    my $sw_get_files = $c->req->params->{sw_get_files} ;
    
    if ($sw_get_files){
        my @files = mdb->joins( master_rel=>{ from_mid=>$self->mid, rel_type=>'topic_asset' },
            to_mid=>mid=>master_doc=>[{},{ fields=>{ yaml=>0 }}] );
        for my $file ( @files ) {
            push @tree, {
                text       => $file->{filename} . '(v' . $file->{versionid} . ')',
                #url        => '/lifecycle/tree_topic_get_files',
                data       => {
                   id_file => $file->{mid},
                   #sw_get_files =>\1
                },
                #icon       => '/static/images/icons/project_small.png',
                leaf       => \1,
                expandable => \0
            };
        }
    }
    else{
        my $files = mdb->master_rel->find({ from_mid=>"$id_topic", rel_type=>'topic_asset' })->count;
        if ($files > 0){
            push @tree, {
               text       => _loc ('Files'),
               url        => '/lifecycle/tree_topic_get_files',
               data       => {
                  id_topic => $id_topic,
                  sw_get_files =>\1
               },
               icon       => '/static/images/icons/directory.png',
               leaf       => \0,
               expandable => \1
           };           
        }
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree_project_releases : Local {
    my ($self,$c) = @_;
    my %seen = ();
    
    my $id_project = $c->req->params->{id_project};
    my @topics = map { $$_{from_mid} } mdb->master_rel->find({ to_mid=>"$id_project", rel_type=>'topic_project' })->all;
    my @rels = mdb->topic->find({ is_release=>'1', mid=>mdb->in(@topics) })->all;


    my @menu_related = $self->menu_related();
    my @tree = map {
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.png',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid},
                category_color => $_->{category}{color},
                category_name  => $_->{category}{name},
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{category}{name}, $_->{mid} ),
            },
            menu => \@menu_related
       }
    } @rels;
    #$c->stash->{release_only} = 1;
    #$c->forward('tree_topics_project');
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub category_contents : Local {
    my ($self,$c) = @_;
    my %seen = ();
    my ($category_id) = _array($c->req->params->{category_id});
    my ($cnt,@user_topics) = Baseliner->model('Topic')->topics_for_user( { username => $c->username, categories => $category_id, clear_filter => 1 });
    @user_topics = map { $_->{mid}} @user_topics;

    my @rels = mdb->topic->find( { 'category_status.type' => mdb->nin('F','FC'), mid => mdb->in(@user_topics) })->all;
    
    
    my %categories = mdb->category->find_hash_one( id=>{},{ workflow=>0, fields=>0, statuses=>0, _id=>0 });
    
    my @menu_related = $self->menu_related();

    my %related;
    map { $related{$_->{from_mid}} = 1 if !$related{$_->{from_mid}} } mdb->master_rel->find( { from_mid => mdb->in(@user_topics), rel_type => 'topic_topic' } )->all;

    my @tree = map {
        my $leaf = ci->new($_->{mid})->children( where => { collection => 'topic'}, depth => 1) ? \0 : \1;
       +{
            text => ' ('.$_->{category_status}->{name}.') '.$_->{title},
            icon => '/static/images/icons/release.png',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid}. ' ('.$_->{category_status}->{name}.')',
                category_color => $_->{category}->{color},
                category_name  => $_->{category}->{name},
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{category}->{name}, $_->{mid} ),
            },
            leaf => $leaf,
            expandable => !$leaf,
            menu => \@menu_related
       }
    } @rels;
    #$c->stash->{release_only} = 1;
    #$c->forward('tree_topics_project');
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree_project_jobs : Local {
    my ($self,$c) = @_;
    my $id_project = $c->req->params->{id_project} ;
    
    my @jobs = ci->parents( mid=>$id_project, rel_type=>'job_project',
        start=>1, rows=>20, no_rels=>1,
        sort => { from_mid=>-1 },
    );

    my @tree = map {
        my $icon   = $_->status_icon || 'job.png';
       +{
            text => sprintf('%s [%s]', $_->name, $_->endtime) ,
            icon => '/static/images/icons/'.$icon,
            leaf => \1,
            menu => [
                {
                  icon => '/static/images/icons/job.png',
                  text => _loc('Open...'),
                  page => {
                      url => sprintf( "/job/log/dashboard?mid=%s&name=%s", $_->mid, $_->name ),
                      title => $_->name,
                  }
                }
            ],
            data => {
                #topic_mid    => $_->{mid},
            },
       }
    } @jobs;
    #$c->stash->{release_only} = 1;
    #$c->forward('tree_topics_project');
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

=head2 tree_topics_project

Left hand tree "Topics" in each one of the explorer projects.

=cut
sub tree_topics_project : Local {
    my ($self,$c) = @_;
    my $project = $c->req->params->{project} ;
    my $id_project = $c->req->params->{id_project} ;
    
    my ($cnt,@user_topics) = Baseliner->model('Topic')->topics_for_user( { username => $c->username, id_project => $id_project, clear_filter => 1 });
    @user_topics = map { $_->{mid}} @user_topics;

    my @rels = mdb->topic->find( { 'category_status.type' => mdb->nin('F','FC'), mid => mdb->in(@user_topics) })->all;
    
    my @menu_related = $self->menu_related();

    my %related;
    map { $related{$_->{from_mid}} = 1 if !$related{$_->{from_mid}} } mdb->master_rel->find( { from_mid => mdb->in(@user_topics), rel_type => 'topic_topic' } )->all;

    my @tree = map {
       my $leaf = $related{$_->{mid}} ? \0 : \1;
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.png',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid}. ' ('.$_->{category_status}->{name}.')',
                category_color => $_->{category}->{color},
                category_name  => $_->{category}->{name},
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{category}->{name}, $_->{mid} ),
            },
            leaf => $leaf,
            expandable => !$leaf,
            menu => \@menu_related
       }
    } @rels;
    #$c->stash->{release_only} = 1;
    #$c->forward('tree_topics_project');
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub topic_children_for_state {
    my ($self,%p) = @_;
    my $topic_mid = $p{topic_mid};
    my $state_id = $p{state_id};
    my $id_project = $p{id_project};
    
    # get all children topics
    my @chi_topics = mdb->joins( master_rel=>{ rel_type=>'topic_topic', from_mid=>"$topic_mid" }, to_mid => mid => topic=>[{},{mid=>1}] );
    push @chi_topics, map { mdb->joins( master_rel=>{ rel_type=>'topic_topic', from_mid=>"$$_{mid}" }, to_mid => mid => topic=>[{},{mid=>1}] ) } @chi_topics;

    # now filter them thru user visibility, current state 
    my $where = {
        username     => $p{username},
        clear_filter => 1,
        id_project   => $id_project,
        topic_list   => [ map{ $$_{mid} } @chi_topics ],
    }; 
    if ( $state_id ) {
        $where->{statuses} = [ "$state_id" ];
    }

    my ( $cnt, @topics ) = Baseliner->model('Topic')->topics_for_user($where);
    
    return @topics;
}

sub topic_contents : Local {
    my ($self,$c) = @_;
    my @tree;
    my $topic_mid = $c->req->params->{topic_mid};
    my $state = $c->req->params->{state_id};
    my @topics = ci->new($topic_mid)->children( where => { collection => 'topic'}, depth => 1);

    # mdb->master_rel->find( { from_mid => $topic_mid } )->all;
    my @mids = map { $_->{mid} } @topics;
    @topics = mdb->topic->find( { mid=>mdb->in(@mids) } )->all;
    my %related;
    map { $related{$_->{from_mid}} = 1 } mdb->master_rel->find( { from_mid => mdb->in(@mids), rel_type => 'topic_topic' } )->all;
    for ( @topics ) {
        my $is_release = $_->{category}{is_release};
        my $is_changeset = $_->{category}{is_changeset};

        my $icon = $is_release ? '/static/images/icons/release_lc.png'
            : $is_changeset ? '/static/images/icons/changeset_lc.png' :'/static/images/icons/topic.png' ;

        my @menu_related = $self->menu_related();

        # my $mid_project = $_->{_project_security}->{project}[0];
        # my $project_name = $mid_project ? mdb->project->find_one({ mid=>$mid_project })->{name} : '';

        # my $title_project = "(" . $project_name . ")";
        my $leaf = $related{$_->{mid}} ? \0 : \1;

        push @tree, {
            text       => $_->{title},
            #text       => $_->{title},
            topic_name => {
                mid             => $_->{mid},
                category_color  => $_->{category}{color},
                category_name   => _loc($_->{category}{name}),
                is_release      => $is_release,
                is_changeset    => $is_changeset,
            },
            url        => '/lifecycle/topic_contents',
            data       => {
               topic_mid   => $_->{to_mid},
               click       => $self->click_for_topic(  $_->{category}{name}, $_->{mid} ),
            },
            icon       => $icon, 
            leaf       => $leaf,
            expandable => !$leaf,
            menu => \@menu_related
        };
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree_releases : Local {
    my ($self,$c) = @_;
    my %seen = ();
    my @categories  = map { $_->{id}} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'view' );
    my @rels = mdb->category->find({ id =>mdb->in(@categories), is_release=>mdb->true })->fields({ fields=>0, workflow=>0 })->all;
    my @tree = map {
       +{
            text => $_->{name},
            icon => '/static/images/icons/release.png',
            url  => '/lifecycle/category_contents?category_id='.$_->{id},
            category_name => {
                category_id => $_->{id},
                category_color => $_->{color},
                category_name  => $_->{name},
            },
            data => {
                category_id    => $_->{id},
                click       => $self->click_category(  $_->{name}, $_->{id} ),
            }
       }
    } @rels;
    #$c->stash->{release_only} = 1;
    #$c->forward('tree_topics_project');
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
} 

sub tree_projects : Local {
    my ( $self, $c ) = @_;
    my @tree;

    my @projects_ids= Baseliner->model('Permissions')->user_projects_ids( username=>$c->username );
    my $projects =  ci->project->find({ active => mdb->true, mid => mdb->in(@projects_ids)})->sort({name=>1});

    while( my $r = $projects->next ) {
        push @tree, {
            text       => $r->{name},
            url        => '/lifecycle/tree_project',
            data       => {
                id_project => $r->{mid},
                project    => $r->{name},
                click => {
                    url   => '/dashboard/list/project',
                    type  => 'html',
                    icon  => '/static/images/icons/project.png',
                    title => $r->{name},
                }               
            },
            icon       => '/static/images/icons/project.png',
            leaf       => \0,
            expandable => \1
        };
    }
    @tree = sort { lc($$a{text}) cmp lc($$b{text}) } @tree;
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
    my $lc = BaselinerX::Lc->new->lc_for_project( $id_project, $project, $c->username );
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
                state_name => _loc($node->{name} // $node->{node}),
                %{ $node->{data} || {} }
            },
            leaf       => $$node{leaf} // \0,
            expandable => \0
        };
    }

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

# a generic dispatcher for repo contents - that way we avoid having to implement a controller for each repo
sub list_repo_contents : Local {
    my ($self,$c) = @_;
    my @tree;
    my $p = $c->req->params;
    try {
        my $id_repo = $p->{id_repo} or _throw 'missing repo id';
        my $repo = Baseliner::CI->new( $id_repo );

        #if( $config->{show_changes_in_tree} || !$p->{id_status} ) { 
        
        my @items = $repo->list_contents( request=>$p );
        _debug _loc "---- provider ".$repo->name." has %1 changesets", scalar @items;

        # loop through the repo objects
        for my $it ( @items ) {
            my $menu = [];
            # get menu extensions (find packages that do)
            # get node menu
            push @$menu, _array $it->node_menu if ref $it->node_menu;
            push @tree, {
                url        => $it->node_url,
                data       => $it->node_data,
                #parent_data => { id_project=>$id_project, project=>$project }, 
                menu       => $menu,
                icon       => $it->icon,
                text       => $it->text || $it->name,
                leaf       => \0,
                expandable => \0
            };
        }
    } catch {
        my $err = shift;   
        my $msg = _loc('Error detected: %1', $err );
        _error( $msg );
        push @tree, { 
            text => substr($msg,0,255), 
            data => {},
            icon => '/static/images/icons/error.png',
            leaf=>\1,
            expandable => \0
        };
    };

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub branches : Local {
    my ($self,$c) = @_;
    my @tree;

    my $p = $c->req->params;
    my $project = $p->{project} or _throw 'missing project';
    my $id_project = $p->{id_project} or _throw 'missing project id';
    my $id_repo = $p->{id_repo} or _throw 'missing repo id';

    my $config = config_get 'config.lc';
    # provider-by-provider:
    # get all the changes for this project + baseline
    my @cs;

    if( $config->{show_changes_in_tree} || !$p->{id_status} ) { 

        try {
            my $repo = Baseliner::CI->new( $id_repo );

            my @changes = $repo->can('list_contents') 
                ?  $repo->list_contents( request=>$p )
                : $repo->list_branches( project=>$project );
            _debug _loc "---- provider ".$repo->name." has %1 changesets", scalar @changes;
            push @cs, @changes;

            # loop through the branch objects 
            for my $cs ( @cs ) {
                my $menu = [];
                # get menu extensions (find packages that do)
                # get node menu
                push @$menu, _array $cs->node_menu if ref $cs->node_menu;
                push @tree, {
                    url        => $cs->node_url,
                    data       => $cs->node_data,
                    parent_data => { id_project=>$id_project, project=>$project }, 
                    menu       => $menu,
                    icon       => $cs->icon,
                    text       => $cs->text || $cs->name,
                    leaf       => \0,
                    expandable => \0
                };
            }
        } catch {
            my $err = shift;   
            my $msg = _loc('Error detected: %1', $err );
            _error( $msg );
            push @tree, { 
                text => substr($msg,0,255),
                data => {},
                icon => '/static/images/icons/error.png',
                leaf=>\1,
                expandable => \0
            };
        };
    }

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub changeset : Local {
    my ($self,$c) = @_;
    my @tree;

    my $p = $c->req->params;

    my $bl = $p->{bl} || '*';
    my $project = $p->{project} or _throw 'missing project';
    my $state_name = $p->{state_name} or _throw 'missing state name';
    my $id_project = $p->{id_project} or _throw 'missing project id';

    my $config = config_get 'config.lc';
    # provider-by-provider:
    # get all the changes for this project + baseline
    my @cs;

    if( $config->{show_changes_in_tree} || !$p->{id_status} ) { 
        for my $provider ( packages_that_do 'Baseliner::Role::LC::Changes' ) {
            #push @cs, $class;
            try {
                my $prov = $provider->new( project=>$project );
                my @changes = $prov->list( project=>$project, bl=>$bl, id_project=>$id_project, state_name=>$state_name );
                _debug _loc "---- provider $provider has %1 changesets", scalar @changes;
                push @cs, @changes;
            } catch {
                my $err = shift;
                my $msg = _loc('Error loading changes for provider %1: %2', $provider, $err);
                _error( $msg );
                push @tree, {
                    icon => '/static/images/icons/error.png',
                    text => substr($msg,0,80), 
                    leaf => \1,
                };
            };
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
    }

    ## add what's in this baseline 
    my $repos = Baseliner::CI->new( $id_project )->repositories;
    # ( Girl::Repo->new( path=>"$path" ), $rev, $project );

    if ( $bl ne '*' ) {
        for( _array $repos ) {
            my $d = $_->load;
            push @tree, {
                url  => '/lifecycle/repository',
                icon => '/static/images/icons/repo.gif',
                text => $d->{name},
                leaf => \1,
                data => {
                    bl    => $bl,
                    name  => $d->{name},
                    repo_path  => $d->{repo_dir},
                    click => {
                        url   => '/lifecycle/repository',
                        type  => 'comp',
                        icon  => '/static/images/icons/repo.gif',
                        title => "$d->{name} - $bl",
                    }
                  },
            }
        }
    }

    #################################################################
    #
    # topics for a state
    #
    my $bind_releases = 0;
    my @changes = mdb->joins(
                master_rel=>{ rel_type=>'topic_project', to_mid=>"$id_project" },
                from_mid=>mid=>topic=>{ is_changeset=>'1', 'category_status.id'=> "$p->{id_status}" });
            
    # find releases for each changesets
    my @topic_topic = mdb->master_rel->find({ to_mid=>mdb->in(map{$$_{mid}}@changes), rel_type=>'topic_topic' })->all;
    my %rels = map{ $$_{mid}=>$_ }mdb->topic->find({ mid=>mdb->in(map{$$_{from_mid}}@topic_topic), is_release=>mdb->true })->all;
    my %releases;
    push @{ $releases{ $$_{to_mid} } } => $rels{$$_{from_mid}} for @topic_topic;
        
    $bind_releases = ci->status->find_one({ id_status=>''. $p->{id_status} })->{bind_releases};
    my %categories = mdb->category->find_hash_one( id=>{},{ workflow=>0, fields=>0, statuses=>0, _id=>0 });

    my @rels;
    for my $topic (@changes) {
        my @releases_for_changeset = _array( $releases{ $topic->{mid} } );
        push @rels, @releases_for_changeset;  # slow! join me!
        next if $bind_releases && @releases_for_changeset;
        # get the menus for the changeset
        my ( $deployable, $promotable, $demotable, $menu ) = $self->cs_menu(
            $c,
            topic      => $topic,
            bl_state   => $bl,
            state_name => $state_name,
            id_project => $id_project,
            categories => \%categories
        );
        my $node = {
            url  => '/lifecycle/topic_contents',
            icon => '/static/images/icons/changeset_lc.png',
            text => $topic->{title},
            leaf => \1,
            menu => $menu,
            topic_name => {
                mid             => $topic->{mid},
                category_color  => $$topic{category}{color}, 
                category_name   => _loc($$topic{category}{name}),
                is_release      => $$topic{category}{is_release},
                is_changeset    => $$topic{category}{is_changeset},
            },
            data => {
                ns           => 'changeset/' . $topic->{mid},
                bl           => $bl,
                name         => $topic->{title},
                promotable   => $promotable,
                demotable    => $demotable,
                deployable   => $deployable,
                state_id     => $p->{id_status},
                id_project   => $id_project,
                state_name   => _loc($state_name),
                topic_mid    => $topic->{mid},
                topic_status => $topic->{id_category_status},
                click        => $self->click_for_topic(  _loc($$topic{category}{name}), $topic->{mid} )
            },
        };
        # push @tree, $node if ! @rels;
        push @tree, $node;
    }
    if( $bl ne "new" && @rels ) {
        my %unique_releases = map { $$_{mid} => $_ } @rels;
        for my $rel ( values %unique_releases ) {
            my ( $deployable, $promotable, $demotable, $menu ) = $self->cs_menu(
                $c,
                topic      => $rel,
                bl_state   => $bl,
                state_name => $state_name,
                id_status_from  => $p->{id_status},
                id_project => $id_project,
                categories => \%categories,
            );
            my $node = {
                url  => '/lifecycle/topic_contents',
                icon => '/static/images/icons/release_lc.png',
                text => $rel->{title},
                leaf => \0,
                menu => $menu,
                topic_name => {
                    mid             => $rel->{mid},
                    category_color  => $rel->{category}{color},
                    category_name   => $rel->{category}{name},
                    is_release      => \1,
                },
                data => {
                    ns           => 'changeset/' . $rel->{mid},
                    bl           => $bl,
                    name         => $rel->{title},
                    promotable   => $promotable,
                    demotable    => $demotable,
                    deployable   => $deployable,
                    state_name   => _loc($state_name),
                    id_project   => $id_project,
                    state_id     => $p->{id_status},
                    topic_mid    => $rel->{mid},
                    topic_status => $rel->{id_category_status},
                    click        => $self->click_for_topic(  _loc($rel->{category}{name}), $rel->{mid} )
                },
            };
            push @tree, $node;
        }
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub promotes_and_demotes {
    my ($self, %p ) = @_; 
    my ( $username, $topic, $id_status_from, $id_project ) = @p{ qw/username topic id_status_from id_project/ };
    my ( @menu_s, @menu_p, @menu_d );
    $id_status_from //= $topic->{category_status}{id};

    _fail _loc 'Missing topic parameter' unless $topic;
    
    my $id_status_from_lc = $id_status_from ? $id_status_from : $topic->{id_category_status};
    my @user_workflow = _unique map {$_->{id_status_to} } Baseliner->model("Topic")->user_workflow( $username );
    my @user_roles = ci->user->roles( $username );
    my %statuses = ci->status->statuses;
    my %bls = map{ $$_{mid}=>$$_{moniker} || $$_{bl} }ci->bl->find->all;
    my @bl_from = _array $statuses{ $id_status_from }{bls};
    my $cat = mdb->category->find_one({ id=>''.$topic->{id_category} },{ workflow=>1 });
    _fail _loc 'Category %1 not found', $topic->{id_category} unless $cat;
    
    my $status_list = sub {
        my ($dir) = @_;
        my %seen;
        return sort { $$a{seq} <=> $$b{seq} }
            map { 
                my $st = $statuses{ $$_{id_status_to} };
                $st;
            }
            grep {
               my $k = join',', ( map{ $_ // '' } $$_{id_status_from},$$_{id_status_to} );
               my $flag = exists $seen{$k};
               $seen{$k} = 1;
               !$flag;
            } 
            grep {
               $$_{id_role} ~~ @user_roles
               && $$_{id_status_to} ~~ @user_workflow
               && $$_{id_status_from} == $id_status_from_lc
            } 
            grep {
               ( $$_{job_type} // '' ) eq $dir  # static,promote,demote
            }
            _array( $$cat{workflow} );
    };
    
    # Static
    my @statics = $status_list->( 'static' );

    my ($cs_project) = ci->new($topic->{mid})->projects;
    my @project_bls = map { $_->{bl} } _array $cs_project->bls;

    my $statics={};
    for my $status ( @statics ) {
        for my $bl ( map { $bls{$_} } _array $status->{bls} ) {        
            if ( !@project_bls || $bl->{bl} ~~ @project_bls ){
                $statics->{ $bl } = \1;
                push @menu_s, {
                    text => _loc( 'Deploy to %1 (%2)', _loc( $status->{name} ), $bl ),
                    eval => {
                        url            => '/comp/lifecycle/deploy.js',
                        title          => 'Deploy',
                        job_type       => 'static',
                        bl_to          => $bl,
                        id_project     => $id_project,
                        status_to      => $status->{id_status},
                        status_to_name => _loc($status->{name}),
                    },
                    id_status_from => $id_status_from_lc,
                    icon => '/static/images/silk/arrow_right.gif'
                };
            }
        }
    }

    # Promote
    my @status_to = $status_list->( 'promote' );
    
    my $promotable={};
    for my $status ( @status_to ) {
        for my $bl ( map { $bls{$_} } _array $status->{bls} ) {        
            if ( !@project_bls || $bl->{bl} ~~ @project_bls ){
                $promotable->{ $bl } = \1;
                push @menu_p, {
                    text => _loc( 'Promote to %1 (%2)', _loc( $status->{name} ), $bl ),
                    eval => {
                        url            => '/comp/lifecycle/deploy.js',
                        title          => 'To Promote',
                        job_type       => 'promote',
                        id_project     => $id_project,
                        bl_to          => $bl,
                        status_to      => $status->{id_status},
                        status_to_name => _loc($status->{name}),
                    },
                    id_status_from => $id_status_from_lc,
                    icon => '/static/images/silk/arrow_down.gif'
                };
            }
        }
    }

    # Demote
    my @status_from = $status_list->( 'demote' );

    my $demotable={};
    for my $status ( @status_from ) {
        for my $bl ( map { $bls{$_} } @bl_from ) {        
            if ( !@project_bls || $status->{statuses_from}{bl} ~~ @project_bls ){
                $demotable->{ $bl } = \1;
                push @menu_d, {
                    text => _loc( 'Demote to %1 (from %2)', _loc($status->{name}), $bl ),
                    eval => {
                        url            => '/comp/lifecycle/deploy.js',
                        title          => 'Demote',
                        job_type       => 'demote',
                        id_project     => $id_project,
                        bl_to          => $bl,
                        status_to      => $status->{id_status},
                        status_to_name => _loc( $status->{name} ),
                    },
                    id_status_from => $id_status_from_lc,
                    icon => '/static/images/silk/arrow_up.gif'
                };
            }
        }
    }
    return ( $statics, $promotable, $demotable, \@menu_s, \@menu_p, \@menu_d );
}

sub cs_menu {
    my ($self, $c, %p ) = @_; 
    my ( $topic, $bl_state, $state_name, $id_status_from, $id_project, $categories ) = @p{ qw/topic bl_state state_name id_status_from id_project categories/ };
    #return [] if $bl_state eq '*';
    my ( @menu, @menu_s, @menu_p, @menu_d );
    my $sha = ''; 
    
    push @menu, $self->menu_related();

    my ($deployable, $promotable, $demotable ) = ( {}, {}, {} );
    my $is_release = $$categories{$topic->{id_category}}{is_release}; 
    
    if ( $is_release ) {
        # releases take the menu of their first child 
        #   TODO but should be intersection
        my @chi = 
            grep { $$_{category}{is_changeset} }
            $self->topic_children_for_state( username=>$c->username, topic_mid=>$topic->{mid}, state_id=>$id_status_from, id_project=>$id_project );
        
        if( @chi ) {
           my ($menu_s, $menu_p, $menu_d );
           ($deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = $self->promotes_and_demotes( 
                username   => $c->username,
                topic      => $chi[0],
                id_project => $id_project,
            );
           push @menu_s, _array( $menu_s );
           push @menu_p, _array( $menu_p );
           push @menu_d, _array( $menu_d );
        }
    } else {
        my ( $menu_s, $menu_p, $menu_d );

        ( $deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = $self->promotes_and_demotes(
            username   => $c->username,
            topic      => $topic,
            id_project => $id_project
        );
        push @menu_s, _array($menu_s);
        push @menu_p, _array($menu_p);
        push @menu_d, _array($menu_d);
    }

    push @menu, ( @menu_s, @menu_p, @menu_d );  # deploys, promotes, then demotes

    ( $deployable, $promotable, $demotable, \@menu );
}

sub repository : Local {
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
            my $basename = Girl->unquote($file->basename);
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
    if( $p->{favorites} && $p->{favorites} eq 'true' ) {
        $c->forward( 'tree_favorites' );
    } elsif( $p->{show_workspaces} && $p->{show_workspaces} eq 'true' ) {
        $c->forward( 'tree_workspaces' );    
    } elsif( $p->{show_releases} && $p->{show_releases} eq 'true' ) {
        $c->forward( 'tree_releases' );
    } elsif( $p->{show_ci} && $p->{show_ci} eq 'true' ) {
        $c->forward( '/ci/list' );
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
            #$c->forward('tree_lifecycle');
             $c->stash->{json} = {};
             $c->forward( 'View::JSON' );
        }
    }
}

sub tree_favorites : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my @tree;
    my $provider;
    my $user = $c->user_ci; 
    my $root = length $p->{id_folder} 
        ? $user->favorites->{ $p->{id_folder} }{contents}
        : $user->favorites;
   
    $root //= {};
    
    my $favs = [ map { $root->{$_} } sort { $a cmp $b }
        keys %$root ];

    for my $node ( @$favs ) {
        ! $node->{menu} and delete $node->{menu}; # otherwise menus don't work
        push @tree, $node;
    }
    $c->stash->{json} = \@tree;
}

sub tree_favorite_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->forward( 'tree_favorites' );
    $c->forward( 'View::JSON' );
}

sub tree_workspaces : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my @tree;
    my $user = $c->user_ci; 
    my $wks = $user->workspaces;
    for my $node ( map {$wks->{$_}} sort { $a<=>$b } keys %{$wks||{}} ) {
        ! $node->{menu} and delete $node->{menu}; # otherwise menus don't work
        $node->{text} //= $node->{name};
        $node->{icon} //= '/static/images/icons/workspaces.png';
        push @tree, $node;
    }
    $c->stash->{json} = \@tree;
}

sub favorite_add : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        # create the favorite id 
        my $id = time . '-' .  int rand(9999);
        # delete empty ones
        $p->{$_} eq 'null' and delete $p->{$_} for qw/data menu/;
        # if its a folder
        if( length $p->{id_folder} ) {
           $p->{id_folder} = $id; #_name_to_id delete $p->{id_folder};
           $p->{url} //= '/lifecycle/tree_favorite_folder?id_folder=' . $p->{id_folder};
        }
        # decode data structures
        defined $p->{$_} and $p->{$_} = _decode_json( $p->{$_} ) for qw/data menu/;
        $p->{id_favorite} = $id;
        my $user = $c->user_ci; 
        $user->favorites->{$id} = $p; 
        $user->save;
        { success=>\1, msg=>_loc("Favorite added ok"), id_folder => $p->{id_folder} }
    } catch {
        { success=>\0, msg=>shift() }
    };
    $c->forward( 'View::JSON' );
}

sub favorite_del : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        my $user = $c->user_ci; 
        my $favs = $user->favorites;
        # delete node
        my $id = $p->{id};
        if( ! delete $favs->{$id} ) {
            # search 
            delete $favs->{$_}{contents}{$id} for keys %$favs;  
        }
        $user->save;
        { success=>\1, msg=>_loc("Favorite removed ok") }
    } catch {
        { success=>\0, msg=>shift() }
    };
    $c->forward( 'View::JSON' );
}

sub favorite_rename : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        _fail _loc "Invalid name" unless length $p->{text};
        
        # TODO rename id_folder in case it's a folder?
        my $user = $c->user_ci; 
        my $d = $user->favorites->{ $p->{id} };
        $d->{text} = $p->{text};
        $user->save;
        { success=>\1, msg=>_loc("Favorite renamed ok") }
    } catch {
        { success=>\0, msg=>shift() }
    };
    $c->forward( 'View::JSON' );
}

sub favorite_add_to_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        # get data
        my $user = $c->user_ci; 
        my $d = $user->favorites->{ $p->{id_folder} }; 
        _fail _loc "Not found: %1", $p->{id_folder} unless defined $d; 
        $d->{contents} //= {};
        # delete old
        my $fav = delete $user->favorites->{ $p->{id_favorite} }; 
        # set new 
        $d->{favorite_folder} = $p->{id_folder};
        $d->{contents}{ $p->{id_favorite} } = $fav; 
        $user->save;
        { success=>\1, msg=>_loc("Favorite moved ok") }
    } catch {
        { success=>\0, msg=>shift() }
    };
    $c->forward( 'View::JSON' );
}

sub click_for_topic {
    my ($self, $catname, $mid ) = @_;
    +{ 
        url   => sprintf('/topic/view?topic_mid='.$mid),
        type  => 'comp',
        icon  => '/static/images/icons/topic.png',
        title => sprintf( "%s #%d", _loc($catname), $mid ),
    };
}

sub click_category {
    my ($self, $catname, $id ) = @_;
    +{ 
        url   => sprintf("/topic/grid?category_id=".$id),
        type  => 'comp',
        icon  => '/static/images/icons/topic.png',
        title => sprintf( "%s #%d", _loc($catname), $id ),
    };
}


sub build_topic_tree {
    my $self = shift;
    my %p    = @_;
    my @menu_related = $self->menu_related();
    my $category = $p{category} // $p{topic}{category} // $p{topic}{categories};

    return +{
        text     => $p{topic}{title},
        calevent => {
            mid    => $p{mid},
            color  => $category->{color},
            title  => $p{topic}{title},
            allDay => \1
        },
        url        => '/lifecycle/tree_topic_get_files',
        topic_name => {
            mid            => $p{mid},
            category_color => $category->{color},
            category_name  => _loc($category->{name}),
            is_release     => $p{is_release} // $category->{is_release},
            is_changeset   => $p{is_changeset} // $category->{is_changeset},
        },
        children => [
            {
                text => _loc('Files'),
                icon => '/static/images/icons/directory.png',
                url  => '/lifecycle/tree_topic_get_files',
                leaf => \0,
                data => {
                    id_topic     => $p{mid},
                    sw_get_files => \1
                },
            }
        ],
        data => {
            topic_mid => $p{mid},
            click     => $self->click_for_topic( $category->{name}, $p{mid} )
        },
        icon       => $p{icon} // q{/static/images/icons/topic.png},
        leaf       => \0,
        expandable => \1,
        menu => \@menu_related
    };
}

sub topics_for_release : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my @cis = ci->new($p->{id_release})->children( rel_type => "topic_topic", depth => -1);

    #my @topics = _unique map { $_->{_ci}->{mid} } @cis;
    my @topics = _unique map { $_->{mid} } @cis;
    push @topics, $p->{id_release};        

    $c->stash->{json} = { success=>\1, topics=>\@topics };
    $c->forward('View::JSON');
}

sub menu_related {
    my ($self, $mid ) = @_;
    my @menu;
        push @menu, {  text => _loc('Related'),
                        icon => '/static/images/icons/topic.png',
                        eval => {
                            handler => 'Baseliner.open_topic_grid_from_release'
                        }
                    };
        push @menu, {  text => _loc('Apply filter'),
                        icon => '/static/images/icons/topic.png',
                        eval => {
                            handler => 'Baseliner.open_apply_filter_from_release'
                        }
                    };           
    return @menu;
}

1;
