package Clarive::Code::JSModules::path;
use strict;
use warnings;

use File::Spec;
use File::Basename ();

use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        basename => js_sub { File::Basename::basename(@_) },
        dirname  => js_sub { File::Basename::dirname(@_) },
        extname  => js_sub {
            ( File::Basename::fileparse( $_[0], qr/(?<=.)\.[^.]*/ ) )[2]
        },
        join => js_sub { File::Spec->catfile(@_) },
    };
}

1;
