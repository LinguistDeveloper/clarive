package Baseliner::Schema::Migrations::from62;
use Moose;

#cla db-upgrade --migrate from62 

sub upgrade {
    # 6.2:
    mdb->migra->activity_to_status_changes;
    mdb->migra->closed_date;
    mdb->migra->topic_categories_to_rules;
    mdb->migra->create_initial_dashboards;
    mdb->cache->drop;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


