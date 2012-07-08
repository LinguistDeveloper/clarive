package BaselinerX::CI::generic_server;
use Moose;
with 'Baseliner::Role::CI::Server';

sub collection { 'generic_server' }

sub error {}
sub rc {}

1;


