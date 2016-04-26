package Clarive::Code::JSModules::reg;
use strict;
use warnings;

use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    {
        register => js_sub {
            my ( $key, $obj ) = @_;

            Baseliner::Core::Registry->add( 'Clarive::Code::JS::Service', $key,
                _serialize( { to_bytecode=>1 }, $obj ) );
        },
        launch => js_sub {
            my $key  = shift;
            my %opts = @_;
            require Baseliner::RuleFuncs;
            Baseliner::RuleFuncs::launch( $key, $opts{name},
                $opts{stash} // $stash,
                $opts{config}, $opts{dataKey} );
        },
    };
}

1;
