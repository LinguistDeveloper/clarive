package Baseliner::Schema::Migrations::topic_rels;
use Mouse;

sub upgrade {
    # 6.1:
    mdb->migra->topic_rels;
}

sub downgrade {
    
}

1;


