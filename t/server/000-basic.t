use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;

BEGIN {
    plan skip_all => 'set TEST_LIVE to run this test' unless $ENV{TEST_LIVE};
}

my $ag = Clarive::Test->user_agent;
#$ag->success or die $ag->response->status_line;

# Get some CIs
$ag->get( '/ci/store' );
my $json = _decode_json( $ag->content );
say "Total Count: " . $json->{totalCount};
ok $json->{totalCount} > 0, 'ci store has CIs';

done_testing;
