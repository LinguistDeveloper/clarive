package BaselinerX::CI::filesys_repo;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Repository';

has root_dir   => qw(is rw isa Str required 1); # base path for relative dirs
has start_path => qw(is rw isa Str), default=>sub { '.' };  # where we start searching from

sub collection { 'filesys_repo' }
sub icon       { '/static/images/icons/drive.svg' }

sub checkout { }
sub list_elements { }
sub repository { }
sub update_baselines { }

has items => qw(is rw isa Baseliner::Role::CI::Group lazy 1), default=>sub{
    $_[0]->load_items;
};

service scan => 'Scan files' => sub {
    my ($self,$c,$p) =@_;
    $self->method_scan( $p );
};

service load => 'Load files as items' => sub {
    my ($self,$c,$p) =@_;
    my $itset = $self->load_items();
    $self->children( $itset->items );
    $self->save;
    return $itset;
};

sub load_items {
    my ( $self, %p ) = @_;
    my $d = Util->_dir( $self->root_dir, $self->start_path );
    Util->_fail( Util->_loc('Directory does not exist or is not accesible %1', $d ) ) unless -e $d;
    my @items;
    $d->recurse(
        callback => sub {
            my $f = shift;
            my $relative = $f->relative( $self->root_dir );
            push @items,
                BaselinerX::CI::file->new(
                    ns     => "$relative",
                    name   => $f->basename,
                    is_dir => $f->is_dir,
                    path   => "$f",
                    dir    => ''. $relative->parent,
                );
        }
    );
    BaselinerX::CI::itemset->new( items => \@items );
}



1;
