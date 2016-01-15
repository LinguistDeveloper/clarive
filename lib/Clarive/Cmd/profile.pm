package Clarive::Cmd::profile;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'print default profile';

sub run {
    my ( $self, %opts ) = @_;

    my $version = Clarive->version;

    print <<"EOF";

# Clarive profile $version

# User settings
export CLARIVE_BASE=$ENV{CLARIVE_BASE}
export CLARIVE_ENV=myenv

# System settings
export CLARIVE_HOME=\$CLARIVE_BASE/clarive
export LD_LIBRARY_PATH=\$CLARIVE_BASE/local/lib
export PATH="\$CLARIVE_HOME/bin:\$CLARIVE_BASE/local/bin:\$CLARIVE_BASE/local/sbin:\$PATH"

# End of Clarive profile

EOF
}

1;
