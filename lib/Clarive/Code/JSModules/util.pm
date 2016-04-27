package Clarive::Code::JSModules::util;
use strict;
use warnings;

use Time::HiRes qw(usleep);
use Benchmark ();
use Clarive::Code::Utils qw(js_sub);

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
    };
}

1;
