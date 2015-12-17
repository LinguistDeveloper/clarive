package Baseliner::Code;
use Moose;
use Moose::Util::TypeConstraints;

use Baseliner::Utils qw(_fail _loc);

has lang => qw(default js is rw isa), enum([qw(js perl)]);

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    if ( $self->lang eq 'js' ) {
        require Baseliner::Code::JS;
        my $js = Baseliner::Code::JS->new;
        $js->eval_code( $code, $stash );
    }
    else {
        _fail _loc( 'Unhandled code language: %1', $self->lang );
    }
}

1;
