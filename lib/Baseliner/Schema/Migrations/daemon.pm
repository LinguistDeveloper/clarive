package Baseliner::Schema::Migrations::daemon;
use Mouse;

sub upgrade {
    mdb->migra->daemons;
}

sub downgrade {
    
}

1;