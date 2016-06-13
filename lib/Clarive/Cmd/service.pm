package Clarive::Cmd::service;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;

has service_name => qw(is ro required 1);

with 'Clarive::Role::Baseliner';

our $CMD_ALIAS = '<service.*>';
our $CAPTION = 'run services';

sub run {
    my ($self,%opts)=@_;
    $self->setup_baseliner;
    $self->bali_service( $self->service_name, %opts );
}

1;
