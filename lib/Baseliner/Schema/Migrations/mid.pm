package Baseliner::Schema::Migrations::mid;
use Mouse;

sub upgrade {
    mdb->migra->mids;
}

sub downgrade {
    
}

1;

