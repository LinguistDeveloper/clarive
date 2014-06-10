package Baseliner::Schema::Migrations::posts 3;
use Mouse;

sub upgrade {
    mdb->migra->posts;
}

sub downgrade {
    
}

1;



