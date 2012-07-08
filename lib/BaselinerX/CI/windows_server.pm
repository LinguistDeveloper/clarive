package BaselinerX::CI::windows_server;
use Moose;
with 'Baseliner::Role::CI::Server';

sub collection { 'windows_server' }

sub error {}
sub rc {}

1;
