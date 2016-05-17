package Clarive::Code::JSModules::process;
use strict;
use warnings;

use Config qw( %Config );
use Clarive::Code::JSUtils qw(js_sub);

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        argv => js_sub { \@ARGV },
        env  => js_sub {
            my ($key) = @_;

            return \%ENV unless $key;

            return $ENV{$key};
        },
        pid   => js_sub { $$ },
        title => js_sub { $0 },
        arch  => js_sub { $Config{archname} },
        os    => js_sub { $^O },
    };
}

1;
