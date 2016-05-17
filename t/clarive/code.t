use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code';

subtest 'eval_code: dispatches to js' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code( '1 + 1', lang => 'js' );

    is_deeply $ret, { ret => 2, error => undef };
};

subtest 'eval_code: dispatches to perl' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code( '1 + 1', lang => 'perl' );

    is_deeply $ret, { ret => 2, error => undef };
};

subtest 'eval_code: catches errors' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code( 'throw new Error()' );

    cmp_deeply $ret, { ret => undef, error => re(qr/Error/) };
};

subtest 'eval_code: benchmark code' => sub {
    my $code = _build_code( benchmark => 1 );

    my $ret = $code->eval_code( q{var x=1; x++;} );

    ok $ret->{elapsed} > 0;
};

subtest 'run_file: executes code from file' => sub {
    my $filename = TestUtils->create_temp_file( "1 + 1", 'file.js' );

    my $code = _build_code();

    my $ret = $code->eval_file( $filename );

    is $ret->{ret}, 2;
};

done_testing;

sub _build_code {
    Clarive::Code->new(@_);
}
