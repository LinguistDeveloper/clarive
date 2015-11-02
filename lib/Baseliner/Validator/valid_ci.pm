package Baseliner::Validator::valid_ci;
use Moose;
BEGIN { extends 'Baseliner::Validator::Base'; }

has isa_check => qw(is ro);

use Clarive::ci;

sub validate {
    my $self = shift;
    my ($mid) = @_;

    my $ci = ci->new( mid => $mid );

    return $self->_build_not_valid unless $ci;
    return $self->_build_not_valid if $self->isa_check && !$ci->isa( $self->isa_check );
    return $self->_build_valid( value => $ci );
}

1;
