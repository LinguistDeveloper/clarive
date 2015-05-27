package BaselinerX::Lc;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

register 'config.lc' => {
    metadata => [
        { id=>'show_changes_in_tree', label=>'Show provider tags in the Lifecycle tree', default=>'0' },
    ]
};

has 'lc' => (
    is      => 'rw',
    isa     => 'Any',
    lazy    => 1,
    default => sub {
        # loads the lc.yaml file on initialization
        my $feature = Baseliner->features->find( file => __FILE__ );
        my $file = _file( $feature->root, '..', 'etc', 'lc.yaml' );    # TODO to config
        if( ! -e $file ) {
            return {};
            my $tfile = _file( $feature->root, '..', 'etc', 'lc.yaml.example' ); 
            File::Copy::copy( $tfile, $file );
        }
        open my $ff, '<:encoding(UTF-8)', "$file" or _throw _loc "Error loading file %1: %2", $file, $!;
        my $fi = join '', <$ff>;
        utf8::downgrade( $fi );
        my $lc = _load( $fi ); 
        close $ff;
        # now from config
        my $ch = Baseliner->config->{lifecycle} || {};
        #_log "CH=================" . _dump $ch;
        return +{ %$lc, %$ch };
    }
);

has 'state_data' => qw(is rw isa HashRef lazy 1), 
    default => sub{
        my $self = shift;
        my $lc = $self->lc;
        my $states = $lc->{lifecycle}->{default}->{states};
        my $state_data = {};
        for my $state ( _array $states ) {
            my $state_name = $state->{name} // $state->{node}  ;
            $state_data->{ $state_name }->{bl} = $state->{bl};
            $state_data->{ $state_name }->{bl_to} = $state->{bl_to};
            $state_data->{ $state_name }->{bl_from} = $state->{bl_from};
            $state_data->{ $state_name }->{show_branch} = $state->{show_branch};
        }
        return $state_data;
    };

sub lc_for_project {
    my ($self, $id_prj, $name_prj, $username) = @_;
    #my $lc = $self->lc;
    #_log "LC==========> $lc , " . ref $lc;
    #my $nodes = $lc->{nodes}; $ch ||= {
    my @nodes = (
          {
            node => 'Topics',
            icon => '/static/images/icons/topic.png',
            url => '/lifecycle/tree_topics_project',
            has_query => 1,
            data => {
                        'click' => {
                                     'icon' => '/static/images/icons/topic.png',
                                     'url' => '/topic/grid',
                                     'title' => $name_prj,
                                     'type' => 'comp'
                                   }
                      },
            type => 'component',
          },
          {
            node => 'Releases',
            icon => '/static/images/icons/release_explorer.png',
            url => '/lifecycle/tree_project_releases',
            type => 'component',
            has_query => 1,
          }
    );
    push @nodes,
    {
        node => 'Dashboards',
        icon => '/static/images/icons/dashboard.png',
        url => '/dashboard/dashboard_list',
        has_query => 1,
        type => 'component'
    };
    my $is_root = Baseliner->model('Permissions')->is_root($username);
    my $has_permission = Baseliner->model('Permissions')->user_has_action( username=> $username, action=>'action.job.monitor' );
    if ($has_permission || $is_root){

        push @nodes, {
            'node' => 'Jobs',
            'icon' => '/static/images/icons/job.png',
            'url' => '/lifecycle/tree_project_jobs',
            'type' => 'component',
            'menu' => [
                {
                  icon => '/static/images/icons/open.png',
                  text => _loc('Open...'),
                  comp => { url => '/job/monitor' },
                }
            ],
          }
    };
    push @nodes,{
        'node' => 'Views',
        'icon' => '/static/images/icons/views.png',
        'menu' => [
                    {
                      'icon' => '/static/images/icons/folder_new.gif',
                      'text' => 'New Folder',
                      'url' => '/fileversion/new_folder',
                       'eval' => {
                           handler=>'Baseliner.new_folder',
                       },
                    }
                  ],
        'url' => '/fileversion/tree_file_project',
        'data' => {
                    id_folder => '',
                    'on_drop' => {
                                   'url' => '/fileversion/drop'
                                 }
                  },
        'type' => 'component',
    };
    $has_permission = Baseliner->model('Permissions')->user_has_action( username=> $username, action=>'action.home.hide_project_repos' );
    if ( !$has_permission || $is_root ){
        my @repos =
            map { values %$_ }
            mdb->master_rel->find({from_mid=>"$id_prj", rel_type=>'project_repository'})->fields({ to_mid=>1, _id=>0 })->all;

        for my $id_repo ( @repos ) {
            try {
                my $repo = ci->new( $id_repo );
                push @nodes, {
                  node   => $repo->name,
                  type   => 'changeset',
                  url    => $repo->content_url, 
                  active => 1,
                  icon   => $repo->icon,
                  data   => {
                    id_repo => $id_repo  
                  }
                };
            } catch {
                # publish an error node
                my $err = shift;
                my $msg = _loc('Error loading repository %1: %2', $id_repo, $err);
                _error( $msg );
                push @nodes, {
                  node    => substr($msg,0,80), 
                  active  => 1,
                  leaf    => \1,
                  icon    => '/static/images/icons/error.png',
                  data    => { id_repo => $id_repo }
                };
                
            };
        }
    }
    # General bag for starting the deployment workflow
    # Show states only if user has action for that project
    
    my @states;
    my @projects_with_lc = Baseliner->model('Permissions')->user_projects_with_action( username => $username, action => 'action.project.see_lc');
    my @user_workflow = _unique map {$_->{id_status_from} } Baseliner->model("Topic")->user_workflow( $username );

    if ( @projects_with_lc && $id_prj ~~ @projects_with_lc ) {   

        # States-Statuses with bl and type = D (Deployable)
        my @deployable_statuses = map { $_->{id_status} } ci->status->find({ type=>'D' })->sort({ seq=>1 })->all; 
        
        my @from_statuses = 
                _unique map { $_->{id_status_from} } 
                grep { 
                    $$_{id_status_from} ~~ @user_workflow 
                    && $$_{id_status_to} ~~ @deployable_statuses 
                }
                map { _array($$_{workflow}) }
                mdb->category->find->fields({ workflow=>1 })->all;
        push @from_statuses, map { $_->{id_status} } ci->status->find({ view_in_tree => '1' })->sort({ seq=>1 })->all; 
        @from_statuses = _unique(@from_statuses);
        
        push @states, map {
                my $project_ci = ci->new($id_prj);
                my @project_bls = map { $_->{bl} } _array $project_ci->bls;
                my @bls = map { $_->{bl} } sort { $a->{seq} <=> $b->{seq} } grep { !@project_bls || $_->{bl} ~~ @project_bls } _array $_->{bls};
                my $bls_text = join ",", @bls;
                #+{  node   => $_->{type} ne "D" ? $_->{name}:"$_->{name} [$bls_text]",
                +{  node   => !$bls_text || $bls_text eq '*' ? $_->{name}:"$_->{name} [$bls_text]",
                type   => 'state',
                active => 1,
                data => { id_status => $_->{id_status}, },
                bl     => $bls[0],
                bl_to  => $bls[0],                               # XXX
                icon   => '/static/images/icons/state.gif',
                seq => $_->{seq}
                };
            } sort {
                $a->{seq} <=> $b->{seq}
            } grep { 
                ref $_ eq 'BaselinerX::CI::status'
            } 
            BaselinerX::CI::status->query( { id_status =>mdb->in(@from_statuses) } );
    } else {
        # publish an warning node
        my $msg = _loc('User does not have access to states');
        push @nodes, {
          node    => $msg,
          active  => 1,
          leaf    => \1,
          icon    => '/static/images/icons/error.png',
        };
    }

    [ @nodes, @states ];
}

=head2 project_repos project=>'...'

Returns all repositories for a project:

    name => 'reponame'
    path => '/path/to/repo'

=cut
sub project_repos {
    my ($self, %args) = @_;
    my $lc = $self->lc;
    my $prj = $args{project} or _throw 'Missing project parameter';
    return unless $lc->{projects};
    my @ret;
    for my $assoc ( @{ $lc->{projects} } ) {
        next unless $assoc->{name} eq $prj;
        push @ret, _array $assoc->{repositories}; 
    }
    @ret;
}

sub all_repos {
    my ($self, %args) = @_;
    my $lc = $self->lc;
    my @ret;
    for my $assoc ( @{ $lc->{projects} } ) {
        push @ret, { project=>$assoc->{name}, repositories=>$assoc->{repositories} } 
    }
    @ret;
}

sub bl {
    my ($self, $state_name ) = @_;
    my $state_data = $self->state_data;
    return try { $state_data->{ $state_name }->{bl} } catch { undef };
}

sub bl_from {
    my ($self, $state_name ) = @_;
    my $state_data = $self->state_data;
    return try { $state_data->{ $state_name }->{bl_from} } catch { undef };
}

sub bl_to {
    my ($self, $state_name ) = @_;
    my $state_data = $self->state_data;
    return try { $state_data->{ $state_name }->{bl_to} } catch { undef };
}

=head2 state_names_for_bl

    state_names_for_bl( bl_to => 'PROD' )
    state_names_for_bl( bl_from => 'PROD' )
    state_names_for_bl( bl => 'PROD' )

=cut
sub state_names_for_bl {
    my ($self, $type, $bl ) = @_;

    my @state_names;
    my $state_data = $self->state_data;
    for my $state_name ( keys %{ $state_data || {} } ) {
        # _log '%%%%%%%%%%% Checking '.$state_name;
        # _log '%%%%%%%%%%% Is correct? '.$state_data->{$state_name}->{ $type };
        if( $state_data->{$state_name}->{ $type } eq $bl ) {
            push @state_names, $state_name;
        }
    }
    return @state_names;
}

sub show_branch {
    my ($self, $state_name ) = @_;
    my $state_data = $self->state_data;
    return try { $state_data->{ $state_name }->{show_branch} } catch { undef };
}

sub repopath_for_project_repo {
    my ($self, $prjrepo ) = @_;
    if( my ($prj, $repo_name ) = $prjrepo =~ /^(.*)\:(.*)/ ) {
        my $lc = $self->lc;
        for my $assoc ( @{ $lc->{projects} } ) {
            next unless $assoc->{name} eq $prj;
            for my $repo ( _array $assoc->{repositories} ) {
                next unless $repo->{name} eq $repo_name;
                $repo->{project} = $prj;
                return $repo;
            }
        }
        _throw "Not found $prjrepo";
    } else {
        _throw "Invalid project:repo name $prjrepo";
    }
}

1;
