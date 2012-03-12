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

has 'baselines' => qw(is rw isa HashRef lazy 1), 
    default => sub{
        my $self = shift;
        my $lc = $self->lc;
        my $states = $lc->{lifecycle}->{default}->{states};
        my $baselines = {};
        for my $state ( _array $states ) {
           $baselines->{ $state->{bl} }->{to} = $state->{bl_to};
           $baselines->{ $state->{bl} }->{from} = $state->{bl_from};
        }
        return $baselines;
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

=head2 project_repos

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
    my ($self, $bl ) = @_;
    # TODO XXX
    my %from = ( DESA=>'DESA', DEV=>'new', TEST=>'DESA', PREP=>'TEST', PROD=>'PREP' );
    $from{ $bl };
}

sub bl_to {
    my ($self, $bl ) = @_;
    my $baselines = $self->baselines;
    # TODO XXX
    return try { $baselines->{ $bl }->{to} } catch { undef };
}

sub repopath_for_project_repo {
    my ($self, $prjrepo ) = @_;
    if( my ($prj, $repo_name ) = $prjrepo =~ /^(.*)\:(.*)/ ) {
        my $lc = $self->lc;
        for my $assoc ( @{ $lc->{projects} } ) {
            next unless $assoc->{name} eq $prj;
            for my $repo ( _array $assoc->{repositories} ) {
                next unless $repo->{name} eq $repo_name;
                return $repo;
            }
        }
        _throw "Not found $prjrepo";
    } else {
        _throw "Invalid project:repo name $prjrepo";
    }
}

1;
