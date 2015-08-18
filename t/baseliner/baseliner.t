use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst', 'mock_time';

BEGIN {
    TestEnv->setup;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Role::CI;
use Baseliner::Core::Registry;

# mock Baseliner subs
our $config = {}; 
require Baseliner;
sub Baseliner::config { $config };  # XXX had to monkey patch this one so config works

subtest 'core encrypt-decrypt working' => sub {
    Baseliner->config->{decrypt_key} = '11111';
    my $enc = Baseliner->encrypt( '123' );
    is '123', Baseliner->decrypt( $enc );
};

done_testing;
