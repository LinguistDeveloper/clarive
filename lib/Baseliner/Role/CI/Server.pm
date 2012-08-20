package Baseliner::Role::CI::Server;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/ci/server.png' }

has hostname => qw(is rw isa Any);

1;

