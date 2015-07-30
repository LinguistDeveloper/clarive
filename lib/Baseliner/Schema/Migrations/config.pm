package Baseliner::Schema::Migrations::config;
use Moose;

sub upgrade {
    mdb->migra->config;
}

sub downgrade {
    
}

1;

