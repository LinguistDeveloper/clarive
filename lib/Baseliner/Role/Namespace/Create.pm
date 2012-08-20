package Baseliner::Role::Namespace::Create;
use Moose::Role;

requires 'create';
requires 'create_form_url'; 

=head1 DESCRIPTION

A namespace that can be created, most likely by a user.

=head1 REQUIRES

=head2 create

A method to create namespaces.

    $self->create( 
        name     =>'namespacename',
        username =>'user',
        project  => 'project/12345',
    );

=head2 create_form_url

A method that returns a js component url with a create form.

=cut

1;

