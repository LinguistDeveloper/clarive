package Baseliner::Model::Calendar;
use Moose;
BEGIN { extends 'Catalyst::Model' }

sub delete_multi {
    my $self = shift;
    my (%params) = @_;

    my $ids = $params{ids};

    mdb->calendar->remove( { id => mdb->in($ids) } );
    mdb->calendar_window->remove( { id_cal => mdb->in($ids) } );

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
