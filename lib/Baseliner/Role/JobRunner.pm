package Baseliner::Role::JobRunner;
use Moose::Role;

requires 'jobid';
requires 'bl';
requires 'step';
requires 'status';
requires 'exec';
requires 'logger';

1;
