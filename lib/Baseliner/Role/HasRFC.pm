package Baseliner::Role::HasRFC;
use Moose::Role;

=head1 NAME

Baseliner::Role::HasRFC

=head1 DESCRIPTION

This roles indicates that the Namespace has an 
external RFC associated with it. 

=head1 REQUIRES

=head2 rfc

A method that returns a RFC code for this namespace

=cut

requires 'rfc'; 

1;
