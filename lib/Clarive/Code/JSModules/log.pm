package Clarive::Code::JSModules::log;
use strict;
use warnings;

use Baseliner::Utils qw(:logging);
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        info  => js_sub { _info(@_) },
        debug => js_sub { _debug(@_) },
        warn  => js_sub { _warn(@_) },
        error => js_sub { _error(@_) },
        fatal => js_sub { _fail(@_) },
    };
}

1;
