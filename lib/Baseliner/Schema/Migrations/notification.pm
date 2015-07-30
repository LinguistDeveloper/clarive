package Baseliner::Schema::Migrations::notification;
use Moose;

sub upgrade {
    mdb->migra->notifications;
}

sub downgrade {
    
}

1;
