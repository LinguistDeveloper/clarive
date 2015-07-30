package Baseliner::Schema::Migrations::notification;
use Moose;

sub upgrade {
    mdb->migra->notifications;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
