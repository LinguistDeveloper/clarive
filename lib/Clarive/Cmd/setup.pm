package Clarive::Cmd::setup;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'run setup profile';

use Baseliner::Mongo;
use Baseliner::SetupProfile;
BEGIN { unshift @INC, 't/lib' }

sub run {
    my ($self, %opts) = @_;

    my @argv = @{$opts{argv} || []};

    my ($profile_name) = grep { !/^-/ } @argv;
    die "Usage: <profile_name>\n" unless $profile_name;

    my $profile = Baseliner::SetupProfile->load($profile_name);

    my $db_name = Baseliner::Mongo->new->mongo_db_name;

    if (
        $self->_ask_me(
                msg => "\n!!!!! WARNING !!!!!\n\n"
              . "Are you sure you want to run '$profile_name'?\n"
              . "All the data in '$db_name' will be lost!"
        )
      )
    {
        $profile->setup;

        warn "\nDone\n";
    }
    else {
        warn "\nSkipped\n";
    }
}

sub _ask_me {
    my $self = shift;
    my (%p) = @_;

    require Term::ReadKey;

    # flush keystrokes
    while (defined(my $key = Term::ReadKey::ReadKey(-1))) { }

    print $p{msg};
    print " [y/N/q]: ";

    unless ((my $yn = <STDIN>) =~ /^y/i) {
        exit 1 if $yn =~ /q/i;    # quit
        return 0;
    }

    return 1;
}

1;
