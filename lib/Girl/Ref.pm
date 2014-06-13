package Girl::Ref;
use Any::Moose;
use Girl::Commit;

has name   => qw( is rw isa Str );
has commit => qw( is rw isa Girl::Commit);

# static 

sub prefix {
    my $self = shift;
    ( my $prefix = $self->name ) =~ s/^.*:://s;
    'refs/' . lc( $prefix );
}

sub find_all {
    my ($class, $repo, %args) = @_;
    my @refs = $repo->git->refs( %args ); 
    map {
        my $ref = $_;
        my ($name, $id ) = ( $ref->{name}, $ref->{id} );
        my $commit = Girl::Commit->create( $repo, sha => $id ); 
        $class->new( name=>$ref->{name}, commit=>$commit );
    } @refs;
}

package Girl::Head;
use Any::Moose;
extends 'Girl::Ref';

package Girl::Remote;
use Any::Moose;
extends 'Girl::Ref';

package Girl::Note;
use Any::Moose;
extends 'Girl::Ref';


1;
