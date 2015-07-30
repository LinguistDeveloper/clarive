package Baseliner::Core::Event;
use Moose;

has data => qw(is rw isa HashRef), default => sub{{}};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
