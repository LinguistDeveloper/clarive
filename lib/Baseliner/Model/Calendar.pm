package Baseliner::Model::Calendar;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_loc);
use Try::Tiny;
use v5.10;

sub delete {
    my ( $self, %params ) = @_;

    my $ids      = $params{ids};
    my $username = $params{username};

    mdb->calendar->remove( { id => mdb->in($ids) } );
    mdb->calendar_window->remove( { id_cal => mdb->in($ids) } );

    return _loc('Calendar(s) deleted');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
