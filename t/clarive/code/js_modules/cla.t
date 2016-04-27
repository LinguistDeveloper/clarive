use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Capture::Tiny qw(capture);

use_ok 'Clarive::Code::JS';

subtest 'cla.loadCla: loads cla component' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{ cla.loadCla('util') });

    ok $ret->{sleep};
};

subtest 'cla.loadCla: throws an error when cannot find' => sub {
    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(q{ cla.loadCla('unknown') })
    }, qr/Error loading module `unknown`/;
};

subtest 'cla.loadModule: loads module' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{ cla.loadModule('underscore') });

    like $ret, qr/Underscore.js/;
};

subtest 'cla.eval: runs perl' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        cla.eval('pl', `"9" x 6`)}
    );

    is $ret, '999999';
};

subtest 'cla.eval: runs perl with array serialization' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        cla.eval('pl', '(1, 2, 3)')}
    );

    is_deeply $ret, [ 1, 2, 3 ];
};

subtest 'cla.eval: rethrows perl exception' => sub {
    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        cla.eval('pl', 'die "here"')}
        );
    }, qr/here/;
};

subtest 'cla.eval: runs js' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{ cla.eval('js', `var x=10; x;`) });

    is $ret, 10;
};

subtest 'cla.eval: throws on unknown language' => sub {
    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code(q{ cla.eval('ruby', 'puts "hi"') }) },
      qr/Could not eval, language not available: ruby/;
};

subtest 'dispatches to parseVars' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{ cla.parseVars('${my_var}') }, { my_var => 'hello' } );

    is $ret, 'hello';
};

subtest 'dispatches to parseVars with local stash' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        cla.parseVars('${my_var}',{ "my_var":"hola" })}, { my_var => 'hello' }
    );

    is $ret, 'hola';
};

subtest 'parseVars without a stash' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code('cla.parseVars("this is ${foo}")');

    is $ret, 'this is ${foo}';
};

subtest 'dispatches to stash' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stash = {};
    $code->eval_code( q/cla.stash('foo', 'bar')/, $stash );

    is_deeply $stash, { foo => 'bar' };

    is $code->eval_code( q/cla.stash('foo')/, $stash ), 'bar';

    is_deeply $code->eval_code( q/cla.stash()/, $stash ), $stash;
};

subtest 'dispatches to stash pointers' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stash = { foo => {} };
    $code->eval_code( q{cla.stash('/foo/bar', 99)}, $stash );

    is_deeply $stash, { foo => { bar => 99 } };
};

subtest 'cla.config: return config value' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    Clarive->app->config->{_tester99} = 99;

    my $home = $code->eval_code(q{cla.config('_tester99')});

    is $home, 99;
};

subtest 'cla.config: sets config value' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    $code->eval_code(q{cla.config('_tester99', 99)});
    my $home = $code->eval_code(q{cla.config('_tester99')});

    is $home, 99;
};

subtest 'regex param unwrap' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );
    $code->save_vm(1);

    my $vm = $code->initialize;
    $vm->set(
        barfoo => sub {
            my $arg  = shift;
            my ($re) = Clarive::Code::Utils::unwrap_types($arg);
            my @r    = ( 'aa bb cc dd' =~ m/$re/g );
            return scalar @r;
        }
    );

    my $ret = $code->eval_code(
        q{
        barfoo( cla.regex('( )') );
    }
    );

    is $ret, 3;
};

subtest 'cla.printf: prints formatted string' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stdout = capture { $code->eval_code(q{ cla.printf('foo %s', 'bar') }) };

    is $stdout, 'foo bar';
};

subtest 'cla.printf: prints formatted string with unicode' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stdout = capture { $code->eval_code(q{ cla.printf('foo %s', 'привет') }) };

    is $stdout, Encode::encode( 'UTF-8', 'foo привет' );
};

subtest 'cla.sprintf: returns formatted string' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{ cla.sprintf('foo %s', 'bar') });

    is $ret, 'foo bar';
};

subtest 'cla.each: iterates over array' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var output = '';
        cla.each([1, 2, 3], function(el) {
            output += el;
        })
        output;
        }
    );

    is $ret, '123';
};

subtest 'cla.each: does nothing when not an array' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var output = '';
        cla.each(1, function(el) {
            output += el;
        })
        output;
        }
    );

    is $ret, '';
};

subtest 'cla.lastError: returns last error' => sub {
    _setup();

    local $! = 1;

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        cla.lastError();
        }
    );

    is $ret, 'Operation not permitted';
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
