package Baseliner::Schema::Migrations::topic_admin 5;
use Mouse;

sub upgrade {
    mdb->migra->topic_admin;
}

sub downgrade {
    
}

1;


