package Clarive::Code::JSModules::process;
use v5.10;
use strict;
use warnings;

use Config qw( %Config );
use Baseliner::Utils qw(_json_pointer);
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    my $app = $js->app;

    +{
        argv => js_sub {
            return $app->argv;
        },
        args => js_sub {
            return $app->args;
        },
        options => js_sub {
            my ($pointer) = @_;
            return _json_pointer( $js->options, $pointer );
        },
        env => js_sub {
            return {%ENV};
        },
        pid => js_sub {
            return $$;
        },
        title => js_sub {
            return $0;
        },
        arch => js_sub {
            return $Config{archname};
        },
        os => js_sub {
            return $^O;
        },
        hrtime => js_sub {
            require Time::HiRes;
            my ( $seconds, $microseconds ) = Time::HiRes::gettimeofday();
            return [ $seconds, $microseconds ];
        },
    };
}

1;

