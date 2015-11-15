package Clarive::Cmd::prove;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'run prove with correct parameters';

sub run {
    my ( $self, %opts ) = @_;

    my @argv = @{ $opts{argv} };

    push @argv, 't' unless @argv;

    exec("prove -Ilib -It/lib -r @argv");
}

1;
