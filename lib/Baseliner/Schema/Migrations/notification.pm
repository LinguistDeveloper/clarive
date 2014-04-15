package Baseliner::Schema::Migrations::notification;
use Mouse;

sub upgrade {
    mdb->migra->notifications;
}

sub downgrade {
    
}

1;
