use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Baseliner::IdenticonGenerator';

subtest 'identicon: when no user generate identican anyway' => sub {
    _setup();

    my $png = _build_identicon_generator()->identicon('unknown');

    like $png, qr/^.PNG/;
};

subtest 'identicon: when user found return png' => sub {
    _setup();

    my $user = TestUtils->create_ci( 'user', username => 'developer' );

    my $png = _build_identicon_generator()->identicon('developer');

    like $png, qr/^.PNG/;
};

subtest 'identicon: when user found save to user' => sub {
    _setup();

    my $user = TestUtils->create_ci( 'user', username => 'developer' );

    my $png = _build_identicon_generator()->identicon('developer');

    $user = ci->new( $user->{mid} );

    like $user->avatar, qr/^.PNG/;
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );
    TestUtils->cleanup_cis;
}

sub _build_identicon_generator {
    Baseliner::IdenticonGenerator->new();
}

