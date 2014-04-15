package Baseliner::Schema::Migrations;
use Mouse;

sub upgrade {
    mdb->migra->notifications;
}

sub downgrade {
    
}

1;
