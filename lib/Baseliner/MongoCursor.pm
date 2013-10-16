package Baseliner::MongoCursor;
use Mouse;
extends 'MongoDB::Cursor';

sub each {
    my ($self, $code ) = @_;
    while( my $doc = $self->next ) {
        $code->($doc);
    }
}


1;
