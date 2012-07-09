package BaselinerX::CI::uss;
use Moose;
with 'Baseliner::Role::CI::Server';

sub collection { 'uss' }

sub error {}
sub rc {}

1;



