package BaselinerX::CI::weblogic;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'weblogic' }

sub error {}
sub rc {}

1;


