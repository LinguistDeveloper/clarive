package Baseliner::Role::Filesys;
use Moose::Role;

requires 'execute';
requires 'put';
requires 'get';
requires 'copy';

1;

