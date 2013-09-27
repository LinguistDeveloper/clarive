package Clarive::Cmd::prove;
use Mouse;
use Path::Class;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'run a system check';

our $t0;

with 'Clarive::Role::Baseliner';

sub run {
    my ( $self ) = @_;
    $self->setup_baseliner;
    $SIG{__WARN__} = sub {};
    $ENV{BASELINER_DEBUG}=0;
    say "Starting system test...";
    eval {
        require Baseliner;
    };
    if( $@ ) {
        die "Clarive: error during system prove: $@\n";
    } else {
        say "Clarive: all systems ready.";
    }
    exit 0;
}

1;
