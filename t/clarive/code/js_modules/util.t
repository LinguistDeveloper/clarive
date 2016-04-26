use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code::JS';

subtest 'load yaml util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $hash = $code->eval_code(q{
        var util = require("cla/util");
        var yaml="---\nfoo: bar\n"; util.loadYAML(yaml)});

    is_deeply $hash, { foo=>'bar' };
};

subtest 'dump yaml util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $yaml = $code->eval_code(q{
        var util = require("cla/util");
        util.dumpYAML({ foo: 'bar' })});

    like $yaml, qr/foo: bar/;
};

subtest 'load json util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $hash = $code->eval_code(q{
        var util = require("cla/util");
        var json='{ "foo":"bar" }'; util.loadJSON(json)});

    is_deeply $hash, { foo=>'bar' };
};

subtest 'dump json util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $json = $code->eval_code(q{
        var util = require("cla/util");
        util.dumpJSON({ foo: 'bar' })});

    like $json, qr/"foo"\s*:\s*"bar"/;
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}

