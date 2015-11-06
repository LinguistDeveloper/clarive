package Baseliner::Controller::Test;
use Moose;
BEGIN { extends 'Catalyst::Controller'; }

use Clarive::mdb;
use Clarive::App;
use Clarive::Cmd::init;
use Clarive::Cmd::migra;

sub setup : Local {
    my ( $self, $c ) = @_;

    if ( $ENV{CLARIVE_TEST} ) {
        my $dbname = Clarive->config->{mongo}->{dbname};

        die "Database '$dbname' doesn't look like a test database to me" unless $dbname && $dbname =~ m/^test/;

        my $app = Clarive::App->new( env => $ENV{CLARIVE_ENV} );

        Clarive::Cmd::init->new( app => $app, opts => {} )->run( args => { yes => 1, reset => 1 } );
        Clarive::Cmd::migra->new( app => $app, opts => {} )->run( args => { yes => 1, force => 1 } );

        $c->stash( json => { msg => 'ok' } );
        $c->forward('View::JSON');
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
