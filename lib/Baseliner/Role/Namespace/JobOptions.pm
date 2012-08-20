package Baseliner::Role::Namespace::JobOptions;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'job_options_global';
requires 'job_options';

1;
