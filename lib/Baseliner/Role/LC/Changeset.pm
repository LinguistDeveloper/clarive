package Baseliner::Role::LC::Changeset;
use Moose::Role;

requires 'name';

has icon => qw(is rw isa Str default /static/images/icons/lc/branch_obj.gif);

with 'Baseliner::Role::LC::Node';

1;

