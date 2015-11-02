package Baseliner::Validator::Base;
use Moose;

sub _build_valid {
    my $self = shift;

    return $self->_build_result( is_valid => 1, @_ );
}

sub _build_not_valid {
    my $self = shift;

    return $self->_build_result( is_valid => 0, error => 'INVALID', @_ );
}

sub _build_result {
    my $self = shift;
    my (%params) = @_;

    return {%params};
}

1;
