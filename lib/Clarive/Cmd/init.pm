package Clarive::Cmd::init;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Clarive System Initialization';

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Baseliner';

use boolean;
use Clarive::mdb;
use Clarive::ci;
use Clarive::Cmd::migra;
use Baseliner::Utils qw(_md5);

sub run {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = mdb->clarive->find_one();

    if ( !$self->check ) {
        no warnings 'redefine';
        local *Baseliner::config = \&Clarive::config;

        if ( !ci->user->find_one( { name => 'root' } ) ) {
            ci->user->new(
                {
                    name             => 'root',
                    username         => 'root',
                    project_security => {},
                    realname         => 'Root User',
                    password         => _md5( _md5(_md5) ),
                }
            )->save;
        }

        my %defaults = ( initialized => true );

        if ($clarive) {
            mdb->clarive->update( { _id => $clarive->{_id} }, { '$set' => {%defaults} } );
        }
        else {
            mdb->clarive->insert( {%defaults} );
        }

        Clarive::Cmd::migra->new( app => $self->app, env => $self->env, opts => {} )
          ->run_init( args => { yes => 1, quiet => 1 } );

        mdb->index_all;
    }
    else {
        die 'ERROR: System is already initialized';
    }
}

sub check {
    my $self = shift;

    my $clarive = mdb->clarive->find_one();

    return 0 unless $clarive && %$clarive && $clarive->{initialized};

    return 1;
}

1;

__END__

=head1 Clarive System Initialization

Common options:

    --env <environment>
