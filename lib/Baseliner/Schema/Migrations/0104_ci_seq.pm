package Baseliner::Schema::Migrations::0104_ci_seq;
use Moose;

sub upgrade {
    my $rs = mdb->master->find->fields({ mid=>1, _id=>1 })->sort({ _id=>1 });
    mdb->seq('ci-seq',0);
    while( my $ci = $rs->next ) {
       my $_seq = mdb->seq('ci-seq');
       warn "Migration: Applying sequence to mid=$ci->{mid} ==> seq=$_seq\n";
       mdb->master->update({ mid=>$ci->{mid} },{ '$set'=>{_seq=>$_seq} });
       mdb->master_doc->update({ mid=>$ci->{mid} },{ '$set'=>{_seq=>$_seq} });
    }

    mdb->master->ensure_index({ _seq=>1 },{ unique=>1 });
    mdb->master_doc->ensure_index({ _seq=>1 },{ unique=>1 });
}

sub downgrade {
    # not needed, no harm in having a _seq in there
}

1;

