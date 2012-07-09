package BaselinerX::CI::jboss;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'jboss' }

sub error {}
sub rc {}

1;


