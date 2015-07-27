package Baseliner::Validator::git_tag;
use Moo;
BEGIN { extends 'Baseliner::Validator::Base'; }

sub validate {
    my $self = shift;
    my ($value) = @_;

    return $self->_build_not_valid unless $value =~ qr/^[[:alnum:]\-#\.]+$/;
    return $self->_build_valid;
}

1;
