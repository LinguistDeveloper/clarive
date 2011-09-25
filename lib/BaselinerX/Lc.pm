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
        $lc;
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



1;
