package Clarive::Code::JSModules::path;
use strict;
use warnings;

use File::Spec;
use File::Basename ();
use Clarive::Code::Utils qw(js_sub);

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        basename => js_sub { File::Basename::basename(@_) },
        dirname  => js_sub { File::Basename::dirname(@_) },
        extname  => js_sub {
            my ($filename) = @_;

            if ($filename =~ m/.((?:\.[^\.\/]+)+)$/) {
                return $1;
            }

            return '';
        },
        join => js_sub { File::Spec->catfile(@_) },
    };
}

1;
