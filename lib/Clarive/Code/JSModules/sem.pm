package Clarive::Code::JSModules::sem;
use strict;
use warnings;

use Baseliner::Sem;
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        take => js_sub {
            my $key = shift || die "Missing semaphore key\n";
            my $cb  = shift || die "Missing semaphore function\n";

            my $sem = Baseliner::Sem->new( key => $key );
            $sem->take;
            return $cb->( _serialize({}, $sem) );
        },
    };
}

1;
