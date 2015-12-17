package Baseliner::Code;
use strict;
use warnings;
use Baseliner::Utils qw(_fail _loc);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = { lang=>$params{lang} };
    bless $self, $class;

    return $self;
}

sub eval_code {
    my $self = shift;
    my ($code,$stash) = @_;

    if( $self->{lang} eq 'js' ) {
        require Baseliner::Code::JS;
        my $js = Baseliner::Code::JS->new;
        $js->eval_code( $code, $stash );
    } else {
        _fail _loc( 'Unknown code language: %1', $self->{lang} );
    }
    
}

1;
