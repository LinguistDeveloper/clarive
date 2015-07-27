package Baseliner::Validator::match;
use Moo;
BEGIN { extends 'Baseliner::Validator::Base'; }

has re => qw(is ro);

sub validate {
    my $self = shift;
    my ($value) = @_;

    return $self->_build_not_valid unless $value =~ $self->re;
    return $self->_build_valid;
}

1;
