use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code::JS';

subtest 'console testing' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{
        var con = require('cla/console');
        con.log({aa:11});
        con.warn('hello there');
        con.dir({aa:22});
        con.dir(cla.regex('x'));
        con.assert(true, 'nada');
    });
    ok 1, 'we are alive here';
};

subtest 'console testing' => sub {
    my $code = _build_code( lang => 'js' );

    like exception( sub { $code->eval_code(q{
        var con = require('cla/console');
        con.assert(false, 'Oh my god %d', 10);
    }) } ), qr/assert.*10/i;
};

done_testing;

sub _build_code {
    Clarive::Code::JS->new(@_);
}

