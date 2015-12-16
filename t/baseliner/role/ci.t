use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
use TestUtils;

BEGIN { TestEnv->setup; }

use Baseliner::CI;
use Clarive::ci;
use Baseliner::Core::Registry;
use Baseliner::Role::CI;
use BaselinerX::CI::TestClass;
use BaselinerX::CI::TestAnother;
use BaselinerX::CI::TestParentClass;
use BaselinerX::CI::TestGrandParent;
use Clarive::cache;

subtest 'returns true when deleting ci' => sub {
    _setup();

    my $ci = _build_ci();
    $ci->save;

    is $ci->delete, 1;
};

subtest 'returns false when deleting not loaded ci' => sub {
    _setup();

    my $ci = _build_ci();

    is $ci->delete, 0;
};

subtest 'returns false when deleting deleted ci' => sub {
    _setup();

    my $old_ci = _build_ci();
    my $mid = $old_ci->save;

    $old_ci->delete;

    is(ci->delete($mid), 0);
};

subtest 'children store into parent' => sub {
    _setup();

    my $chi = _build_ci();
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

subtest 'children retrieved as array but stored as value' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new( kids=>$chi_mid );
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

subtest 'children retrieved as array but stored as value in method' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new;
    $dad->kids( $chi_mid );
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

subtest 'children retrieved as array but stored as array in method' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new;
    $dad->kids( $chi_mid );
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

###########################################################################################

subtest 'children obj store into parent' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi]);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

subtest 'children retrieved as array but obj stored as value' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new( kids=>$chi);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

subtest 'children retrieved as array but obj stored as value in method' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new;
    $dad->kids( $chi );
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};

subtest 'children retrieved as array but obj stored as array in method' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new;
    $dad->kids( $chi );
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    is $dad2->kids->[0]->mid, $chi_mid;
};


########################################################################

subtest 'related cis returns docs only' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    my @rels = $dad2->related( depth=>1, docs_only=>1 );
    is $rels[0]->{mid}, $chi_mid;
    is ref $rels[0], 'HASH', "it's a doc";
};

subtest 'related cis returns ci object' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    my @rels = $dad2->related( depth=>1, docs_only=>0 );
    is $rels[0]->{mid}, $chi_mid;
    is ref $rels[0], 'BaselinerX::CI::TestClass';
};

subtest 'related cis returns mids only' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    my @rels = $dad2->related( depth=>1, mids_only=>1 );
    is $rels[0]->{mid}, $chi_mid;
    is ref $rels[0], 'HASH';
};

subtest 'gen_mid: correctly generated mid format' => sub {
    _setup();
    
    my $chi = BaselinerX::CI::TestClass->new;
    like $chi->gen_mid, qr/^TestClass-\d+$/ ;

};

subtest 'ci save is in cache' => sub {
    _setup();

    cache->setup('mongo');  # otherwise cache is fake
    my $ci = BaselinerX::CI::TestClass->new( something=>333 );
    my $mid = $ci->save;
    $ci = ci->new( $mid );
    my $ci_cache = cache->get({ d=>'ci', mid=>$mid });
    is( $ci_cache->{something}, $ci->something );
};

subtest 'ci save results in no ci in cache' => sub {
    _setup();
    
    cache->setup('mongo');  # otherwise cache is fake
    my $ci = BaselinerX::CI::TestClass->new( something=>333 );
    my $mid = $ci->save;
    $ci = ci->new( $mid );
    $ci->something( 444 );
    $ci->save;
    my $ci_cache = cache->get({ d=>'ci', mid=>$mid });
    is $ci_cache->{something}, undef;
};

subtest 'ci save: cache is synchronized with latest data' => sub {
    _setup();
    
    cache->setup('mongo');  # otherwise cache is fake
    my $ci = BaselinerX::CI::TestClass->new( something=>333 );
    my $mid = $ci->save;
    $ci = ci->new( $mid );
    $ci->something( 444 );
    $ci->save;
    $ci = ci->new( $mid );
    my $ci_cache = cache->get({ d=>'ci', mid=>$mid });
    is $ci_cache->{something}, $ci->something; 
};

subtest 'ci sequencing saved in new CI' => sub {
    _setup();
    
    my $prev_seq = mdb->seq('ci-seq');
    my $ci = BaselinerX::CI::TestClass->new();
    my $mid = $ci->save;
    $ci = ci->new( $mid );
    is $ci->_seq, $prev_seq + 1;
};

subtest 'ci sequencing available immediatly after save' => sub {
    _setup();
    
    my $ci = BaselinerX::CI::TestClass->new();
    my $mid = $ci->save;
    ok length $ci->_seq;
};

subtest 'ci sorting by sequence is correct' => sub {
    _setup();
    
    for my $ii ( 1..11 ) {
        my $ci = BaselinerX::CI::TestClass->new(something=>$ii);
        my $mid = $ci->save;
    }
    my @cis = ci->TestClass->find->sort({ _seq=>-1 })->all;
    is $cis[0]->{something}, 11;
    is $cis[$#cis]->{something}, 1;
};

subtest 'save: control mid characters' => sub{
    _setup();
    
    my $ci = BaselinerX::CI::TestClass->new(mid=>'bad#mid');
    like exception { $ci->save }, qr/cannot contain.*#/;
};

subtest 'save: related single ci stored in master_doc as one mid, not array' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(the_kid=>[$chi_mid]);
    my $dad_mid = $dad->save;

    my $doc = ci->TestParentClass->find_one({ mid=>"$dad_mid" });
    is ref $doc, 'HASH';
    is $doc->{the_kid}, $chi_mid;
};

subtest 'save: related cis stored in master_doc as array of mids' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;

    my $doc = ci->TestParentClass->find_one({ mid=>"$dad_mid" });
    is ref $doc, 'HASH';
    is $doc->{kids}->[0], $chi_mid;
};

subtest 'save: related cis get deleted when removed' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;
    
    my $dad2 = ci->new( $dad_mid );
    $dad2->kids([]);
    $dad2->save;

    my $doc = ci->TestParentClass->find_one({ mid=>"$dad_mid" });
    is ref $doc, 'HASH';
    ok exists $doc->{kids};
    is_deeply $doc->{kids}, [];
};

subtest 'save: related single ci gets deleted when removed' => sub {
    _setup();

    my $chi = BaselinerX::CI::TestClass->new;
    my $chi_mid = $chi->save;

    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi_mid]);
    my $dad_mid = $dad->save;
    
    my $dad2 = ci->new( $dad_mid );
    $dad2->kids([]);
    $dad2->save;

    my $doc = ci->TestParentClass->find_one({ mid=>"$dad_mid" });
    is ref $doc, 'HASH';
    ok exists $doc->{kids};
    is_deeply $doc->{kids}, [];
};

subtest 'save: all related are saved in 2 steps' => sub {
    _setup();

    my $chi1 = BaselinerX::CI::TestClass->new;
    my $chi1_mid = $chi1->save;
    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi1]);
    my $dad_mid = $dad->save;

    my $dad2 = ci->new( $dad_mid );
    my $chi2 = BaselinerX::CI::TestClass->new;
    my $chi2_mid = $chi2->save;
    $dad2->kids([ @{ $dad2->kids },$chi2]);
    $dad2->save;

    my $doc = ci->TestParentClass->find_one({ mid=>"$dad_mid" });
    is ref $doc, 'HASH';
    ok exists $doc->{kids};
    is_deeply $doc->{kids}, [$chi1_mid,$chi2_mid];

    my @rels = $dad2->related;
    is @rels, 2;
    is_deeply( [map{ $_->{mid} } @rels], [$chi1_mid,$chi2_mid] );
};

subtest 'save: relations are saved with from and to collections' => sub {
    _setup();

    my $chi1 = BaselinerX::CI::TestClass->new;
    my $chi1_mid = $chi1->save;
    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi1]);
    my $dad_mid = $dad->save;

    my @rels = mdb->master_rel->find({ from_mid=>$dad_mid })->all;
    is @rels, 1;
    is $rels[0]->{from_cl}, 'TestParentClass';
    is $rels[0]->{to_cl}, 'TestClass';
};

subtest 'save: reverse relations are saved with from and to collections' => sub {
    _setup();

    my $gran = BaselinerX::CI::TestGrandParent->new;
    $gran->save;
    my $dad = BaselinerX::CI::TestParentClass->new( grandad=>$gran );
    my $dad_mid = $dad->save;

    my @rels = mdb->master_rel->find({ to_mid=>$dad_mid })->all;
    is @rels, 1;
    is $rels[0]->{from_cl}, 'TestGrandParent';
    is $rels[0]->{to_cl}, 'TestParentClass';
};

subtest 'children: include by include_cl' => sub {
    _setup();

    my $chi1 = BaselinerX::CI::TestClass->new;
    my $chi1_mid = $chi1->save;
    my $chi2 = BaselinerX::CI::TestAnother->new;
    my $chi2_mid = $chi2->save;
    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi1,$chi2]);
    my $dad_mid = $dad->save;
    my $dad2 = ci->new( $dad_mid );

    my @rels = $dad2->related( include_cl => 'TestAnother' );
    is @rels, 1;
    is $rels[0]->{mid}, $chi2_mid;
};

subtest 'children: exclude by exclude_cl' => sub {
    _setup();

    my $chi1 = BaselinerX::CI::TestClass->new;
    my $chi1_mid = $chi1->save;
    my $chi2 = BaselinerX::CI::TestAnother->new;
    my $chi2_mid = $chi2->save;
    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi1,$chi2]);
    my $dad_mid = $dad->save;
    my $dad2 = ci->new( $dad_mid );

    my @rels = $dad2->related( exclude_cl => 'TestAnother' );
    is @rels, 1;
    is $rels[0]->{mid}, $chi1_mid;
};

subtest 'children: exclude many with array' => sub {
    _setup();

    my $chi1 = BaselinerX::CI::TestClass->new;
    my $chi1_mid = $chi1->save;
    my $chi2 = BaselinerX::CI::TestAnother->new;
    my $chi2_mid = $chi2->save;
    my $dad = BaselinerX::CI::TestParentClass->new(kids=>[$chi1,$chi2]);
    my $dad_mid = $dad->save;
    my $dad2 = ci->new( $dad_mid );

    my @rels = $dad2->related( exclude_cl => ['TestClass', 'TestAnother'] );
    is @rels, 0;
};

subtest 'save: check unique_keys gives error on duplicate' => sub {
    _setup();

    eval {
        my $ci1 = BaselinerX::CI::TestParentClass->new( name=>'ci1', test_attr=>'aa' );
        my $ci1_mid = $ci1->save;

        my $ci2 = BaselinerX::CI::TestParentClass->new( name=>'ci2', test_attr=>'aa' );
        my $ci2_mid = $ci2->save;
    };

    ok length $@, "verify fails on test_attr";
};

subtest 'save: check unique_keys are ok with empty' => sub {
    _setup();

    eval {
        my $ci1 = BaselinerX::CI::TestParentClass->new( name=>'ci1', test_attr=>'' );
        my $ci1_mid = $ci1->save;

        my $ci2 = BaselinerX::CI::TestParentClass->new( name=>'ci2', test_attr=>'' );
        my $ci2_mid = $ci2->save;
    };

    ok ! length $@, "verify fails on moniker";
};

sub _setup {
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_cis;
    TestUtils->register_ci_events;
}

sub _build_ci {
    BaselinerX::CI::TestClass->new(@_);
}

done_testing;
