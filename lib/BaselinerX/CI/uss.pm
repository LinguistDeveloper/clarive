package BaselinerX::CI::uss;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Server';

sub error {}
sub rc {}
sub ping {'OK'};

1;



