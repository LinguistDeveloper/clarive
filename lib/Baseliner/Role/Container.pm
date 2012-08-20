package Baseliner::Role::Container;
use Moose::Role;

# releases must return an array of namespace items
requires 'contents';

has 'content' => ( is=>'rw', isa=>'ArrayRef', default=>sub{[]} );

sub items {
    my $self = shift;
    return $self->content;
}

1;

