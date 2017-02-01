package Baseliner::Schema::Migrations::0125_update_mongo_index;
use Moose;

sub upgrade {
    mdb->master_doc->ensure_index( { name => 1, collection => 1, moniker => 1 } );
    mdb->master_doc->ensure_index( { status         => 1,  step       => 1 } );
    mdb->master_doc->ensure_index( { 'projects.mid' => 1,  starttime  => -1, collection => 1 } );
    mdb->master_doc->ensure_index( { 'projects.mid' => 1,  collection => 1, starttime => -1 } );
    mdb->master_doc->ensure_index( { starttime      => -1, collection => 1 } );
    mdb->master_doc->ensure_index( { maxstarttime   => 1,  collection => 1, status => 1 } );
    mdb->master_doc->ensure_index( { now            => 1,  collection => 1, status => 1, host => 1, step => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, now => 1, status => 1, starttime => -1, step => 1, host => 1 } );
    mdb->master_doc->ensure_index(
        { schedtime => 1, maxstarttime => 1, status => 1, host => 1, step => 1, collection => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, projects => 1 } );
    mdb->master_doc->ensure_index( { host => 1, status => 1, collection => 1, step => 1, now => 1 } );
    mdb->master_doc->ensure_index(
        { host => 1, collection => 1, step => 1, status => 1, maxstarttime => 1, schedtime => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, projects => 1, bl           => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, pid      => 1, status       => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, status   => 1, maxstarttime => 1 } );
    mdb->master_doc->ensure_index( { now        => 1, step     => 1, collection   => 1, status => 1, host => 1 } );
    mdb->master_doc->ensure_index( { step => 1, collection => 1, starttime => -1, host => 1, status => 1, now => 1 } );
    mdb->master_doc->ensure_index(
        { maxstarttime => 1, status => 1, schedtime => 1, host => 1, step => 1, collection => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, starttime => 1, bl       => 1, projects  => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, bl        => 1, projects => 1, starttime => -1 } );
    mdb->master_doc->ensure_index( { collection => 1, starttime => -1 } );

    mdb->rule_version->ensure_index( { _id     => 1 } );
    mdb->rule_version->ensure_index( { id_rule => 1 } );
    mdb->rule_version->ensure_index( { id      => 1, deleted => 1 } );
    mdb->rule_version->ensure_index( { id_rule => 1, _id => 1 } );
    mdb->rule_version->ensure_index( { id_rule => 1, version_tag => 1 } );
    mdb->rule_version->ensure_index( { id_rule => 1, _id => 1, version_tag => 1 } );
}

sub downgrade {
}

1;
