package Clarive::Code::JSModules::console;
use v5.10;
use strict;
use warnings;

use Encode ();
use Baseliner::Utils qw(_to_json);
use Clarive::Code::JSUtils qw(js_sub);

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        log => js_sub {
            $class->_print( *STDOUT, @_ );
        },
        warn => js_sub {
            $class->_print( *STDERR, @_ );
        },
        assert => js_sub {
            my ( $assert, $fmt, @msg ) = @_;

            return if $assert;

            say sprintf( "$fmt\n", @msg );
        }
    };
}

sub _print {
    my $class = shift;
    my $fh    = shift;

    print $fh map { Encode::is_utf8($_) ? Encode::encode( 'UTF-8', $_ ) : $_  } map { ref $_ ? _to_json($_) : $_ } @_, "\n";
}

1;
