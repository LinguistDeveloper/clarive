package Baseliner::Role::CI::Mainframe;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/icons/mainframe.svg' }

1;
