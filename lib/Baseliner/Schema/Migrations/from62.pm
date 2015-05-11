package Baseliner::Schema::Migrations::from62;
use Mouse;

sub upgrade {
    # 6.2:
    mdb->migra->closed_date;
    mdb->cache->drop;
}

sub downgrade {
    
}

1;


