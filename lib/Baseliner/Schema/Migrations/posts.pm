package Baseliner::Schema::Migrations::posts 3;
use Moose;

sub upgrade {
    mdb->migra->posts;
}

sub downgrade {
    
}

1;



