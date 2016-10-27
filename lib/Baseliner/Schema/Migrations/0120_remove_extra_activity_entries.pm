package Baseliner::Schema::Migrations::0120_remove_extra_activity_entries;
use Moose;

sub upgrade {
    my $self = shift;
    mdb->activity->remove( { event_key => { '$not' => qr/event.topic|event.file|event.post|event.ci/ } } );
}

sub downgrade {
}

1;
