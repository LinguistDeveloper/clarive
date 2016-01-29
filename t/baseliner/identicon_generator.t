use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Baseliner::IdenticonGenerator';

subtest 'identicon: generates identicon' => sub {
    my $png = _build_identicon_generator()->identicon;

    like $png, qr/^.PNG/;
};

subtest 'identicon: returns default icon when generate fails' => sub {
    my $generator = _build_identicon_generator();
    $generator = Test::MonkeyMock->new($generator);
    $generator->mock( _generate => sub { die 'some error' } );

    my $png = $generator->identicon();

    like $png, qr/^.PNG/;
};

done_testing;

sub _build_identicon_generator {
    Baseliner::IdenticonGenerator->new( default_icon => 'root/static/images/icons/user.png' );
}

