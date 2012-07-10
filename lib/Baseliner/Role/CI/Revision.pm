package Baseliner::Role::CI::Revision;
use Moose::Role;

requires 'list_elements';
requires 'checkout';
requires 'repository';

1;



