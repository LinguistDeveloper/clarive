package Baseliner::Schema::Migrations::config;
use Mouse;

sub upgrade {
    mdb->migra->config;
}

sub downgrade {
    
}

1;

