package Baseliner::Standalone;
use Moose;
extends 'Baseliner';
has 'stash' => qw(is rw isa HashRef), default => sub{{}};
sub registry { 'Baseliner::Core::Registry' }

Baseliner::Standalone->meta->make_immutable( inline_constructor=>0 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

