package Baseliner::MongoCursorCI;
use Moose;

has cursor => qw(is ro isa MongoDB::Cursor);

sub next     { my $self = shift; _wrapper( $self->cursor->next ) }
sub has_next { my $self = shift; $self->cursor->has_next }
sub count    { my $self = shift; $self->cursor->count(@_) }

sub all {
    my $self = shift;

    return ( map { _wrapper($_) } $self->cursor->all );
}

sub fields { my $self = shift; __PACKAGE__->new( cursor => $self->cursor->fields(@_) ) }
sub limit  { my $self = shift; __PACKAGE__->new( cursor => $self->cursor->limit(@_) ) }
sub skip   { my $self = shift; __PACKAGE__->new( cursor => $self->cursor->skip(@_) ) }
sub sort   { my $self = shift; __PACKAGE__->new( cursor => $self->cursor->sort(@_) ) }

sub _wrapper { ci->new( $_[0]->{mid} ) }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
