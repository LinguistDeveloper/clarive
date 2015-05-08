package Baseliner::Role::CI::Destination;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::ErrorThrower';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/icons/destination.png' }

requires 'path';

has home     => qw(is rw isa Str), default => '/';

1;
