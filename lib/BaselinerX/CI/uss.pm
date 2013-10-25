package BaselinerX::CI::uss;
use Baseliner::Moose;

sub error {}
sub rc {}
sub ping {'OK'};
sub connect { ... }

with 'Baseliner::Role::CI::Server';

1;



