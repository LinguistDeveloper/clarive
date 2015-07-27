package Baseliner::Validator::in;
use Moo;
BEGIN { extends 'Baseliner::Validator::Base'; }

has in => ( is => 'ro' );

sub validate {
    my $self = shift;
    my ($value) = @_;

    my $in = $self->in;

    return $self->_build_not_valid unless grep { $value eq $_ } @$in;
    return $self->_build_valid;
}

1;
