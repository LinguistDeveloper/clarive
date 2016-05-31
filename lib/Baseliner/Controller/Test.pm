package Baseliner::Controller::Test;
use Moose;
BEGIN { extends 'Catalyst::Controller'; }

use Class::Load qw(load_class);
use Clarive::mdb;

sub setup : Local {
    my ( $self, $c ) = @_;

    if ( $ENV{CLARIVE_TEST} ) {
        my $dbname = Clarive->config->{mongo}->{dbname};

        die "Database '$dbname' doesn't look like a test database to me"
          unless $dbname && ( $dbname eq 'acmetest' || $dbname =~ m/^test/ );

        if (my $profile = $c->req->params->{profile}) {
            $self->_create_profile($profile)->setup;
        }

        $c->stash( json => { msg => 'ok' } );
        $c->forward('View::JSON');
    }
}

sub _create_profile {
    my $self = shift;
    my ($profile) = @_;

    my $class_profile = 'Baseliner::SetupProfile::' . ucfirst($profile);

    load_class $class_profile;

    return $class_profile->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
