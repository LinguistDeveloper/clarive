use strict;
use warnings;
use lib 't/lib';

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }

use TestUtils;

use Clarive::ci;

use_ok('BaselinerX::CI::nature');

subtest 'push_item: pushes item matching nature' => sub {
    my $ci = ci->nature->new( include => '/ok/' );

    my $item_ci  = ci->item->new( source => 'ok',     path => '/ok/path' );
    my $item_ci2 = ci->item->new( source => 'not_ok', path => '/not_ok/path' );

    $ci->push_item($item_ci);

    my $items = $ci->items;

    is scalar @$items, 1;
    is $items->[0]->source, 'ok';
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry( 'BaselinerX::CI', 'BaselinerX::Type::Event' );
}
