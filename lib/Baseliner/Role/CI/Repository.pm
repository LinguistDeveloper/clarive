package Baseliner::Role::CI::Repository;
use Moose::Role;
with 'Baseliner::Role::CI';

requires 'list_elements';
requires 'checkout';
requires 'update_baselines';
requires 'list_elements';
requires 'checkout';
requires 'repository';

1;



