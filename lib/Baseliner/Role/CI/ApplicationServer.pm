package Baseliner::Role::CI::ApplicationServer;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::ErrorThrower';

sub icon { '/static/images/ci/appserver.png' }

1;


