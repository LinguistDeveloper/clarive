package Baseliner::Schema::Migrations::0104_ci_seq;
use Moose;

sub upgrade {
    my %master_mids;

    mdb->master->drop_index({ _seq=>1 },{ unique=>1 });
    mdb->master_doc->drop_index({ _seq=>1 },{ unique=>1 });

    mdb->seq('ci-seq',0);

    my @cis = sort { $a->{mid} <=> $b->{mid} } mdb->master->find->fields( { mid => 1, _id => 1 } )->all;

    foreach my $ci (@cis) {
       my $_seq = mdb->seq('ci-seq');

       warn "Migration: Applying sequence to mid=$ci->{mid} ==> seq=$_seq\n";

       mdb->master->update({ mid=>$ci->{mid} },{ '$set'=>{_seq=>$_seq} });
       mdb->master_doc->update({ mid=>$ci->{mid} },{ '$set'=>{_seq=>$_seq} });

       $master_mids{$ci->{mid}}++;
    }

    my $master_doc_iter = mdb->master_doc->find({_seq => undef}, {mid => 1});
    while( my $ci = $master_doc_iter->next ) {
        if (!exists $master_mids{$ci->{mid}}) {
            warn "Migration: Removing master_doc=$ci->{mid} because no related entry in master was found\n";

            mdb->master_doc->remove({mid => $ci->{mid}});
        }
    }

    mdb->master->ensure_index({ _seq=>1 },{ unique=>1 });
    mdb->master_doc->ensure_index({ _seq=>1 },{ unique=>1 });
}

sub downgrade {
    # not needed, no harm in having a _seq in there
}

1;

