package BaselinerX::CI::tomcat;
use Moose;
with 'Baseliner::Role::CI::ApplicationServer';

sub collection { 'tomcat' }

sub error {}
sub rc {}

1;


