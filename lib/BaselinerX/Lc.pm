package BaselinerX::Lc;
use Moose;
use Baseliner::Utils;
use Try::Tiny;

has 'lc' => (
    is      => 'rw',
    isa     => 'Any',
    default => sub {
        # loads the lc.yaml file on initialization
        my $feature = Baseliner->features->find( file => __FILE__ );
        my $file = _file( $feature->root, '..', 'etc', 'lc.yaml' );    # TODO to config
        open my $ff, '<', "$file" or _throw _loc "Error loading file %1: %2", $file, $!;
        my $lc = _load join '', <$ff>;
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
            $state_data->{ $state_name }->{to} = $state->{bl_to};
            $state_data->{ $state_name }->{from} = $state->{bl_from};
            $state_data->{ $state_name }->{show_branch} = $state->{show_branch};
        }
        return $state_data;
    };

sub lc_for_project {
    my ($self, $id_prj) = @_;
    my $lc = $self->lc;
    _log "LC==========> $lc , " . ref $lc;
    my $nodes = $lc->{nodes};
    my $states = $lc->{lifecycle}->{default}->{states};
    no strict;
    [ @$nodes, @$states ];
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

sub bl_from {
    my ($self, $state_name ) = @_;
    my $state_data = $self->state_data;
    return try { $state_data->{ $state_name }->{from} } catch { undef };
}

sub bl_to {
    my ($self, $state_name ) = @_;
    my $state_data = $self->state_data;
    return try { $state_data->{ $state_name }->{to} } catch { undef };
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
