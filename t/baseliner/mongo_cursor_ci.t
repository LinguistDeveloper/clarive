use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Baseliner::MongoCursorCI';

subtest 'wraps next' => sub {
    _setup();

    TestUtils->create_ci( 'status', name => 'New' );

    my $cursor = mdb->master_doc->find();

    $cursor = Baseliner::MongoCursorCI->new( cursor => $cursor );

    my $ci = $cursor->next;

    is $ci->name, 'New';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
    );

    TestUtils->cleanup_cis;
}
