package Baseliner::Role::CI::Project;
use Moose::Role;
with 'Baseliner::Role::CI::Internal';

sub icon { '/static/images/icons/project.svg' }

has repository => qw(is rw isa Any);

1;
