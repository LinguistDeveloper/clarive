package Baseliner::Role::CI::VariableStash;
use Moose::Role;
with 'Baseliner::Role::CI';

has variables => qw(is rw isa HashRef), default=>sub{ +{} };

1;

