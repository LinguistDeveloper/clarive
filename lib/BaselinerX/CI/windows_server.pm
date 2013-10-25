package BaselinerX::CI::windows_server;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Server';

sub error {}
sub rc {}
sub ping {'OK'};
sub connect { ... }

1;
