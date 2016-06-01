package Baseliner::Role::CI::CCMDB;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/agent.svg' }
sub ci_form { '/ci/item.js' }

1;
