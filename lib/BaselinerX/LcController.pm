package BaselinerX::LcController;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = 'lifecycle';

register 'action.project.see_lc' => { name => 'User can access the project lifecycle' };

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
                       #sw_get_files =>\1
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
    my @rels = grep {!$seen{$_->{mid}}++} DB->BaliProject->find( $c->req->params->{id_project} )->releases->search(undef,{ prefetch=>['categories'] })->hashref->all;
    my @menu_related = $self->menu_related();
    my @tree = map {
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.png',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid},
                category_color => $_->{categories}{color},
                category_name  => $_->{categories}{name},
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{categories}{name}, $_->{mid} ),
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
    my @rels = grep {!$seen{$_->{mid}}++} DB->BaliTopic->search( { id_category => $c->req->params->{category_id} },{ prefetch=>['categories'] })->hashref->all;
    my @menu_related = $self->menu_related();
    my @tree = map {
       +{
            text => $_->{title},
            icon => '/static/images/icons/release.png',
            url  => '/lifecycle/topic_contents',
            topic_name => {
                mid            => $_->{mid},
                category_color => $_->{categories}{color},
                category_name  => $_->{categories}{name},
                is_release     => 1,
            },
            data => {
                topic_mid    => $_->{mid},
                click       => $self->click_for_topic(  $_->{categories}{name}, $_->{mid} ),
            },
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
        order_by=>{-desc=>'from_mid'} );

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

sub tree_topics_project : Local {
    my ($self,$c) = @_;
    my @tree;

    my $project = $c->req->params->{project} ;
    my $id_project = $c->req->params->{id_project} ;
    my @categories  = map { $_->{id}} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'view' );
    my @topics = DB->BaliMasterRel->search(
        { to_mid => $id_project, 'categories.id' => \@categories, rownum => {'<=',30}, -not => ['status.type' => { -like => 'F%' }] },
        { prefetch => {'topic_project'=> ['categories','status']}, order_by => { -desc => 'modified_on'} }
    )->hashref->all;
    for( @topics ) {
        my $is_release = $_->{topic_project}{categories}{is_release};
        next if $c->stash->{release_only} && ! $is_release;
        my $is_changeset = $_->{topic_project}{categories}{is_changeset};
        my $icon = $is_release ? '/static/images/icons/release_lc.png'
            : $is_changeset ? '/static/images/icons/changeset_lc.png' :'/static/images/icons/topic.png' ;
        push @tree,
            $self->build_topic_tree( 
                mid      => $_->{from_mid},
                topic    => $_->{topic_project},
                icon     => $icon,
                is_release => $is_release,
                is_changeset => $is_changeset,
            );
    }

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub topic_contents : Local {
    my ($self,$c) = @_;
    my @tree;
    my $topic_mid = $c->req->params->{topic_mid};
    my $state = $c->req->params->{state_id};
    my $where = { from_mid => $topic_mid };

    if ( $state ) {
        $where->{'topic_topic2.id_category_status'} = $state;
    }

    my @topics = $c->model('Baseliner::BaliMasterRel')->search(
        $where,
        { prefetch => {'topic_topic2'=>'categories'} }
    )->hashref->all;
    for ( @topics ) {
        my $is_release = $_->{topic_topic2}{categories}{is_release};
        my $is_changeset = $_->{topic_topic2}{categories}{is_changeset};
        my $icon = $is_release ? '/static/images/icons/release_lc.png'
            : $is_changeset ? '/static/images/icons/changeset_lc.png' :'/static/images/icons/topic.png' ;

        my @menu_related = $self->menu_related();
        push @tree, {
            text       => $_->{topic_topic2}{title},
            topic_name => {
                mid             => $_->{topic_topic2}{mid},
                category_color  => $_->{topic_topic2}{categories}{color},
                category_name   => _loc($_->{topic_topic2}{categories}{name}),
                is_release      => $is_release,
                is_changeset    => $is_changeset,
            },
            url        => '/lifecycle/tree_topic_get_files',
            data       => {
               topic_mid   => $_->{to_mid},
               click       => $self->click_for_topic(  $_->{topic_topic2}{categories}{name}, $_->{topic_topic2}{mid} ),
            },
            icon       => $icon, 
            leaf       => \1,
            expandable => \1,
            menu => \@menu_related
        };
    }

    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub tree_releases : Local {
    my ($self,$c) = @_;
    my %seen = ();
    my @rels = DB->BaliTopicCategories->search( {is_release => 1} )->hashref->all;
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
    my $where = { active=> 1, id_parent=>[undef,''] };
    if( ! $c->is_root ){ 
        $where->{'exists'} =  $c->model( 'Permissions' )->user_projects_query( username=>$c->username, join_id=>'mid' );
    }

    my $rs = Baseliner->model('Baseliner::BaliProject')->search( 
        $where ,
        { order_by => { -asc => \'lower(name)' } } );
    my %projects;
    my @project_ids = map { $_->{mid} } DB->BaliMaster->search( {collection => 'project'} )->hashref->all;

    map { $projects{$_} = 1 } @project_ids;

    while( my $r = $rs->next ) {
        if ( $projects{$r->mid} ) {            
            push @tree, {
                text       => $r->name,
                url        => '/lifecycle/tree_project',
                data       => {
                    id_project => $r->mid,
                    project    => $r->name,
                    click => {
                        url   => '/dashboard/list/project',
                        type  => 'html',
                        icon  => '/static/images/icons/project.png',
                        title => $r->name,
                    }               
                },
                icon       => '/static/images/icons/project.png',
                leaf       => \0,
                expandable => \1
                };
        }
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
            leaf       => \0,
            expandable => \0
        };
    }

    # get sub projects TODO make this recurse over the previous controller (or into a model)
    my $rs_prj = $c->model('Baseliner::BaliProject')->search({ id_parent=>$id_project, active=>1 });
    while( my $r = $rs_prj->next ) {
        my $name = $r->nature ? sprintf("%s (%s)", _loc($r->name), $r->nature) : _loc($r->name);
        push @tree, {
            text       => $name,
            url        => '/lifecycle/tree_project',
            data       => {
                id_project => $r->mid,
                project    => _loc($r->name),
            },
            icon       => '/static/images/icons/project.png',
            leaf       => \0,
            expandable => \1
        };
    }
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

        my $repo = Baseliner::CI->new( $id_repo );

        my @changes = $repo->list_branches( project=>$project );
        _debug _loc "---- provider ".$repo->name." has %1 changesets", scalar @changes;
        push @cs, @changes;

        # loop through the changeset objects (such as BaselinerX::GitChangeset)
        for my $cs ( @cs ) {
            my $menu = [];
            # get menu extensions (find packages that do)
            # get node menu
            ref $cs->node_menu and push @$menu, _array $cs->node_menu;
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
    }

    # ## add what's in this baseline 
    # my @repos = BaselinerX::Lc->new->project_repos( project=>$project );
    # # ( Girl::Repo->new( path=>"$path" ), $rev, $project );

    # push @tree, {
    #     url  => '/lifecycle/repo',
    #     icon => '/static/images/icons/repo.gif',
    #     text => $_->{name},
    #     leaf => \1,
    #     data => {
    #         bl    => $bl,
    #         name  => $_->{name},
    #         repo_path  => $_->{path},
    #         click => {
    #             url   => '/lifecycle/repo',
    #             type  => 'comp',
    #             icon  => '/static/images/icons/repo.gif',
    #             title => "$_->{name} - $bl",
    #         }
    #       },
    # } for @repos;

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

    my $config = config_get 'config.lc';
    # provider-by-provider:
    # get all the changes for this project + baseline
    my @cs;

    if( $config->{show_changes_in_tree} || !$p->{id_status} ) { 
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

    # topic changes
    my $where = { is_changeset => 1, rel_type=>'topic_project', to_mid=>$id_project };
    my @changes;
    my $bind_releases = 0;
    $where->{id_category_status} = $p->{id_status};
    @changes = DB->BaliTopic->search(
        $where,
        { prefetch=>['categories','children','master'] }
    )->all;
    $bind_releases = DB->BaliTopicStatus->find( $p->{id_status} )->bind_releases;

    my @rels;
    for my $topic (@changes) {
        my @releases = $topic->my_releases->hashref->all;
        push @rels, @releases;  # slow! join me!
        next if $bind_releases && @releases;
        my $td = { $topic->get_columns() };  # TODO no prefetch comes thru
        # get the menus for the changeset
        my ( $deployable, $promotable, $demotable, $menu ) = $self->cs_menu( $c, $td, $bl, $state_name );
        my $node = {
            url  => '/lifecycle/topic_contents',
            icon => '/static/images/icons/changeset_lc.png',
            text => $td->{title},
            leaf => \1,
            menu => $menu,
            topic_name => {
                mid             => $td->{mid},
                category_color  => $topic->categories->color,
                category_name   => _loc($topic->categories->name),
                is_release      => $topic->categories->is_release,
                is_changeset    => $topic->categories->is_changeset,
            },
            data => {
                ns           => 'changeset/' . $td->{mid},
                bl           => $bl,
                name         => $td->{title},
                promotable   => $promotable,
                demotable    => $demotable,
                deployable   => $deployable,
                state_name   => _loc($state_name),
                topic_mid    => $td->{mid},
                topic_status => $td->{id_category_status},
                click        => $self->click_for_topic(  _loc($topic->categories->name), $td->{mid} )
            },
        };
        # push @tree, $node if ! @rels;
        push @tree, $node;
    }
    if( $bl ne "new" && @rels ) {
        my %unique = map { $_->{topic_topic}{mid} => $_ } @rels;
        for my $rel ( values %unique ) {
            $rel = $rel->{topic_topic};
            my ( $deployable, $promotable, $demotable, $menu ) = $self->cs_menu( $c, $rel, $bl, $state_name, $p->{id_status} );
            my $node = {
                url  => '/lifecycle/topic_contents',
                icon => '/static/images/icons/release_lc.png',
                text => $rel->{title},
                leaf => \0,
                menu => $menu,
                topic_name => {
                    mid             => $rel->{mid},
                    category_color  => $rel->{categories}{color},
                    category_name   => $rel->{categories}{name},
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
                    state_id     => $p->{id_status},
                    topic_mid    => $rel->{mid},
                    topic_status => $rel->{id_category_status},
                    click        => $self->click_for_topic(  _loc($rel->{categories}{name}), $rel->{mid} )
                },
            };
            push @tree, $node;
        }
    }
    $c->stash->{ json } = \@tree;
    $c->forward( 'View::JSON' );
}

sub promotes_and_demotes {
    my ($self, $c, $topic, $bl_state, $state_name, $id_status_from ) = @_;
    my ( @menu_s, @menu_p, @menu_d );


    _debug( "Buscando deploys, promotes y demotes para el estado $id_status_from");

    my $id_status_from_lc = $id_status_from ? $id_status_from: $topic->{id_category_status};
    my @user_workflow = _unique map {$_->{id_status_to} } Baseliner->model("Topic")->user_workflow( $c->username );

    # Static
    my @status_from = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        { id_status_to => \@user_workflow, id_category => $topic->{id_category}, id_status_from => $id_status_from_lc, job_type => 'static', username => $c->username },
        {   join     => [ 'statuses_from', 'statuses_to', 'user_role' ],
            distinct => 1,
            +select  => [qw/statuses_to.bl statuses_to.name statuses_to.id statuses_from.bl statuses_to.seq/],
            order_by => { -asc => 'statuses_to.seq' }
        }
    )->hashref->all;

    my $deployable={};
    for my $status ( @status_from ) {
        my ($ci_status) = BaselinerX::CI::status->query( { id_status => ''.$status->{statuses_to}{id}, name => $status->{statuses_to}{name} } );

        for my $bl ( _array $ci_status->{bls} ) {        
            $deployable->{ $bl->{bl} } = \1;
            push @menu_s, {
                text => _loc( 'Deploy to %1 (%2)', _loc( $status->{statuses_to}{name} ), $bl->{bl} ),
                eval => {
                    url      => '/comp/lifecycle/deploy.js',
                    title    => 'Deploy',
                    job_type => 'static',
                    bl_to => $bl->{bl},
                    status_to => $status->{statuses_to}{id},
                    status_to_name => _loc($status->{statuses_to}{name}),
                },
                id_status_from => $id_status_from_lc,
                icon => '/static/images/silk/arrow_right.gif'
            };
        }
    }

    # Promote
    my @status_to = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        { id_status_to => \@user_workflow, id_category => $topic->{id_category}, id_status_from => $id_status_from_lc, job_type => 'promote' , username => $c->username },
        {   join     => [ 'statuses_from', 'statuses_to', 'user_role' ],
            distinct => 1,
            +select  => [qw/statuses_to.bl statuses_to.name statuses_to.id statuses_to.seq/],
            order_by => { -asc => 'statuses_to.seq' }
        }
    )->hashref->all;

    my $promotable={};
    for my $status ( @status_to ) {
        my ($ci_status) = BaselinerX::CI::status->query( { id_status => ''.$status->{statuses_to}{id}, name => $status->{statuses_to}{name} } );

        for my $bl ( _array $ci_status->{bls} ) {        
            $promotable->{ $bl->{bl} } = \1;
            push @menu_p, {
                text => _loc( 'Promote to %1 (%2)', _loc( $status->{statuses_to}{name} ), $bl->{bl} ),
                eval => {
                    url      => '/comp/lifecycle/deploy.js',
                    title    => 'To Promote',
                    job_type => 'promote',
                    bl_to => $bl->{bl},
                    status_to => $status->{statuses_to}{id},
                    status_to_name => _loc($status->{statuses_to}{name}),
                },
                id_status_from => $id_status_from_lc,
                icon => '/static/images/silk/arrow_down.gif'
            };
        }
    }

    # Demote
    @status_from = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        { id_status_to => \@user_workflow, id_category => $topic->{id_category}, id_status_from => $id_status_from_lc, job_type => 'demote' , username => $c->username },
        {   join     => [ 'statuses_from', 'statuses_to', 'user_role' ],
            distinct => 1,
            +select  => [qw/statuses_to.bl statuses_to.name statuses_to.id statuses_from.bl statuses_to.seq/],
            order_by => { -asc => 'statuses_to.seq' }
        }
    )->hashref->all;

    my $demotable={};
    for my $status ( @status_from ) {
        $demotable->{ $status->{statuses_from}{bl} } = \1;
        push @menu_d, {
            text => _loc( 'Demote to %1', _loc( $status->{statuses_to}{name} ) ),
            eval => {
                url      => '/comp/lifecycle/deploy.js',
                title    => 'Demote',
                job_type => 'demote',
                bl_to => $status->{statuses_from}{bl},
                status_to => $status->{statuses_to}{id},
                status_to_name => _loc($status->{statuses_to}{name}),
            },
            id_status_from => $id_status_from_lc,
            icon => '/static/images/silk/arrow_up.gif'
        };
    }
    return ( $deployable, $promotable, $demotable, \@menu_s, \@menu_p, \@menu_d );
}

sub cs_menu {
    my ($self, $c, $topic, $bl_state, $state_name, $id_status_from ) = @_;
    #return [] if $bl_state eq '*';
    my ( @menu, @menu_s, @menu_p, @menu_d );
    my $sha = ''; #try { $self->head->{commit}->id } catch {''};
    _log 'Generando menu';

    push @menu, $self->menu_related();

    my ($deployable, $promotable, $demotable ) = ( {}, {}, {} );
    my $row = DB->BaliTopicCategories->find( $topic->{id_category} );
    if( $row->is_release ) {
        # my @chi = DB->BaliTopic->search({ rel_type=>'topic_topic', from_mid=>$topic->{mid}, },
        #    { join=>['parents'] })->hashref->all;
        my @chi;

        for ( ci->new($topic->{mid})->children( isa => 'topic') ) {
            push @chi, $_ if DB->BaliTopicCategories->find($_->{id_category})->is_changeset
        };
        
        if( @chi ) {
           my ($menu_s, $menu_p, $menu_d );
           ($deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = $self->promotes_and_demotes( $c, $chi[0], $bl_state, $state_name );
           push @menu_s, _array( $menu_s );
           push @menu_p, _array( $menu_p );
           push @menu_d, _array( $menu_d );
        }
    } else {
       my ($menu_s, $menu_p, $menu_d );
       ($deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = $self->promotes_and_demotes( $c, $topic, $bl_state, $state_name );
       push @menu_s, _array( $menu_s );
       push @menu_p, _array( $menu_p );
       push @menu_d, _array( $menu_d );       
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

    #my @projects = Baseliner->model('Permissions')->user_projects_with_action(
        #username=>$c->username, action=>'' 
    #);
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

    return +{
        text     => $p{topic}{title},
        calevent => {
            mid    => $p{mid},
            color  => $p{topic}{categories}{color},
            title  => $p{topic}{title},
            allDay => \1
        },
        url        => '/lifecycle/tree_topic_get_files',
        topic_name => {
            mid            => $p{mid},
            category_color => $p{topic}{categories}{color},
            category_name  => _loc($p{topic}{categories}{name}),
            is_release     => $p{is_release} // $p{topic}{categories}{is_release},
            is_changeset   => $p{is_changeset} // $p{topic}{categories}{is_changeset},
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
            click     => $self->click_for_topic( $p{topic}{categories}{name}, $p{mid} )
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

    my @cis = _ci($p->{id_release})->children( rel_type => "topic_topic", depth => -1);

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
