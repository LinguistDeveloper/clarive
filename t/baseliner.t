use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Role::CI;
use Baseliner::Core::Registry;

# mock Baseliner subs
our $config = {};
require Baseliner;
no warnings 'redefine';
sub Baseliner::config { $config };    # XXX had to monkey patch this one so config works

subtest 'core encrypt-decrypt working' => sub {
    Baseliner->config->{decrypt_key} = '11111';

    my $enc = Baseliner->encrypt('123');
    is(Baseliner->decrypt($enc), '123');
};

done_testing;
