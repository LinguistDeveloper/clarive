package Baseliner::Role::Namespace::Checkin;
use Moose::Role;

requires 'checkin';
requires 'checkin_form_url'; 

=head1 DESCRIPTION

A namespace that can handle a Checkin from files

=head1 REQUIRES

=head2 checkin

A method to checkin files.

    $self->checkin( 
        placement => 'trunk' | 'branch',
        clientpath => '',
        viewpath => '',
        comment => '',
        username => '',
    );

=head2 checkin_form_url

A method that returns a js component url with a checkin form.

=cut

1;

