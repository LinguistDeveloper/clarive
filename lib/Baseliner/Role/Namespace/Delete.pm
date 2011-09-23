package Baseliner::Role::Namespace::Delete;
use Moose::Role;

requires 'delete';

=head1 DESCRIPTION

A namespace that can be deleted.

=head1 REQUIRES

=head2 delete

A method to delete namespaces.

    $self->delete;

=cut

1;


