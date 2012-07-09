package BaselinerX::CI::websphere_dmgr;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'websphere_dmgr' }

sub error {}
sub rc {}

1;

