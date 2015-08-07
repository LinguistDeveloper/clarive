package Clarive::Cmd::init;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Clarive System Initialization';

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Baseliner';

use boolean;
use Clarive::mdb;
use Clarive::ci;
use Baseliner::Utils qw(_md5);

sub run {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = mdb->clarive->find_one();

    if ( !$clarive || ( !%$clarive && !$clarive->{initialized} ) ) {
        local *Baseliner::config = \&Clarive::config;

        if ( !ci->user->find_one( { name => 'root' } ) ) {
            ci->user->new(
                {
                    name             => 'root',
                    username         => 'root',
                    project_security => {},
                    realname         => 'Root User',
                    password         => _md5( _md5( _md5 ) ),
                }
            )->save;
        }

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
