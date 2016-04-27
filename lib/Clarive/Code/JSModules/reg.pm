package Clarive::Code::JSModules::reg;
use strict;
use warnings;

use Baseliner::RuleFuncs ();
use Baseliner::Core::Registry;
use Clarive::Code::JS::Service;
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        register => js_sub {
            my ( $key, $obj ) = @_;

            Baseliner::Core::Registry->add( 'Clarive::Code::JS::Service', $key,
                _serialize( { to_bytecode => 1 }, $obj ) );
        },
        launch => js_sub {
            my $key = shift;
            my ($opts) = @_;

            $stash = $opts->{stash} if $opts->{stash};

            Baseliner::RuleFuncs::launch( $key, $opts->{name}, $stash,
                $opts->{config}, $opts->{dataKey} );
        },
    };
}

1;
