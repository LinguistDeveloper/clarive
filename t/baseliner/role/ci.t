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
use BaselinerX::CI::TestParentClass;
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

subtest 'gen_mid: correctly generated mid' => sub {
    _setup();
    
    my $chi = BaselinerX::CI::TestClass->new;
    like $chi->gen_mid, qr/^TestClass-\d{6}$/ ;

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

sub _setup {
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_cis;
    TestUtils->register_ci_events;
}

sub _build_ci {
    BaselinerX::CI::TestClass->new(@_);
}

done_testing;
