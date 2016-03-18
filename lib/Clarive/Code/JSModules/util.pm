package Clarive::Code::JSModules::util;
use strict;
use warnings;

use Baseliner::Utils qw(_dump _decode_json _load);
use Clarive::Code::Utils;

sub generate {
    my $self = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        loadYAML => js_sub {
            my ($yaml) = @_;
            _load($yaml);
        },
        dumpYAML => js_sub {
            my ($ref) = @_;
            _dump($ref);
        },
        loadJSON => js_sub {
            _decode_json(@_);
        },
        dumpJSON => js_sub {
            _to_json(@_);
        },
        unaccent => js_sub {
            my ($str) = @_;

            return Util->_unac($str);
        },
        benchmark => js_sub {
            my ( $count, $cb ) = @_;

            require Benchmark;

            Benchmark::timethis( $count, $cb );
        },
    };
}

1;
