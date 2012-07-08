package Baseliner::Role::CI::Destination;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/ci/destination.png' }

requires 'path';

1;
