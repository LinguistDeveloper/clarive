use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Time::HiRes qw(gettimeofday tv_interval);

use_ok 'Clarive::Code::JS';

subtest 'sleep: sleeps for n seconds' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $t0 = [ gettimeofday() ];

    $code->eval_code(
        q{
        var util = require("cla/util");
        util.sleep(0.1);
        }
    );

    ok tv_interval($t0) > 0.1;
};

subtest 'benchmark: benchmarks code' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $t0 = [ gettimeofday() ];

    $code->eval_code(
        q{
        var util = require("cla/util");
        util.benchmark(1, function() { util.sleep(0.1) });
        }
    );

    ok tv_interval($t0) > 0.1;
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
