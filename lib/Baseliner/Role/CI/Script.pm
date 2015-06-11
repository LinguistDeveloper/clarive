package Baseliner::Role::CI::Script;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::ErrorThrower';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/ci/script.png' }

requires 'path';
requires 'run';

has arg => qw(is rw isa ArrayRef[Str]), default=>sub{[]}, traits=>['Array'];

1;
