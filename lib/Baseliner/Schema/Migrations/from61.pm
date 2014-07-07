package Baseliner::Schema::Migrations::from61;
use Mouse;

sub upgrade {
    # 6.1:
    mdb->migra->master_insert;
    mdb->migra->mids;
    mdb->migra->master_rel_add;  # insert missing rels
    mdb->migra->topic_admin;
    mdb->migra->statuses_from_db;
    mdb->migra->topic_fields;
    mdb->migra->scheduler;
    mdb->migra->config;
    mdb->migra->notifications;
    mdb->migra->dashboards;
    mdb->migra->daemons;
    mdb->migra->repository_repl;
    mdb->migra->topic_rels;
    mdb->migra->role;
    mdb->migra->topic_images;
    mdb->migra->posts;
    mdb->migra->statuses;
    mdb->migra->master_doc_clean;
    mdb->migra->master_cal;
    mdb->migra->topic_assets;
    mdb->session->drop;
    mdb->cache->drop;
}

sub downgrade {
    
}

1;


