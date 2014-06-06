package Baseliner::Schema::Migrations::topic_admin;
use Mouse;

our $VERSION = 3;

sub upgrade {
    mdb->migra->topic_admin;
}

sub downgrade {
    
}

1;


