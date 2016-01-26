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

    foreach my $ci ( @cis_with_numeric_mids, @cis_with_mixed_mids_aligned, @cis_with_mixed_mids ) {
        my $_seq = 0 + mdb->seq('ci-seq');

        warn "Migration: Applying sequence to mid=$ci->{mid} ==> seq=$_seq\n";

        mdb->master->update( { mid => "$ci->{mid}" }, { '$set' => { _seq => $_seq } } );
        mdb->master_doc->update( { mid => "$ci->{mid}" }, { '$set' => { _seq => $_seq } } );
    }

    mdb->master->ensure_index( { _seq => 1 }, { unique => 1 } );
    mdb->master_doc->ensure_index( { _seq => 1 }, { unique => 1 } );
}

sub downgrade {

    # not needed, no harm in having a _seq in there
}

1;

