package Baseliner::Schema::Migrations::dashboard;
use Moose;

sub upgrade {
    mdb->migra->dashboards;
}

sub downgrade {
    
}

1;
