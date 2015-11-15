package Clarive::Cmd::proveui;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'run ui tests';

sub run {
    my ( $self, %opts ) = @_;

    my @argv = @{ $opts{argv} || [] };
    push @argv, '-c' => 'ui-tests/clarive.json'
      unless grep { $_ eq '-c' } @argv;
    push @argv, '-e' => 'phantomjs'
      unless grep { $_ eq '-e' } @argv;
    system("$ENV{NODE_MODULES}/nightwatch/bin/nightwatch @argv");
}

1;
