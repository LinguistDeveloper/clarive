package BaselinerX::LcController;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = 'lifecycle';

sub tree_projects : Local {
    my ($self,$c) = @_;
    my @tree;
    my @projects = Baseliner->model('Permissions')->all_projects();
    for my $id (@projects) {
        my $project = Baseliner->model('Baseliner::BaliProject')->find($id);
        push @tree, {
            text       => $project->name,
            url        => '/lifecycle/tree_project',
            data       => {
                id_project => $id,
                project    => $project->name,
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
        my $type = $node->{type};
        push @tree, {
            #id         => $node->{type} . ':' . $id,
            text       => _loc( $node->{node} ),
            url        => '/lifecycle/changeset',
            icon       => $node->{icon},
            data       => {
                project    => $project,
                id_project => $id_project,
                bl         => $node->{bl},
            },
            leaf       => \0,
            expandable => \0
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
        push @cs, $prov->list( project=>$project, bl=>$bl, id_project=>$id_project );
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

    my $query = $c->req->params->{query};
    my $node = $c->req->params->{node};

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
    $c->forward( 'View::JSON' );
}

1;
