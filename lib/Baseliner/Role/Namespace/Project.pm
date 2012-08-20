package Baseliner::Role::Namespace::Project;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

=head1 DESCRIPTION

A project is directory that belongs to a subapplication. 

=cut

1;
