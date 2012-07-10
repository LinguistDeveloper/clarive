package Baseliner::Role::CI::Script;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::ErrorThrower';

sub icon { '/static/images/ci/script.png' }

requires 'script';
requires 'run';

has arg => qw(is rw isa ArrayRef[Str]), default=>sub{[]}, traits=>['Array'];

1;
