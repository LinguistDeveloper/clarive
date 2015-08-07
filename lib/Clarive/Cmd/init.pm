package Clarive::Cmd::init;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Clarive System Initialization';

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Baseliner';

use boolean;
use Clarive::mdb;
use Clarive::ci;

sub run {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = mdb->clarive->find_one();

    if ( !$clarive || ( !%$clarive && !$clarive->{initialized} ) ) {
        local *Baseliner::config = \&Clarive::config;

        mdb->clarive->insert( { initialized => true } );
    }
    else {
        die 'ERROR: System is already initialized';
    }
}

1;

__END__

=head1 Clarive System Initialization

Common options:

    --env <environment>
