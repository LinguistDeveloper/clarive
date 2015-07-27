package Baseliner::Validator::sort_dir;
use Moo;
BEGIN { extends 'Baseliner::Validator::Base'; }

sub validate {
    my $self = shift;
    my ($value) = @_;

    return $self->_build_not_valid unless $value =~ qr/^(?:DESC|ASC)$/;
    return $self->_build_valid;
}

1;
