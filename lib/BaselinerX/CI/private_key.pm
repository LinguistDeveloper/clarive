package BaselinerX::CI::private_key;
use Moose;

sub collection { 'ssh_script' }

has script => qw(is rw isa Any);

1
