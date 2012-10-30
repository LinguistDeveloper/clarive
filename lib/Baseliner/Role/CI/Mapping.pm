package Baseliner::Role::CI::Mapping;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/icons/catalog.gif' }

1;


