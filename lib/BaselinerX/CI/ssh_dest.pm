package BaselinerX::CI::ssh_dest;
use Moose;
with 'Baseliner::Role::CI::Destination';

sub collection { 'ssh_dest' }

1;

