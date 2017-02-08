package Clarive::Cmd::help;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'This help';

sub run {
    my ( $self, %opts ) = @_;

    my $cmd = ref $opts{''} ? $opts{''}->[0] : $opts{''};

    if ($cmd) {
        $cmd =~ s{-.*$}{}g;

        my $pkg = $self->load_package_for_command($cmd);
        die "ERROR: command $cmd not found\n" unless $pkg;

        $pkg->show_help;
    }
    else {
        # cla -h

        Clarive::Cmd->show_cla_help;
    }
}

1;
