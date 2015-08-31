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

    if ($opts{args}->{reset}) {
        return unless $opts{args}->{yes} || $self->_ask_me( msg => 'ALL the data will be REMOVED' );

        my @collections = mdb->db->collection_names;
        foreach my $collection (@collections) {
            $self->_say("Dropping $collection", %opts);

            mdb->$collection->drop;
        }
    }

    my $clarive = mdb->clarive->find_one();

    if ( !$self->check ) {
        no warnings 'redefine';
        local *Baseliner::config = \&Clarive::config;

        if ( !ci->user->find_one( { name => 'root' } ) ) {
            $self->_say('Creating root user', %opts);

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
        else {
            $self->_say('User root exists. Skipping', %opts);
        }

        my %defaults = ( initialized => true );

        if ($clarive) {
            $self->_say('Updating clarive collection', %opts);

            mdb->clarive->update( { _id => $clarive->{_id} }, { '$set' => {%defaults} } );
        }
        else {
            $self->_say('Creating clarive collection', %opts);

            mdb->clarive->insert( {%defaults} );
        }

        $self->_say('Initializing migrations', %opts);
        Clarive::Cmd::migra->new( app => $self->app, env => $self->env, opts => {} )
          ->run_init( args => { yes => 1, quiet => 1 } );

        $self->_say('Initializing indexes', %opts);
        mdb->index_all( drop=>0 );
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

sub _say {
    my $self = shift;
    my ( $msg, %opts ) = @_;

    print "$msg\n" unless $opts{args}->{quiet};
}

sub _ask_me {
    my $self = shift;
    my (%p) = @_;

    require Term::ReadKey;

    # flush keystrokes
    while ( defined( my $key = Term::ReadKey::ReadKey(-1) ) ) { }

    print $p{msg};
    print " [y/N/q]: ";

    unless ( ( my $yn = <STDIN> ) =~ /^y/i ) {
        exit 1 if $yn =~ /q/i;    # quit
        return 0;
    }

    return 1;
}

1;
__END__

=head1 Clarive System Initialization

Common options:

    --env <environment>
    --reset drop all colections
