package BaselinerX::CI::filesys_repo;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Repository';

has root_path => qw(is rw isa Str);

sub collection { 'filesys_repo' }
sub icon       { '/static/images/icons/gitrepository.gif' }

sub checkout { }
sub list_elements { }
sub repository { }
sub update_baselines { }

sub items {
    my ( $self, %p ) = @_;
    my $d = Util->_dir( $self->root_path );
    my @items;
    $d->recurse(
        callback => sub {
            my $f = shift;
            push @items,
                BaselinerX::CI::file->new(
                    name   => $f->basename,
                    is_dir => $f->is_dir,
                    path   => "$f",
                    dir    => '' . $f->parent
                );
        }
    );
    BaselinerX::CI::itemset->new( children => \@items );
}



1;

