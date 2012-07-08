package Baseliner::Role::CI::Internal;
use Moose::Role;
with 'Baseliner::Role::CI';

sub error {}
sub rc {}

1;
