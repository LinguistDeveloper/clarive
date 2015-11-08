package Baseliner::Schema::Migrations::daemon;
use Moose;

sub upgrade {
    mdb->migra->daemons;
}

sub downgrade {
    
}

1;
