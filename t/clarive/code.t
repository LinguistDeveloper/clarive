use strict;
use warnings;

use Test::More;
use Test::Fatal;

use_ok 'Clarive::Code';

subtest 'eval_code: dispatches to js' => sub {
    my $code = _build_code(lang => 'js');

    my $ret = $code->eval_code('1 + 1', {});

    is $ret, 2;
};

subtest 'eval_code: benchmark js code' => sub {
    my $code = _build_code( lang => 'js', benchmark=>1 );
    $code->eval_code(q{var x=1; x++;});
    ok $code->elapsed > 0;   
};

done_testing;

sub _build_code {
    Clarive::Code->new(@_);
}
