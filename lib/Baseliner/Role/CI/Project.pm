package Baseliner::Role::CI::Project;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/ci/project.png' }

has repository => qw(is rw isa Any);

1;

