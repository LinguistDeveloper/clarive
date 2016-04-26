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

subtest 'cla.eval: run perl' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        cla.eval('pl', `"9" x 6`)});

    is $ret, '999999';
};

subtest 'cla.eval: run js' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        cla.eval('js', `var x=10; x;`)});

    is $ret, 10;
};

subtest 'dispatches to parseVars' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        cla.parseVars('${my_var}')}, { my_var => 'hello' } );

    is $ret, 'hello';
};

subtest 'dispatches to parseVars with local stash' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        cla.parseVars('${my_var}',{ "my_var":"hola" })}, { my_var => 'hello' } );

    is $ret, 'hola';
};

subtest 'parseVars without a stash' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( 'cla.parseVars("this is ${foo}")' );

    is $ret, 'this is ${foo}';
};

subtest 'dispatches to stash' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stash = {};
    $code->eval_code(q/cla.stash('foo', 'bar')/, $stash);

    is_deeply $stash, {foo => 'bar'};

    is $code->eval_code(q/cla.stash('foo')/, $stash), 'bar';

    is_deeply $code->eval_code(q/cla.stash()/, $stash), $stash;

};

subtest 'dispatches to stash pointers' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stash = { foo=>{} };
    $code->eval_code(q{cla.stash('/foo/bar', 99)}, $stash);

    is_deeply $stash, {foo =>{ bar => 99 } };
};

subtest 'gets clarive Config' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    Clarive->app->config->{_tester99} = 99;

    my $home = $code->eval_code(q{cla.config('_tester99')});

    is $home, 99;
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}

