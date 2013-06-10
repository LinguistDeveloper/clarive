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
    my ($self, $id_prj, $name_prj) = @_;
    #my $lc = $self->lc;
    #_log "LC==========> $lc , " . ref $lc;
    #my $nodes = $lc->{nodes}; $ch ||= {
    my $nodes = [
          {
            'node' => 'Topics',
            'icon' => '/static/images/icons/topic.png',
            'url' => '/lifecycle/tree_topics_project',
            'data' => {
                        'click' => {
                                     'icon' => '/static/images/icons/topic.png',
                                     'url' => '/topic/grid',
                                     'title' => $name_prj,
                                     'type' => 'comp'
                                   }
                      },
            'type' => 'component',
          },
          {
            'node' => 'Releases',
            'icon' => '/static/images/icons/release.gif',
            'url' => '/lifecycle/tree_project_releases',
            'type' => 'component',
          },
          {
            'node' => 'Jobs',
            'icon' => '/static/images/icons/job.png',
            'url' => '/lifecycle/tree_project_jobs',
            'type' => 'component',
            'menu' => [
                {
                  icon => '/static/images/icons/job.png',
                  text => _loc('Open...'),
                  comp => { url => '/job/monitor' },
                }
            ],
          },
          {
            'node' => 'Views',
            'icon' => '/static/images/icons/directory.png',
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
                        id_directory => '',
                        'on_drop' => {
                                       'url' => '/fileversion/drop'
                                     }
                      },
            'type' => 'component',
          },
    ];
    

    my @repos =
        map { values %$_ }
        DB->BaliMasterRel->search( {from_mid => $id_prj, rel_type => 'project_repository'},
        {select => 'to_mid'} )->hashref->all;

    for my $id_repo ( @repos ) {
        my $repo = Baseliner::CI->new( $id_repo );
        push @$nodes, {
          node => _loc("Branches").": ".$repo->name,
          type => 'changeset',
          url => '/lifecycle/branches',
          active => 1,
          icon => '/static/images/icons/lc/branches_obj.gif',
          data => {
            id_repo => $id_repo  
          }
          
        }
    }

    # General bag for starting the deployment workflow
    my @states = (
        {   node   => _loc('(Stage)'),
            type   => 'state',
            active => 1,
            bl     => 'IT',
            bl_to  => 'IT',
            icon   => '/static/images/icons/lc/history.gif'
        }
    );

    # States-Statuses with bl and type = D (Deployable)
    push @states, map {
        +{  node   => sprintf("%s [%s]",_loc($_->{name}), $_->{bl}),
            type   => 'state',
            active => 1,
            data => { id_status => $_->{id}, },
            bl     => $_->{bl},
            bl_to  => $_->{bl},                               # XXX
            icon   => '/static/images/icons/lc/history.gif'
            }
        } Baseliner->model('Baseliner::BaliTopicStatus')
        ->search( { bl => { '<>' => '*' }, type=>'D'  }, { order_by => { -asc => ['seq'] } } )->hashref->all;
            

    no strict;
    [ @$nodes, @states ];
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
