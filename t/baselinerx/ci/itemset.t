use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use BaselinerX::CI::itemset;

subtest 'new: builds ci' => sub {
    _setup();

    my $ci = BaselinerX::CI::itemset->new( name => 'foo' );

    ok $ci;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',  'BaselinerX::Type::Event',
        'BaselinerX::Type::Service', 'BaselinerX::Type::Statement',
        'Baseliner::CI',             'BaselinerX::CI'
    );

    TestUtils->cleanup_cis;
}
