package Baseliner::Role::Namespace::Rename;
use Moose::Role;

requires 'rename';

=head1 DESCRIPTION

A namespace that can be renamed.

=head1 REQUIRES

=head2 rename

A method to rename a namespace.

    $self->rename( $name );

=cut

1;


