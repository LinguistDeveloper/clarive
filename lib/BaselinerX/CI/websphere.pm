package BaselinerX::CI::websphere;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'websphere' }

sub error {}
sub rc {}

1;

