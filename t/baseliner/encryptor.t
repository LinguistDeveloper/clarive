use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Baseliner::Encryptor';

subtest 'core encrypt-decrypt working' => sub {
    _setup();

    Clarive->config->{decrypt_key} = '11111';

    my $enc = Baseliner::Encryptor->encrypt('123');
    is( Baseliner::Encryptor->decrypt($enc), '123' );
};

done_testing;

sub _setup {
}
