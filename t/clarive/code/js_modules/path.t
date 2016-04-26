use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code::JS';

subtest 'dispatches to path' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    is $code->eval_code(q{
        var path = require("cla/path");
        path.basename('/foo/bar.baz')}),    'bar.baz';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.dirname('/foo/bar.baz')}),     '/foo';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.extname('/foo/bar.baz')}),     '.baz';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.extname('/foo/bar.daz.baz')}), '.baz';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.extname('.foo')}),             '';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.join('foo', 'bar', 'baz')}),   'foo/bar/baz';
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}

