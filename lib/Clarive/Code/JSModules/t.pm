package Clarive::Code::JSModules::t;
use strict;
use warnings;

use File::Spec;

use Test::More;
use Test::Deep;
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js = shift;

    +{
        subtest => js_sub {
            my $msg = shift;
            my $cb = shift;
            subtest $msg => js_sub(\&$cb);
        },
        doneTesting => js_sub {
            done_testing;
        },
        ok => js_sub {
            my ($cond, $msg) = @_;
            ok( $cond, $msg );
        },
        is => js_sub {
            my ($cond, $val, $msg) = @_;
            is( $cond, $val, $msg );
        },
        isnt => js_sub {
            my ($cond, $val, $msg) = @_;
            isnt( $cond, $val, $msg );
        },
        isDeeply => js_sub {
            my ($cond, $val, $msg) = @_;
            is_deeply( $cond, $val, $msg );
        },
        cmpDeeply => js_sub {
            my ($cond, $val, $msg) = @_;
            cmp_deeply( $cond, $val, $msg );
        },
        like => js_sub {
            my ($cond, $val, $msg) = @_;
            like( $cond, $val, $msg );
        },
        unlike => js_sub {
            my ($cond, $val, $msg) = @_;
            unlike( $cond, $val, $msg );
        },
        pass => js_sub {
            my ($msg) = @_;
            pass( $msg );
        },
        fail => js_sub {
            my ($msg) = @_;
            fail( $msg );
        },
        diag => js_sub {
            my ($msg) = @_;
            diag( $msg );
        },
        skip => js_sub {
            my ($msg) = @_;
            skip( $msg );
        },
    }
}

1;

