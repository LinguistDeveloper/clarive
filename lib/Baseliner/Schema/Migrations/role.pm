package Baseliner::Schema::Migrations::role;
use Moose;

sub upgrade {
    mdb->migra->role;
}

sub downgrade {
    
}

1;
