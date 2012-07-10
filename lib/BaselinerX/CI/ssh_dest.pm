package BaselinerX::CI::ssh_dest;
use Moose;

sub collection { 'ssh_dest' }

has path => qw(is rw isa Any);

extends 'BaselinerX::CI::ssh_agent';   # XXX not sure, use delegation instead
with 'Baseliner::Role::CI::Destination';

sub error {}
sub rc {}

1;

