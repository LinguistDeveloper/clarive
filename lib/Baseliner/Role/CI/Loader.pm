package Baseliner::Role::CI::Loader;
use Moose::Role;
with 'Baseliner::Role::CI';
#with 'Baseliner::Role::ErrorThrower';

sub icon { '/static/images/icons/agent.svg' }

requires 'run_load';

1;
