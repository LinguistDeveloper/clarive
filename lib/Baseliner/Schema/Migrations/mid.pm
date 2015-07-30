package Baseliner::Schema::Migrations::mid;
use Moose;

sub upgrade {
    mdb->migra->mids;
}

sub downgrade {
    
}

1;

