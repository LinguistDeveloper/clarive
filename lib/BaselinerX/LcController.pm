package BaselinerX::LcController;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use experimental 'autoderef', 'smartmatch';
require Girl;
use BaselinerX::Type::Action;
use Baseliner::Model::Topic;
use Baseliner::Model::Favorites;
use Baseliner::Model::Permissions;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;

__PACKAGE__->config->{namespace} = 'lifecycle';

register 'action.project.see_lc' => { name => _locl('User can access the project lifecycle') };

register 'config.releases' => {
    name => _locl('Config lifecycle releases'),
    metadata => [
        { id=>'by_project', label=>'Group by project', default=>0 },
    ],
};

sub tree_topic_get_files : Local {
    my ( $self, $c ) = @_;
    my @tree;

    my $id_topic     = $c->req->params->{id_topic};
    my $sw_get_files = $c->req->params->{sw_get_files};
    if ($sw_get_files) {
        my @files = mdb->joins(
            master_rel => { from_mid => $id_topic, rel_type => 'topic_asset' },
            to_mid => mid => master_doc => [ {}, { fields => { yaml => 0 } } ]
        );

        for my $file (@files) {
            push @tree,
                {
                text    => $file->{name} . '(v' . $file->{versionid} . ')',
                iconCls => 'default_folders',
                data    => {
                    id_file => $file->{mid},
                    click   => {
                        url   => sprintf( '/topic/download_file/' . $file->{mid} . '/' . $file->{name} ),
                        type  => 'download',
                        title => sprintf( $file->{name} . '(v' . $file->{versionid} . ')' ),
                    }
                },
                leaf       => \1,
                expandable => \0
                };
        }
    }
    else {
        my $files = mdb->master_rel->find( { from_mid => "$id_topic", rel_type => 'topic_asset' } )->count;
        if ( $files > 0 ) {
            push @tree,
                {
                text => _loc('Files'),
                url  => '/lifecycle/tree_topic_get_files',
                data => {
                    id_topic     => $id_topic,
                    sw_get_files => \1
                },
                icon       => '/static/images/icons/delete_red.svg',
                leaf       => \0,
                expandable => \1
                };
        }
    }
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub tree_project_releases : Local {
    my ($self,$c) = @_;
    my %seen = ();

    my $p = $c->req->params;
    my $id_project = $p->{id_project};
    my $query = $p->{query};
    my ( $info, @rels ) = Baseliner::Model::Topic->new->topics_for_user({
        username     => $c->username,
        id_project   => $id_project,
        is_release => 1,
        clear_filter => 1,
        ( $query ? ( query => $query ) : () )
    });

    #my @topics = map { $$_{from_mid} } mdb->master_rel->find({ to_mid=>"$id_project", rel_type=>'topic_project' })->all;
    #my @rels = mdb->topic->find({ is_release=>'1', mid=>mdb->in(@topics) })->all;

    my @menu_related = $self->menu_related();
    my @tree = map {
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.svg',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid},
                category_color => $_->{category}->{color},
                category_name  => $_->{category}->{name},
                category_status => "<b>(" . $_->{category_status}->{name} . ")</b>",
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{category}{name}, $_->{mid} ),
                'on_drop' => {
                       'url' => '/comp/topic/topic_drop.js',
                 },
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
    my $p = $c->req->params;
    my ($category_id) = _array($p->{category_id});
    my ($id_project) = _array($p->{id_project});
    my $query = $p->{query};
    my ($info,@user_topics) = model->Topic->topics_for_user({ username=>$c->username, categories=>$category_id, clear_filter=>1, ($query?(query=>$query):()), ($id_project?(id_project=>$id_project):()) });
    @user_topics = map { $_->{mid}} @user_topics;

    my @rels = mdb->topic->find( { 'category_status.type' => mdb->nin('F','FC'), mid => mdb->in(@user_topics) })->all;

    my %categories = mdb->category->find_hash_one( id=>{},{ workflow=>0, fields=>0, statuses=>0, _id=>0 });

    my @menu_related = $self->menu_related();

    my %related;
    map { $related{$_->{from_mid}} = 1 } mdb->master_rel->find( { from_mid => mdb->in(@user_topics), rel_type => 'topic_topic' } )->all;

    my @tree = map {
        my $leaf = $related{$_->{mid}} ? \0 : \1;
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.svg',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid},
                category_color => $_->{category}->{color},
                category_name  => $_->{category}->{name},
                category_status => "<b>(" . $_->{category_status}->{name} . ")</b>",
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{category}->{name}, $_->{mid} ),
                'on_drop' => {
                       'url' => '/comp/topic/topic_drop.js',
                 },
            },
            leaf => $leaf,
            expandable => !$leaf,
            menu => \@menu_related
       }
    } @rels;
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree_project_jobs : Local {
    my ($self,$c) = @_;
    my $id_project = $c->req->params->{id_project} ;

    my @jobs = ci->parents( mid=>$id_project, rel_type=>'job_project',
        start=>1, rows=>20, no_rels=>1,
        sort => { from_mid=>-1 }, docs_only => 1
    );

    my @tree = map {
        my $icon   = Util->job_icon($_->{status},$_->{rollback}) || 'job.svg';
       +{
            text => sprintf('%s [%s]', $_->{name}, $_->{endtime}) ,
            icon => '/static/images/icons/'.$icon,
            leaf => \1,
            draggable => \0,
            menu => [
                {
                  icon => '/static/images/icons/open.svg',
                  text => _loc('Open...'),
                  page => {
                      url => sprintf( "/job/log/dashboard?mid=%s&name=%s", $_->{mid}, $_->{name} ),
                      title => $_->{name},
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
    my $p = $c->req->params;
    my $project = $p->{project} ;
    my $query = $p->{query};
    my $id_project = $p->{id_project} ;

    my ( $info, @user_topics ) = model->Topic->topics_for_user({
        username     => $c->username,
        id_project   => $id_project,
        clear_filter => 1,
        ( $query ? ( query => $query ) : () )
    });
    @user_topics = map { $_->{mid}} @user_topics;

    my @rels = mdb->topic->find( { 'category_status.type' => mdb->nin('F','FC'), mid => mdb->in(@user_topics) })->all;

    my @menu_related = $self->menu_related();

    my %related;
    map { $related{$_->{from_mid}} = 1 if !$related{$_->{from_mid}} } mdb->master_rel->find( { from_mid => mdb->in(@user_topics), rel_type => 'topic_topic' } )->all;

    my @tree = map {
       my $leaf = $related{$_->{mid}} ? \0 : \1;
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.svg',
            url  => '/lifecycle/topic_contents',
            draggable => \1,
            topic_name => {
                mid            => $_->{mid},
                category_color => $_->{category}->{color},
                category_name  => $_->{category}->{name},
                category_status => "<b>(" . $_->{category_status}->{name} . ")</b>",
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
    # my @chi_topics = mdb->joins( master_rel=>{ rel_type=>'topic_topic', from_mid=>"$topic_mid" }, to_mid => mid => topic=>[{},{mid=>1}] );
    # push @chi_topics, map { mdb->joins( master_rel=>{ rel_type=>'topic_topic', from_mid=>"$$_{mid}" }, to_mid => mid => topic=>[{},{mid=>1}] ) } @chi_topics;

    my @changeset_categories = map { $_->{id} } mdb->category->find({ is_changeset => '1'})->fields({id=>1, _id =>0})->all;
    my @chi_topics = ci->new($topic_mid)->children( where => { collection => 'topic', id_category => mdb->in(@changeset_categories)}, mids_only => 1, depth => 2);

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

    my ( $info, @topics ) = Baseliner->model('Topic')->topics_for_user($where);

    return @topics;
}

sub topic_contents : Local {
    my ($self,$c) = @_;
    my @tree;
    my $p = $c->req->params;
    my $topic_mid = $p->{topic_mid};
    my $state = $p->{state_id};
    my @topics = ci->new($topic_mid)->children( mids_only => 1, where => { collection => 'topic'}, depth => 1);

    # mdb->master_rel->find( { from_mid => $topic_mid } )->all;
    my @mids = map { $_->{mid} } @topics;
    @topics = mdb->topic->find( { mid=>mdb->in(@mids) } )->all;
    my %related;
    map { $related{$_->{from_mid}} = 1 } mdb->master_rel->find( { from_mid => mdb->in(@mids), rel_type => 'topic_topic' } )->all;
    for ( @topics ) {
        my $is_release = $_->{category}{is_release};
        my $is_changeset = $_->{category}{is_changeset};

        my $icon = $is_release ? '/static/images/icons/release_lc.svg'
            : $is_changeset ? '/static/images/icons/changeset_lc.svg' :'/static/images/icons/topic.svg' ;

        my @menu_related = $self->menu_related();

        my $leaf = $related{$_->{mid}} ? \0 : \1;
        push @tree, {
            text       => $_->{title},
            topic_name => {
                mid             => $_->{mid},
                category_color  => $_->{category}{color},
                category_name   => _loc($_->{category}{name}),
                category_status => "<b>(" . $_->{category_status}->{name} . ")</b>",
                is_release      => $is_release,
                is_changeset    => $is_changeset,
            },
            url        => '/lifecycle/topic_contents',
            data       => {
               topic_mid   => $_->{topic_mid},
               click       => $self->click_for_topic(  $_->{category}{name}, $_->{mid} ),
            },
            icon       => $icon,
            leaf       => $leaf,
            expandable => !$leaf,
            draggable => \1,
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
    my $config_releases = config_get('config.releases.by_project');
    my @tree = map {
       +{
            text => $_->{name},
            icon => '/static/images/icons/release.svg',
            url  => $config_releases && $config_releases->{by_project} eq '1' ? 'lifecycle/tree_projects?category_id='.$_->{id} : '/lifecycle/category_contents?category_id='.$_->{id},
            has_query => 1,
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
    my $p = $c->req->params;
    my ($category_id) = _array($p->{category_id});
    my @tree;
    my @projects_ids= Baseliner::Model::Permissions->new->user_projects_ids( $c->username );
    my $projects =  ci->project->find({ active => mdb->true, mid => mdb->in(@projects_ids)})->sort({name=>1});

    while( my $r = $projects->next ) {
        push @tree, {
            text       => $r->{name},
            url        => $category_id ? '/lifecycle/category_contents?category_id='.$category_id.'&id_project='.$r->{mid} : '/lifecycle/tree_project',
            data       => {
                id_project => $r->{mid},
                project    => $r->{name},
                desc       => $r->{description},
                click      => {
                    'icon' => '/static/images/icons/topic.svg',
                    'url' => '/topic/grid',
                    'title' => $r->{name},
                    'type' => 'comp'
                },
            },
            draggable  => \0,
            icon       => '/static/images/icons/project.svg',
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
            %$node,
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
        _debug _loc("---- provider %1 has %2 changesets", $repo->name, scalar @items);

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
                leaf       => $it->node_data->{leaf} // \0,
                expandable => !$it->node_data->{leaf} // \1
            };
        }
    } catch {
        my $err = shift;
        my $msg = _loc('Error detected: %1', $err );
        _error( $msg );
        push @tree, {
            text => substr($msg,0,255),
            data => {},
            icon => '/static/images/icons/error_red.svg',
            leaf=>\1,
            expandable => \0
        };
    };

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub branches : Local {
    my ( $self, $c ) = @_;

    my $p          = $c->req->params;
    my $project    = $p->{project} or _fail 'missing project';
    my $id_project = $p->{id_project} or _fail 'missing project id';
    my $id_repo    = $p->{id_repo} or _fail 'missing repo id';
    my $config     = config_get 'config.lc';

    my @changes;
    my @tree;

    if ( $config->{show_changes_in_tree} || !$p->{id_status} ) {
        try {
            my $repo = Baseliner::CI->new($id_repo);

            if ( $repo->can('list_tree') ) {
                @tree = $repo->list_tree( username => $c->username, %$p );
            }
            else {
                if ( $repo->{navigation_type} && $repo->{navigation_type} eq 'Directory' ) {
                    my $res = $repo->list_directories(
                        project    => $project,
                        repo_mid   => $id_repo,
                        username   => $c->username,
                        directory  => '',
                        id_project => $id_project
                    );
                    push @tree, $_ for _array( $res->{directories} );
                    @tree = sort { $a->{text} cmp $b->{text} } @tree;
                    push @changes, $_ for _array( $res->{repositories} );
                }
                else {
                    @changes =
                        $repo->can('list_contents')
                      ? $repo->list_contents( request => $p )
                      : $repo->list_branches(
                        project  => $project,
                        repo_mid => $id_repo,
                        username => $c->username
                      );
                }
                _debug _loc("---- provider %1 has %2 changesets", $repo->name, scalar @changes);

                for my $cs (@changes) {
                    my $menu = [];
                    my $data = $cs->node_data;
                    $data->{repo_mid}   = $id_repo;
                    $data->{id_project} = $id_project;
                    $data->{project}    = $project;

                    push @$menu, _array $cs->node_menu if ref $cs->node_menu;
                    push @tree, {
                        url         => $cs->node_url,
                        data        => $data,                                                #$cs->node_data,
                        parent_data => { id_project => $id_project, project => $project },
                        menu        => $menu,
                        icon        => $cs->icon,
                        text => $cs->text || $cs->name,
                        leaf => \0,
                        expandable => \0
                    };
                }
            }
        }
        catch {
            my $err = shift;
            my $msg = _loc( 'Error detected: %1', $err );
            _error($msg);
            push @tree,
              {
                text       => substr( $msg, 0, 255 ),
                data       => {},
                icon       => '/static/images/icons/error_red.svg',
                leaf       => \1,
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

    try {
        if( $config->{show_changes_in_tree} || !$p->{id_status} ) {
            for my $provider ( packages_that_do 'Baseliner::Role::LC::Changes' ) {
                #push @cs, $class;
                try {
                    my $prov = $provider->new( project=>$project );
                    my @changes = $prov->list( project=>$project, bl=>$bl, id_project=>$id_project, state_name=>$state_name );
                    _debug _loc("---- provider %1 has %2 changesets", $provider, scalar @changes);
                    push @cs, @changes;
                } catch {
                    my $err = shift;
                    my $msg = _loc('Error loading changes for provider %1: %2', $provider, $err);
                    _error( $msg );
                    push @tree, {
                        icon => '/static/images/icons/error.svg',
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
                    icon => '/static/images/icons/repo.svg',
                    draggable => \0,
                    text => $d->{name},
                    leaf => \1,
                    data => {
                        bl    => $bl,
                        name  => $d->{name},
                        repo_path  => $d->{repo_dir},
                        repo_mid   => $d->{mid},
                        collection => $d->{collection},
                        click => {
                            url   => '/lifecycle/repository',
                            type  => 'comp',
                            icon  => '/static/images/icons/repo.svg',
                            title => "$d->{name} - $bl",
                        }
                      }
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
        #my @topic_topic = mdb->master_rel->find({ to_mid=>mdb->in(map{$$_{mid}}@changes), rel_type=>'topic_topic' })->all;
        my @releases = map { $_->{id}} mdb->category->find({ is_release => mdb->true})->all;
        my @topic_topic = map { my $to_mid = $_->{mid}; map { {to_mid => $to_mid, from_mid => $_->{mid}} } ci->new($_->{mid})->parents( where => { collection => 'topic', 'id_category' => mdb->in(@releases) }, mids_only => 1, depth => 2 ) } @changes;
        my %rels = map{ $$_{mid}=>$_ }mdb->topic->find({ mid=>mdb->in(map{"$$_{from_mid}"}@topic_topic), is_release=>mdb->true })->all;
        my %releases;
        push @{ $releases{ $$_{to_mid} } } => $rels{$$_{from_mid}} for @topic_topic;

        $bind_releases = ci->status->find_one({ id_status=>''. $p->{id_status} })->{bind_releases};
        my %categories = mdb->category->find_hash_one( id=>{},{ workflow=>0, fields=>0, statuses=>0, _id=>0 });

        my @rels;
        my $rel_data = {};
        my %statuses = map { $_->{id_status} => $_->{name}} ci->status->find()->all;
        for my $topic (@changes) {
            my @releases = _array( $releases{ $topic->{mid} } );
            push @rels, @releases;  # slow! join me!

            # get the menus for the changeset
            my $topic_row = mdb->topic->find_one({ mid => "$topic->{mid}"});
            my ( $deployable, $promotable, $demotable, $menu );
            my %category_data;
            if ( ($topic->{_workflow} && $topic->{_workflow}->{$p->{id_status}}) || !$category_data{$topic_row->{id_category}}) {
                ( $deployable, $promotable, $demotable, $menu ) = $self->changeset_menu( $c, topic => $topic, bl_state => $bl, state_name => $state_name );
                $category_data{$topic_row->{id_category}} = { deployable => $deployable, promotable => $promotable, demotable => $demotable, menu => $menu};
            } else {
                $deployable = $category_data{$topic_row->{id_category}}{deployable};
                $promotable = $category_data{$topic_row->{id_category}}{promotable};
                $demotable = $category_data{$topic_row->{id_category}}{demotable};
                $menu = $category_data{$topic_row->{id_category}}{menu};
            };
            my $node = {
                url  => '/lifecycle/topic_contents',
                icon => '/static/images/icons/changeset_lc.svg',
                text => $topic->{title},
                leaf => \1,
                menu => $menu,
                topic_name => {
                    mid             => $topic->{mid},
                    category_color  => $topic->{category}->{color},
                    category_name   => _loc($topic->{category}->{name}),
                    category_status => "<b>(" . _loc($statuses{$topic_row->{id_category_status}}) . ")</b>",
                    is_release      => $topic->{category}->{is_release},
                    is_changeset    => $topic->{category}->{is_changeset},
                },
                data => {
                    ns           => 'changeset/' . $topic->{mid},
                    bl           => $bl,
                    name         => $topic->{title},
                    promotable   => $promotable,
                    is_release   => 0,
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
            for ( _array @releases ) {
                if ( !$rel_data->{$_->{mid}} ) {
                    $rel_data->{$_->{mid}} = { deployable => $deployable, promotable => $promotable, demotable => $demotable, menu => $menu};
                }
            }
            next if $bind_releases && @releases;
            push @tree, $node;
        }
        if( $bl ne "new" && @rels ) {
            my %unique = map { $_->{mid} => $_ } @rels;
            for my $rel ( values %unique ) {
                my $mid = $rel->{mid};
                my ( $deployable, $promotable, $demotable, $menu );
                if ( $rel_data->{$mid} ) {
                    $deployable = $rel_data->{$mid}{deployable};
                    $promotable = $rel_data->{$mid}{promotable};
                    $demotable = $rel_data->{$mid}{demotable};
                    $menu = $rel_data->{$mid}{menu};
                } else {
                    ( $deployable, $promotable, $demotable, $menu ) = $self->changeset_menu(
                        $c,
                        topic      => $rel,
                        bl_state   => $bl,
                        state_name => $state_name,
                        id_status_from  => $p->{id_status},
                        id_project => $id_project,
                        categories => \%categories,
                        is_release => 1
                    );
                }
                my @menu_release;
                for my $deploy ( _array($menu) ) {
                    $deploy->{eval}->{is_release} = 1;
                    push @menu_release, $deploy;
                }
                $menu = \@menu_release;
                #_warn $menu;
                my $node = {
                    url  => '/lifecycle/topic_contents',
                    icon => '/static/images/icons/release_lc.svg',
                    text => $rel->{title},
                    leaf => \0,
                    menu => $menu,
                    topic_name => {
                        mid             => $rel->{mid},
                        category_color  => $rel->{category}{color},
                        category_name   => $rel->{category}{name},
                        category_status => "<b>(" . _loc($statuses{$rel->{id_category_status}}) . ")</b>",
                        is_release      => \1,
                    },
                    data => {
                        ns           => 'changeset/' . $rel->{mid},
                        bl           => $bl,
                        name         => $rel->{title},
                        promotable   => $promotable,
                        demotable    => $demotable,
                        is_release   => 1,
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
    } catch {
        my $err = shift;
        my $msg = _loc('Error detected: %1', $err );
        _error( $msg );
        push @tree, {
            text => substr($msg,0,255),
            data => {},
            icon => '/static/images/icons/error_red.svg',
            leaf=>\1,
            expandable => \0
        };
    };
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub status_list {
    my $self = shift;
    my (%params) = @_;

    my $topic    = $params{topic}    || _fail 'topic required';
    my $username = $params{username} || _fail 'username required';
    my $dir      = $params{dir}      || _fail 'dir required';
    my $status   = $params{status}   || $topic->{category_status}->{id};
    my %statuses = $params{statuses} && ref $params{statuses} eq 'HASH' ? %{ $params{statuses} } : ci->status->statuses;

    my @user_roles = Baseliner::Model::Permissions->new->user_roles_ids( $username, topics => $topic->{mid} );

    my @user_workflow = _unique map { $_->{id_status_to} } Baseliner::Model::Topic->new->user_workflow(
        $username,
        categories  => [ $topic->{category}->{id} ],
        status_from => $status,
        topic_mid   => $topic->{mid}
    );

    my @workflow = Baseliner::Model::Topic->new->get_category_workflow(
        id_category => $topic->{category}->{id},
        username    => $username
    );

    my %seen;

    my @available_statuses;
    foreach my $workflow (@workflow) {
        next unless $workflow->{job_type} && $workflow->{job_type} eq $dir;
        next unless grep { $workflow->{id_role} eq $_ } @user_roles;

        next unless $workflow->{id_status_from} eq $status;

        next unless grep { $workflow->{id_status_to} eq $_ } @user_workflow;

        my $transition = join ',', ( map { $_ // '' } $workflow->{id_status_from}, $workflow->{id_status_to} );
        next if $seen{$transition}++;

        push @available_statuses, $statuses{ $workflow->{id_status_to} };
    }

    return sort { $a->{seq} <=> $b->{seq} } @available_statuses;
}

sub promotes_and_demotes {
    my ( $self, %p ) = @_;

    my ( $username, $topic, $id_status_from, $id_project, $job_mode ) = @p{ qw/username topic id_status_from id_project job_mode/ };

    my @topics = ($topic);

    if ( $topic->{category}->{is_release} ) {
        my $ci = ci->new( $topic->{mid} );

        my @changesets_mids = map { $_->{mid} } $ci->children(
            mids_only => 1,
            rel_type  => 'topic_topic',
            where     => { collection => 'topic', 'category.is_changeset' => '1' },
            depth     => 1
        );
        my @changesets = mdb->topic->find( { mid => mdb->in(@changesets_mids) }, { _txt => 0 } )->all;
        my %changesets_by_status = map { $_->{id_category_status} => $_ } @changesets;

        my ( $all_statics, $all_promotable, $all_demotable ) = ( {}, {}, {} );
        my ( $all_menu_s, $all_menu_p, $all_menu_d ) = ( [], [], [] );

        @topics = values %changesets_by_status;
    }

    my ( $all_statics, $all_promotable, $all_demotable ) = ( {}, {}, {} );
    my ( $all_menu_s, $all_menu_p, $all_menu_d ) = ( [], [], [] );
    my @all_transitions;

    foreach my $topic ( @topics ) {
        my ($maps, $transitions, $menus) = $self->_promotes_and_demotes(
            username       => $username,
            topic          => $topic,
            id_status_from => $id_status_from,
            id_project     => $id_project
        );

        my ( $statics, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = (@$maps, @$menus);

        $all_statics    = { %$all_statics,    %$statics };
        $all_promotable = { %$all_promotable, %$promotable };
        $all_demotable  = { %$all_demotable,  %$demotable };

        push @$all_menu_s, @$menu_s if $menu_s;
        push @$all_menu_p, @$menu_p if $menu_p;
        push @$all_menu_d, @$menu_d if $menu_d;

        push @all_transitions, @$transitions;
    }

    if ($job_mode) {
        return @all_transitions;
    }
    else {
        return ( $all_statics, $all_promotable, $all_demotable, $all_menu_s, $all_menu_p, $all_menu_d );
    }
}

sub _promotes_and_demotes {
    my ($self, %p ) = @_;

    my ( $username, $topic, $id_status_from, $id_project) = @p{ qw/username topic id_status_from id_project/ };

    $id_status_from //= $topic->{category_status}{id} // $topic->{id_category_status};
    my %statuses = ci->status->statuses;

    _fail _loc('Missing topic parameter') unless $topic;

    #Personalized _workflow!
    if ( $topic->{_workflow} && $topic->{_workflow}->{$id_status_from} ) {
        my @_workflow;
        my @user_workflow = _unique map { $_->{id_status_to} } Baseliner::Model::Topic->new->user_workflow($username);
        use Array::Utils qw(:all);

        @_workflow = map { _array( values $_ ) } $topic->{_workflow};

        my %final = map { $_ => 1 } intersect( @_workflow, @user_workflow );

        my @final_key = keys %final;
        map { my $st = $_; delete $statuses{$st} if !( $st ~~ @final_key ); } keys %statuses;
    }

    #end Personalized _workflow!

    my %bls = map { $$_{mid} => { bl => ( $$_{moniker} || $$_{bl} ), seq => $_->{seq} } } ci->bl->find->all;

    my ($cs_project) = ci->new( $topic->{mid} )->projects;
    my @project_bls = map { $_->{bl} } _array $cs_project->bls if $cs_project;

    my @maps;
    my @transitions;

    for my $job_type (qw/static promote demote/) {
        my ( $map, $transitions ) = $self->_build_transition(
            type           => $job_type,
            topic          => $topic,
            username       => $username,
            id_status_from => $id_status_from,
            bls            => \%bls,
            statuses       => \%statuses,
            project_bls    => \@project_bls,
        );

        push @maps, $map;

        push @transitions, [
            map {
                { %$_, id_project => $id_project }
            } @$transitions
        ];
    }

    my $icons = {
        static  => '/static/images/icons/arrow_right.svg',
        promote => '/static/images/icons/arrow_down_short.svg',
        demote  => '/static/images/icons/arrow_up_short.svg',
    };

    my @menus;
    foreach my $transition (@transitions) {
        push @menus, [
            map {
                {
                    text => $_->{text},
                    eval => {
                        id         => $_->{id},
                        job_type   => $_->{job_type},
                        id_project => $id_project,
                        url        => '/comp/lifecycle/deploy.js',

                    },
                    id_status_from => $_->{id_status_from},
                    icon           => $icons->{ $_->{job_type} }
                }
            } @$transition
        ];
    }

    return ( \@maps, [ map { @$_ } @transitions ], \@menus );
}

sub _build_transition {
    my $self = shift;
    my (%params) = @_;

    my $type           = $params{type};
    my $topic          = $params{topic};
    my $username       = $params{username};
    my $id_status_from = $params{id_status_from};
    my $statuses       = $params{statuses};
    my $bls            = $params{bls};
    my $project_bls    = $params{project_bls};
    my $id_project     = $params{id_project};

    my @statuses = $self->status_list(
        dir      => $type,
        topic    => $topic,
        username => $username,
        status   => $id_status_from,
        statuses => $statuses
    );

    my $map         = {};
    my $transitions = [];

    for my $status (@statuses) {
        my @bls;

        my $bl_to;
        if ($type eq 'demote') {
            @bls = _array $statuses->{$id_status_from}{bls};
            ($bl_to) = _array $statuses->{ $status->{id_status} }{bls};
            $bl_to = $bls->{$bl_to}->{bl};
        }
        else {
            @bls = _array $status->{bls};
        }

        for my $bl ( map { $_->{bl} } sort { $a->{seq} <=> $b->{seq} } map { $bls->{$_} } @bls ) {
            if ( !@$project_bls || $bl ~~ @$project_bls ) {
                my $id = substr($type, 0, 1) . $bl . $status->{id_status};

                $map->{$id} = \1;

                my $text = {
                    static  => _loc( 'Deploy to %1 (%2)',      _loc( $status->{name} ), $bl ),
                    promote => _loc( 'Promote to %1 (%2)',     _loc( $status->{name} ), $bl ),
                    demote  => _loc( 'Demote to %1 (from %2)', _loc( $status->{name} ), $bl ),
                };

                push @$transitions,
                  {
                    id             => $id,
                    bl_to          => $bl_to // $bl,
                    job_type       => $type,
                    job_bl         => $bl,
                    id_project     => $id_project,
                    is_release     => $topic->{category}->{is_release},
                    status_to      => $status->{id_status},
                    status_to_name => _loc( $status->{name} ),
                    id_status_from => $id_status_from,
                    text           => $text->{$type}
                  };
            }
        }
    }

    return ($map, $transitions);
}

sub job_transitions : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $topic_projects = Util->_decode_json($p->{topics});

    #_warn $topic_projects;

    my %categories = mdb->category->find_hash_one( id=>{},{ workflow=>0, fields=>0, statuses=>0, _id=>0 });

    my @promotes_and_demotes;
    my $cont=0;
    for my $topic_project ( _array $topic_projects ) {
        my ( $topic_mid, $project_mid, $id_status_from ) = ($topic_project->{topic_mid}, $topic_project->{project}, $topic_project->{state});

        $project_mid = '' if ( $project_mid eq 'all' );

        my $topic = mdb->topic->find_one({ mid => "$topic_mid"},{ _txt => 0});
        my $id_project = $project_mid;

        my $username = $c->username;
        my @topic_transitions;
        my @topic_transitions_keys;

        try {
            @topic_transitions = $self->promotes_and_demotes(
                topic          => $topic,
                username       => $username,
                id_status_from => $id_status_from,
                id_project     => $id_project,
                job_mode       => 1
            );
            @topic_transitions_keys = map {$_->{id}} @topic_transitions;
        } catch {
            my $error = shift;

            _warn sprintf 'Error building transitions for topic `%s`: %s', $topic_project->{topic_mid}, $error;
        };

        if ( $cont ) {
            @promotes_and_demotes = grep { $_->{id} ~~ @topic_transitions_keys } @promotes_and_demotes;
        } else {
            $cont++;
            @promotes_and_demotes = @topic_transitions;
        }
    }
    $c->stash->{ json } = { data => \@promotes_and_demotes, totalCount => scalar @promotes_and_demotes};
    $c->forward('View::JSON');
}

sub changeset_menu {
    my ($self, $c, %p ) = @_;
    my ( $topic, $bl_state, $state_name, $id_status_from, $id_project, $categories ) = @p{ qw/topic bl_state state_name id_status_from id_project categories/ };

    my $username = $c->username;

    my @menu = $self->menu_related();

    my ( $deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = $self->promotes_and_demotes(
        username       => $username,
        topic          => $topic,
        id_project     => $id_project,
        id_status_from => $id_status_from
    );

    push @menu, @$menu_s, @$menu_p, @$menu_d;

    return ( $deployable, $promotable, $demotable, \@menu );
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
    my $repo_type = $p->{repo_type};
    my $bl = $p->{bl};
    my $repo_path = $p->{repo_path};
    my $path = $p->{path} // '';
    length $path and $path = "$path/";
    my @ls;
    my @res;
    if($repo_type eq 'PlasticRepository'){
        my $cmd = "cm find \"labels where name='$bl' on repository '$repo_path'\" --format={changeset} --nototal";
        my $out = `$cmd`;
        $out =~ s/\s//;
        my $tag_sha = $out;
        if($tag_sha){
            my $cmd = "cm ls $p->{path} --tree=$tag_sha\@$repo_path --format={fullpath}#-#{revid}#-#{changeset}#-#{itemid}#-#{type}#-#{size}#-#{name}";
            my @all_files = `$cmd`;
            map { my @parts = split '#-#',$_;
                  my $name = $parts[6];
                  $name =~ s/\n//;
                  my $type = $parts[4];
                  push @res, {path=>$parts[0], item=>$parts[6], size=>$parts[5], version=>$parts[2], leaf=>($type ne 'dir' ? \1 : \0 )} if !($name eq '.' and $type eq 'dir')
            } @all_files;
        }
    }elsif($repo_type eq 'GitRepository'){
        my $g = Girl::Repo->new( path=>"$repo_path" );
        @ls = $g->git->exec( 'ls-tree', '-l', $p->{bl}, $path );
        my $cnt = 100;
        @res = grep { defined }
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
                    bl      => $p->{bl},
                    leaf    => ( $type eq 'blob' ? \1 : \0 )
                }
                : undef
        } @ls;
    }
    my $cnt = 100;
    $c->stash->{json} = [
        @res
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
    my $repo_type = $p->{repo_type};
    my $res = { pane => $pane };
    if($repo_type eq 'PlasticRepository'){
    }else{
        # TODO separate concerns, put this in Git Repo provider
        #      Baseliner::Repo->new( 'git:repo@tag:file' )
        my $g = Girl::Repo->new( path=>"$repo_path" );
        if( $pane eq 'hist' ) {
            my @log = $g->git->exec( 'log', '--pretty=oneline', '--decorate', $ref, '--', $path );
            my @formatted_log;
            for my $data (@log) {
                my $rev_data = {};
                my $commit;
                my $revs;
                my $author;
                my $date;
                my @log_data;
                try{
                    $data =~ /^(.+?)\s\(.*?\)\s(.*)$/;
                    $commit = $1;
                    $revs = $2;
                    @log_data = $g->git->exec( 'rev-list', '--pretty', $commit );
                }catch{
                    $data =~ /^(.+?)\s(.*)$/;
                    $commit = $1;
                    $revs = $2;
                    @log_data = $g->git->exec( 'rev-list', '--pretty', $commit );
                }

                map {
                    if ( $data =~ /^Author:\s(.*)$/ ) {
                        $author = $1;
                    }
                    if ( $data =~ /^Date:\s(.*)$/ ) {
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
    }
    $c->stash->{json} = $res;
    $c->forward('View::JSON');
}

sub tree : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    try {
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
    } catch {
        my $err = shift;
        my $msg = _loc('Error detected: %1', $err );
        _error( $msg );
        $c->stash->{json} = [{
            text => substr($msg,0,255),
            data => {},
            icon => '/static/images/icons/error_red.svg',
            leaf=>\1,
            expandable => \0
        }];
    };
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
    my ( $self, $c ) = @_;

    my $p = $c->req->params;
    my $user = $c->user_ci;

    $self->filter_user_favorites($user);

    my $tree = Baseliner::Model::Favorites->new->get_children( $user, $p->{id_folder} );

    my @nodes;
    for my $node (@$tree) {
        delete $node->{menu} if !$node->{menu};
        $node->{leaf} = \1 if !$node->{url};
        push @nodes, $node;
    }

    $c->stash->{json} = \@nodes;
    $c->forward( 'View::JSON' );
}

sub filter_user_favorites {
    my ($self,$user_ci) = @_;

    my @fav_user = $user_ci->{favorites};
    for my $item ( @fav_user ) {
        for my $node (keys $item){
            my @keys_data = keys $item->{$node}{data} if $item->{$node}{data};
            foreach my $k (@keys_data){
                if( $k =~ /^id/ ){
                    if($k eq "id_status"){
                        try{
                            ci->status->find_one({id_status =>$k});
                        }catch{
                            delete $user_ci->{favorites}->{$node};
                        }
                    }else{
                        try{
                            ci->new($item->{$node}->{data}->{$k});
                        }catch{
                            delete $user_ci->{favorites}->{$node};
                        }
                    }
                }
            }
        }
    }
    $user_ci->save;
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
        $node->{icon} //= '/static/images/icons/connected.svg';
        push @tree, $node;
    }
    $c->stash->{json} = \@tree;
}

sub favorite_add : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    my $user = $c->user_ci;

    $c->stash->{json} = try {
        my $favorite = Baseliner::Model::Favorites->new->add_favorite_item(
            $user,
            {   text      => $p->{text},
                url       => $p->{url},
                icon      => $p->{icon},
                menu      => $p->{menu},
                data      => $p->{data},
                is_folder => $p->{is_folder},
            }
        );

        cache->remove( { d => "ci", mid => $user->{mid} } );

        {   success     => \1,
            msg         => _loc("Favorite added ok"),
            id_favorite => $favorite->{id_favorite},
            id_folder   => $favorite->{id_folder} // '',
            position    => $favorite->{position}
        }
    }
    catch {
        { success => \0, msg => shift() }
    };

    $c->forward('View::JSON');
}

sub favorite_del : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    $c->stash->{json} = try {
        my $user = $c->user_ci;

        Baseliner::Model::Favorites->new->delete_nodes( $user, $p->{id_favorite}, $p->{id_parent});

        cache->remove( { d => "ci", mid => $user->{mid} } );

        { success => \1, msg => _loc("Favorite removed ok") }
    }
    catch {
        { success => \0, msg => shift() }
    };
    $c->forward('View::JSON');
}

sub favorite_rename : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    $c->stash->{json} = try {
        _fail _loc("Invalid name") unless length $p->{text};

        my $user = $c->user_ci;

        Baseliner::Model::Favorites->new->rename_favorite( $user, $p->{id_favorite}, $p->{text} );

        { success => \1, msg => _loc("Favorite renamed ok") }
    }
    catch {
        { success => \0, msg => shift() }
    };
    $c->forward('View::JSON');
}


sub favorite_add_to_folder : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    my $id_favorite   = $p->{id_favorite};
    my $id_parent     = $p->{id_parent} // '';
    my $action        = $p->{action} // '';
    my $nodes_ordered = $p->{nodes_ordered} ? _decode_json( $p->{nodes_ordered} ) : '';

    my $user = $c->user_ci;

    cache->remove( { d => "ci", mid => $user->mid } );

    $c->stash->{json} = try {
        Baseliner::Model::Favorites->new->update_position(
            $user,
            $id_favorite,
            $id_parent,
            action        => $action,
            nodes_ordered => $nodes_ordered
        );
        { success => \1, msg => _loc("Favorite moved ok") }
    }
    catch {
        { success => \0, msg => shift() }
    };

    cache->remove( { d => "ci", mid => $user->mid } );

    $c->forward('View::JSON');
}


sub click_for_topic {
    my ($self, $catname, $mid ) = @_;
    +{
        url   => sprintf('/topic/view?topic_mid='.$mid),
        type  => 'comp',
        icon  => '/static/images/icons/topic.svg',
        title => sprintf( "%s #%d", _loc($catname), $mid ),
    };
}

sub click_category {
    my ($self, $catname, $id ) = @_;
    +{
        url   => sprintf("/topic/grid?category_id=".$id),
        type  => 'comp',
        icon  => '/static/images/icons/topic.svg',
        title => sprintf( "%s #%d", _loc($catname), $id ),
    };
}

sub build_topic_tree {
    my $self         = shift;
    my %p            = @_;
    my @menu_related = $self->menu_related();
    my $category     = $p{category} // $p{topic}{category} // $p{topic}{categories};
    my $topic_title  = $p{topic}{title};
    my @tree;

    push @tree,
        {
        text     => $topic_title,
        calevent => {
            mid    => $p{mid},
            color  => $category->{color},
            title  => $topic_title,
            allDay => \1
        },
        url        => '/lifecycle/tree_topic_get_files',
        topic_name => {
            mid            => $p{mid},
            category_color => $category->{color},
            category_name  => _loc( $category->{name} ),
            is_release     => $p{is_release} // $category->{is_release},
            is_changeset   => $p{is_changeset} // $category->{is_changeset},
        },
        moniker => ( $p{moniker} || Util->_name_to_id($topic_title) ),
        data => {
            topic_mid => $p{mid},
            click     => $self->click_for_topic( $category->{name}, $p{mid} )
        },
        icon => $p{icon} // q{/static/images/icons/topic.svg},
        leaf => \0,
        expandable => \0,
        menu       => \@menu_related
        };
    my @files = mdb->joins(
        master_rel => { from_mid => $p{mid}, rel_type => 'topic_asset' },
        to_mid => mid => master_doc => [ {}, { fields => { yaml => 0 } } ]
    );

    if (@files) {
        $tree[0]->{children} = [
            {   text    => _loc('Files'),
                iconCls => 'default_folders',
                url     => '/lifecycle/tree_topic_get_files',
                leaf    => \0,
                data    => {
                    id_topic     => $p{mid},
                    sw_get_files => \1
                },
            }
        ];
    }
    return @tree;
}

sub topics_for_release : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $depth = -1;

    if($p->{id_report}){
        $depth = ci->report->find_one({ mid => $p->{id_report} })->{recursivelevel} // "2"
    }

    my @cis = ci->new($p->{id_release})->children( mids_only => 1, rel_type => 'topic_topic', where => { collection => 'topic'}, depth => $depth);

    my @topics = _unique map { $_->{mid} } @cis;
    push @topics, $p->{id_release};

    $c->stash->{json} = { success=>\1, topics=>\@topics };
    $c->forward('View::JSON');
}

sub menu_related {
    my ($self, $mid ) = @_;
    my @menu;
        push @menu, {  text => _loc('Related'),
                        icon => '/static/images/icons/topic.svg',
                        eval => {
                            handler => 'Baseliner.open_topic_grid_from_release'
                        }
                    };
        push @menu, {  text => _loc('Apply filter'),
                        icon => '/static/images/icons/topic.svg',
                        eval => {
                            handler => 'Baseliner.open_apply_filter_from_release'
                        }

                    };
    return @menu;
}

sub repository_details : Local {
    my ( $self, $c ) = @_;

    my $p   = $c->req->params;
    my $mid = $p->{mid};
    my $ci  = ci->new($mid);

    $c->stash->{json} = {
        success       => \1,
        name          => $ci->name,
        mid           => $ci->mid,
        repo_dir      => $ci->repo_dir,
        description   => $ci->description,
        collection    => $ci->collection,
    };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
