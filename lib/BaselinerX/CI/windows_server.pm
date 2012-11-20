package BaselinerX::CI::windows_server;
use Moose;
with 'Baseliner::Role::CI::Server';

sub error {}
sub rc {}
sub ping {'OK'};

1;
