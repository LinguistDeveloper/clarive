package Baseliner::Role::LC::Changeset;
use Moose::Role;

requires 'name';

has icon => qw(is rw isa Str default /static/images/icons/lc/branch_obj.gif);
#has id_project => qw(is rw isa Num required 1);
#has project => qw(is rw isa Num required 1);

with 'Baseliner::Role::LC::Node';

1;

