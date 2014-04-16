package Baseliner::Schema::Migrations::dashboard;
use Mouse;

sub upgrade {
    mdb->migra->dashboards;
}

sub downgrade {
    
}

1;