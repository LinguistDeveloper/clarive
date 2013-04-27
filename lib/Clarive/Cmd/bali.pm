package Clarive::Cmd::bali;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;

has service_name => qw(is ro required 1);

with 'Clarive::Role::Baseliner'; 

our $CAPTION = 'run Baseliner services';

sub run {
    my ($self,%opts)=@_;
    $self->bali_service( $self->service_name, %opts ); 
}

1;
