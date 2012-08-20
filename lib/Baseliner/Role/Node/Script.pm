package Baseliner::Role::Node::Script;
use Moose::Role;

requires 'run';

has arg => qw(is rw isa ArrayRef[Str]), default=>sub{[]}, traits=>['Array'];

sub script { shift->home }

1;
