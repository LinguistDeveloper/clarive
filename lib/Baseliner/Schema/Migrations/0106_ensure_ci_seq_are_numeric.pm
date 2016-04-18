package Baseliner::Schema::Migrations::0106_ensure_ci_seq_are_numeric;
use Moose;

sub upgrade {
    mdb->master->drop_index( { _seq => 1 }, { unique => 1 } );
    mdb->master_doc->drop_index( { _seq => 1 }, { unique => 1 } );

    mdb->seq( 'ci-seq', 0 );

    my @cis_with_numeric_mids = sort { $a->{mid} <=> $b->{mid} }
      mdb->master->find( { mid => { '$regex' => '^\d+$' } } )->fields( { _id => 0, mid => 1 } )->all;

    my @cis_with_mixed_mids_aligned = sort { ( $a->{mid} =~ m/(\d+)$/ )[0] <=> ( $b->{mid} =~ m/(\d+)$/ )[0] }
      mdb->master->find( { mid => { '$regex' => '^[^\d]+-\d{6}$' } } )->fields( { _id => 0, mid => 1 } )->all;

    my @cis_with_mixed_mids = sort { ( $a->{mid} =~ m/(\d+)$/ )[0] <=> ( $b->{mid} =~ m/(\d+)$/ )[0] }
      mdb->master->find( { mid => { '$regex' => '^[^\d]+-\d{1,5}$' } } )->fields( { _id => 0, mid => 1 } )->all;

    my %master_mids = ();
    foreach my $ci ( @cis_with_numeric_mids, @cis_with_mixed_mids_aligned, @cis_with_mixed_mids ) {
        my $_seq = 0 + mdb->seq('ci-seq');

        warn "Migration: Applying sequence to mid=$ci->{mid} ==> seq=$_seq\n";

        mdb->master->update( { mid => "$ci->{mid}" }, { '$set' => { _seq => 0 + $_seq } } );
        mdb->master_doc->update( { mid => "$ci->{mid}" }, { '$set' => { _seq => 0 + $_seq } } );

        $master_mids{$ci->{mid}}++;
    }

    my $master_doc_iter = mdb->master_doc->find()->fields({_id => 0, mid => 1});
    while( my $ci = $master_doc_iter->next ) {
        if (!exists $master_mids{$ci->{mid}}) {
            warn "Migration: Removing master_doc=$ci->{mid} because no related entry in master was found\n";

            mdb->master_doc->remove({mid => "$ci->{mid}"});
        }
    }

    mdb->master->ensure_index( { _seq => 1 }, { unique => 1 } );
    mdb->master_doc->ensure_index( { _seq => 1 }, { unique => 1 } );
}

sub downgrade {

    # not needed, no harm in having a _seq in there
}

1;
