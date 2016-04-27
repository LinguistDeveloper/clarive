package Clarive::Code::JSModules::t;
use strict;
use warnings;

use File::Spec;

use Test::Builder;
use Test::More;
use Test::Deep;
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        subtest => js_sub {
            my $msg = shift;
            my $cb  = shift;
            subtest $msg => js_sub( \&$cb );
        },
        doneTesting => js_sub {
            done_testing;
        },
        ok => js_sub {
            my ( $cond, $msg ) = @_;
            ok( $cond, $msg );
        },
        is => js_sub {
            my ( $cond, $val, $msg ) = @_;
            is( $cond, $val, $msg );
        },
        isnt => js_sub {
            my ( $cond, $val, $msg ) = @_;
            isnt( $cond, $val, $msg );
        },
        isDeeply => js_sub {
            my ( $cond, $val, $msg ) = @_;
            is_deeply( $cond, $val, $msg );
        },
        cmpDeeply => js_sub {
            my ( $cond, $val, $msg ) = @_;
            cmp_deeply( $cond, $val, $msg );
        },
        like => js_sub {
            my ( $cond, $val, $msg ) = @_;
            like( $cond, $val, $msg );
        },
        unlike => js_sub {
            my ( $cond, $val, $msg ) = @_;
            unlike( $cond, $val, $msg );
        },
        bag => js_sub {
            _serialize( { wrap_blessed => 1 }, bag(@_) );
        },
        shallow => js_sub {
            _serialize( { wrap_blessed => 1 }, shallow(@_) );
        },
        set => js_sub {
            _serialize( { wrap_blessed => 1 }, set(@_) );
        },
        noneof => js_sub {
            _serialize( { wrap_blessed => 1 }, noneof(@_) );
        },
        supersetof => js_sub {
            _serialize( { wrap_blessed => 1 }, supersetof(@_) );
        },
        subsetof => js_sub {
            _serialize( { wrap_blessed => 1 }, subsetof(@_) );
        },
        superbagof => js_sub {
            _serialize( { wrap_blessed => 1 }, superbagof(@_) );
        },
        subbagof => js_sub {
            _serialize( { wrap_blessed => 1 }, subbagof(@_) );
        },
        re => js_sub {
            _serialize( { wrap_blessed => 1 }, re(@_) );
        },
        any => js_sub {
            _serialize( { wrap_blessed => 1 }, any(@_) );
        },
        all => js_sub {
            _serialize( { wrap_blessed => 1 }, all(@_) );
        },
        ignore => js_sub {
            _serialize( { wrap_blessed => 1 }, ignore(@_) );
        },
    };
}

1;
