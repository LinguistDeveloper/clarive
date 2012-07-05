package BaselinerX::CI::WindowsServer;
use Moose;
with 'Baseliner::Role::CI::Server';

sub collection { 'windows_server' }

1;
