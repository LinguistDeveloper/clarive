package Baseliner::Core::Event;
use Moose;

has data => qw(is rw isa HashRef), default => sub{{}};


1;
