package BaselinerX::Lc;
use Moose;
use Baseliner::Utils;

has 'lc' => (
    is      => 'rw',
    isa     => 'Any',
    default => sub {
        my $feature = Baseliner->features->find( file => __FILE__ );
        my $file = _file( $feature->root, '..', 'etc', 'lc.yaml' );    # TODO to config
        open my $ff, '<', "$file" or _throw _loc "Error loading file %1: %2", $file, $!;
        my $lc = _load join '', <$ff>;
        close $ff;
        # now from config
        my $ch = Baseliner->config->{lifecycle} || {};
        _log "CH=================" . _dump $ch;
        return +{ %$lc, %$ch };
    }
);

sub lc_for_project {
    my ($self, $id_prj) = @_;
    my $lc = $self->lc;
    _log "LC==========> $lc , " . ref $lc;
    my $nodes = $lc->{nodes};
    my $states = $lc->{lifecycle}->{default}->{states};
    no strict;
    [ @$nodes, @$states ];
}

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
