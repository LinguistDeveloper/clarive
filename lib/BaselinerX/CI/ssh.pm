package BaselinerX::CI::ssh;
use Moose;
with 'Baseliner::Role::CI::Agent';

sub collection { 'ssh_agent' }

1;
