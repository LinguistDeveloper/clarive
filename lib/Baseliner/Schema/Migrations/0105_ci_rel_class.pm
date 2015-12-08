package Baseliner::Schema::Migrations::0105_ci_rel_class;
use Moose;

sub upgrade {
    my %mid_colls = map { $$_{mid} => $$_{collection} } 
        mdb->master->find->fields({ mid=>1, collection=>1 })->all;
    my $rs = mdb->master_rel->find->sort({ _id=>1 });
    while( my $rel = $rs->next ) {
        my $from_mid = $rel->{from_mid};
        my $to_mid = $rel->{to_mid};
        my $from_cl = $mid_colls{$from_mid} // undef;
        my $to_cl = $mid_colls{$to_mid} // undef;
        mdb->master_rel->update({ _id=>$rel->{_id} },{ '$set'=>{ from_cl=>$from_cl, to_cl=>$to_cl } });
    }
    mdb->master_rel->ensure_index({ from_cl=>1 });
    mdb->master_rel->ensure_index({ to_cl=>1 });
    mdb->master_rel->ensure_index({ from_cl=>1, to_cl=>1 });
}

sub downgrade {
    # not needed, no harm in having a _seq in there
}

1;


