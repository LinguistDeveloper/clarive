package Baseliner::Role::CI::VariableStash;
use Moose::Role;
with 'Baseliner::Role::CI';

has variables => qw(is rw isa HashJSON coerce 1 default), sub{ +{} };

1;

