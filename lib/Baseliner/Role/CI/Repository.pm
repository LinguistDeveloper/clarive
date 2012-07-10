package Baseliner::Role::CI::Repository;
use Moose::Role;

requires 'list_elements';
requires 'checkout';
requires 'update_baselines';

1;



