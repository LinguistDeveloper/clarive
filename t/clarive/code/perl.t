use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code::Perl';

subtest 'executes perl' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code('1 + 1');

    is $ret, 2;
};

subtest 'returns multiple values as array ref' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code('(1, 2, 3)');

    is_deeply $ret, [1, 2, 3];
};

subtest 'executes perl > 5.10' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code('say "hi"');

    is $ret, 1;
};

subtest 'no error when not a true value' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code('0');

    is $ret, 0;
};

subtest 'rethrows errors' => sub {
    my $code = _build_code();

    like exception { $code->eval_code('die "here"') }, qr/here at EVAL line 1/;
};

subtest 'rethrows errors with zeroish exceptions' => sub {
    my $code = _build_code();

    like exception { $code->eval_code('die ""') }, qr/Died at EVAL line 1/;
    like exception { $code->eval_code('die 0') }, qr/0 at EVAL line 1/;
    like exception { $code->eval_code('die undef') }, qr/Died at EVAL line 1/;
};

subtest 'rethrows errors with filename' => sub {
    my $code = _build_code(filename => 'some-file.pl');

    like exception { $code->eval_code('die "here"') }, qr/here at some-file.pl line 1/;
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    TestUtils->cleanup_cis;
}

sub _build_code {
    Clarive::Code::Perl->new(@_);
}
