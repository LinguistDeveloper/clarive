package Clarive::Code::JSModules::util;
use strict;
use warnings;

use Time::HiRes qw(usleep);
use Benchmark ();
use Clarive::Code::JSUtils qw(js_sub);
use Baseliner::Utils qw(_retry);

sub generate {
    my $self  = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        benchmark => js_sub {
            my ( $count, $cb ) = @_;

            Benchmark::timethis( $count, $cb );
        },
        sleep => js_sub {
            my $s = shift;

            usleep( $s * 1_000_000 );
        },
        retry => js_sub {
            my ( $cb, $options ) = @_;

            return _retry $cb,
              attempts => exists $options->{attempts} ? $options->{attempts} : 0,
              pause => $options->{pause};
        },
    };
}

1;
