package Baseliner::Role::CI;
use Moose::Role;

sub icon_class { '/static/images/ci/class.gif' }
requires 'icon';
requires 'collection';

1;

