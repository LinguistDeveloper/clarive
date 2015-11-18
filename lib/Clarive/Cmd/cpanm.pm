package Clarive::Cmd::cpanm;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'run cpanm with correct parameters';

sub run {
    my ( $self, %opts ) = @_;

    my @argv = @{ $opts{argv} };

    exec("cpanm --mirror-only --mirror http://cpan.clarive.com @argv");
}

1;
