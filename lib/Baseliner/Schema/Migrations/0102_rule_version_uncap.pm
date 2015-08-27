package Baseliner::Schema::Migrations::0102_rule_version_uncap;
use Moose;

sub upgrade {
    mdb->rule_version->clone('rule_version_capped');
    mdb->rule_version->drop;
    my $rs = mdb->rule_version_capped->find;
    while( my $r = $rs->next ) {
        mdb->rule_version->insert( $r );
    }
    # for safety:
    mdb->rule_version_capped->drop 
        if mdb->rule_version_capped->count == mdb->rule_version->count;
}

sub downgrade {
    # no need to go back to capped, ever
}

1;



