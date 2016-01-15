use strict;
use warnings;

use Test::More;
use Test::Fatal;

use_ok 'Baseliner::Code';

subtest 'eval_code: dispatches to js' => sub {
    my $code = _build_code(lang => 'js');

    my $ret = $code->eval_code('1 + 1', {});

    is $ret, 2;
};

done_testing;

sub _build_code {
    Baseliner::Code->new(@_);
}
