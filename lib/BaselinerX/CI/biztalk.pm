package BaselinerX::CI::biztalk;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'biztalk' }

sub error {}
sub rc {}

1;



