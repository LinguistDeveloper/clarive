package Baseliner::Role::CI::ApplicationServer;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/icons/app-server.svg' }

1;
