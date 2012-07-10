package BaselinerX::CI::iis;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'iis' }

sub error {}
sub rc {}

1;

