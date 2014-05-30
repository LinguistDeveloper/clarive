package Baseliner::Schema::Migrations::role;
use Mouse;

sub upgrade {
    mdb->migra->role;
}

sub downgrade {
    
}

1;