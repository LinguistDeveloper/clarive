package Clarive::Code::JSModules::console;
use v5.10;
use strict;
use warnings;

use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js = shift;

    +{
        log => js_sub { say( map{ ref($_) ? _to_json($_) : $_ } @_ ) },
        info => js_sub { say map{ ref($_) ? _to_json($_) : $_ } @_ },
        warn => js_sub { say STDERR map{ ref($_) ? _to_json($_) : $_ } @_ },
        error => js_sub { say STDERR map{ ref($_) ? _to_json($_) : $_ } @_ },
        assert => js_sub {
            my ($assert,$fmt, @msg) = @_;
            return if $assert;
            die sprintf( "AssertionError: $fmt\n", @msg );
        },
        dir => js_sub{
            my ($obj,$opts) = @_;
            say _to_json($obj);
        },
    }
}

1;

