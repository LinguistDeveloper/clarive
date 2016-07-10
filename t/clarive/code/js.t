use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
    TestEnv->setup( base => "$root/../../data/app-base" );
}

use TestUtils;

use BaselinerX::CI::status;

use_ok 'Clarive::Code::JS';

use Clarive::Code::JSUtils qw(js_sub);

subtest 'JSON: parses/stringifies' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(q/JSON.parse(JSON.stringify({foo: 'bar'}))/);

    is_deeply $ret, { foo => 'bar' };
};

subtest 'JSON: parses/stringifies unicode' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(q/JSON.parse(JSON.stringify({привет: 'всем'}))/);

    is_deeply $ret, { 'привет' => 'всем' };
};

subtest 'JSON: stringifies unicode' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(q/JSON.stringify({привет: 'всем'})/);

    is $ret, q/{"привет":"всем"}/;
};

subtest 'YAML: parses/stringifies' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(q/YAML.parse(YAML.stringify({foo: 'bar'}))/);

    is_deeply $ret, { foo => 'bar' };
};

subtest 'YAML: stringifies unicode' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(q/YAML.stringify({привет: 'всем'})/);

    is $ret, "---\nпривет: всем\n";
};

subtest 'evals js' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code( '1 + 1', {} );

    is $ret, 2;
};

subtest 'console available' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code( 'console', {} );

    ok ref $ret;
};

subtest 'extend cla namespace' => sub {
    my $code = _build_code();

    $code->extend_cla( { foo => js_sub { 321 } } );
    my $ret = $code->eval_code( 'cla.foo();', {} );

    is $ret, 321;
};

subtest 'extend global namespace' => sub {
    my $code = _build_code();

    $code->global_ns( { foo => js_sub { 999 } } );
    my $ret = $code->eval_code( 'foo();', {} );

    is $ret, 999;
};

subtest 'does not process pragmas when not allowed' => sub {
    my $code = _build_code( lang => 'js', allow_pragmas => 0 );

    like exception {
        $code->eval_code(
            q{
        "use transpiler(babel)";
        evens = [2,4,6,8]
        var odds = evens.map(v => v + 1);
        odds;
    }
          )
    }, qr/SyntaxError/;
};

subtest 'ignores unknown pragmas' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(
        q{
        "use unknown_pragma(babel)";
        1;
    }
    );

    is $ret, 1;
};

subtest 'transpile: throws when unknown transpile' => sub {
    my $code = _build_code();

    like exception {
        $code->eval_code(
            q{
        "use transpiler(unknown)";
    }
          )
    }, qr/Transpiler not found: unknown/;
};

subtest 'pragma transpile' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(
        q{
        "use transpiler(babel)";
        var evens = [2,4,6,8];
        var odds = evens.map(v => v + 1);
        odds;
    }
    );
    cmp_deeply $ret, [ 3, 5, 7, 9 ];
};

subtest 'pragma transpile convert code' => sub {
    my $code = _build_code();

    my $ret = $code->eval_code(
        q{
        "use transpiler(test-trans)";
        ({ aa: 22 })}
    );
    is $ret, 33;
};

subtest 'rethrows transpiler error' => sub {
    my $code = _build_code();

    like exception {
        $code->eval_code(
            q{
        "use transpiler(test-trans)";
        ('error')
        }
          )
    }, qr/Transpile Error \(test-trans\): Error: some error/;
};

subtest 'throws when empty transpiler code' => sub {
    my $code = _build_code();

    like exception {
        $code->eval_code(
            q{
        "use transpiler(test-trans)";
        ('empty')
        }
          )
    }, qr/Transpiled code empty or invalid/;
};

subtest 'save vm creates globals' => sub {
    my $code = _build_code();

    $code->save_vm(1);
    $code->eval_code( 'this.x = 100;', {} );

    my $ret = $code->eval_code( 'this.x', {} );

    is $ret, 100;
};

subtest 'save_vm enclose_code protects against globals' => sub {
    my $code = _build_code();

    $code->save_vm(1);
    $code->enclose_code(1);
    $code->eval_code( 'var x = 100;', {} );
    ok exception { $code->eval_code( 'x', {} ) };
};

subtest 'enclose code doesnt return value' => sub {
    my $code = _build_code();

    $code->enclose_code(1);
    my $ret = $code->eval_code( '100', {} );

    is $ret, undef;
};

subtest 'require module underscore' => sub {
    my $code = _build_code();

    my $arr = $code->eval_code( 'var _ = require("underscore"); _.each([1,2],function(){})', {} );

    is_deeply $arr, [ 1, 2 ];
};

subtest 'strict mode by default' => sub {
    _setup();

    my $code = _build_code();

    like exception {
        $code->eval_code( q/x = 1;/, )
    }, qr{ReferenceError: identifier not defined};
};

subtest 'rethrows perl error' => sub {
    _setup();

    my $code = _build_code();

    like exception {
        $code->eval_code(
            q/var f = cla.stash('hello'); f()/,
            {
                hello => sub { die 'error' }
            }
          )
    }, qr{Error: error at t/clarive/code/js.t line \d+.};
};

subtest 'exceptions catch internal errors' => sub {
    _setup();

    my $code = _build_code();
    like exception { $code->eval_code(q/throw new Error('foo error!')/) }, qr/foo error!/;
    ok !exception { $code->eval_code(q/try { throw new Error('error!') } catch(e) {}/) };
};

subtest 'exceptions without JS.pm reference' => sub {
    _setup();

    my $code = _build_code();
    $code->save_vm(1);

    unlike exception {
        $code->eval_code(
            q[cla.stash('errorHere')()],
            {
                errorHere => sub { die 'died here' }
            }
          )
    }, qr/at.*JS.pm/;
};

subtest 'exceptions catch external errors' => sub {
    _setup();

    my $code = _build_code();

    like exception {
        $code->eval_code(
            q{
            var fs = require("cla/fs");
            fs.openFile('cla-test-unknown')}
          )
    }, qr/Cannot open file cla-test-unknown/;
    ok !exception { $code->eval_code(q/try { fs.openFile('cla-test-unknown') } catch(e) {}/) };
};

subtest 'exceptions catch class not found errors' => sub {
    _setup();

    my $code = _build_code();

    like exception { $code->eval_code(q{ require('cla/ci').getClass('XYZ123') }) }, qr/class.*XYZ123/;
};

subtest 'exceptions trap nested error' => sub {
    my $code = _build_code();

    like exception { $code->eval_code(q{ cla.each([1,2],function(i){ cla.fooABC('foo') }); 11; }) }, qr/not callable/;
};

subtest 'exceptions throws double nested error' => sub {
    my $code = _build_code();
    $code->save_vm(1);

    like exception {
        $code->eval_code(
            q{
            cla.each([1,2],function(i){
                cla.stash('barfoo')();
            });
        },
            {
                barfoo => sub { die 123 }
            }
        );
    }, qr/123/;
};

subtest 'exceptions trap try-catch nested error' => sub {
    my $code = _build_code();

    my $ret;
    ok !exception {
        $ret = $code->eval_code(
            q{
            cla.each([1,2],function(i){
                try {
                    cla.fooABC('foo');
                } catch(e) {
                }
            });
            11;
        }
        );
    };
    is $ret => 11;
};

subtest 'exceptions trap double try-catch nested error' => sub {
    my $code = _build_code();

    my $ret;
    ok !exception {
        $ret = $code->eval_code(
            q{
            var t = require('cla/t');
            cla.each([1,2],function(i){
                try {
                    cla.stash('barfoo')();
                } catch(e) {
                    t.like( e+'', cla.regex('123') );
                }
            });
            11;
        },
            {
                barfoo => sub {
                    die 123;
                }
            }
        );
    };
    is $ret => 11;
};

subtest 'returns js array' => sub {
    _setup();

    my $code = _build_code();

    my $ret = $code->eval_code(q{var x = [1,2,3]; x});

    is_deeply $ret, [ 1, 2, 3 ];
};

subtest 'returns js array from bare structure' => sub {
    _setup();

    my $code = _build_code();

    my $ret = $code->eval_code(q{[1,2,3];});

    is_deeply $ret, [ 1, 2, 3 ];
};

subtest 'bytecode call serialized from js to js' => sub {
    _setup();

    {
        my $code = _build_code();

        $code->eval_code(
            q{
            var ci = require('cla/ci');
            ci.createClass("AnotherTestCI",{
                superclasses: ['Status'],
                has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
                methods: {
                    foo : function(){ return 100 },
                    connect: function(){ return { aa: this.name(), bb: this.password() } }
                }
            });
        }
        );
    }
    {
        my $code = _build_code();

        is $code->eval_code(
            q{
            var ci = require('cla/ci');
            var obj = ci.build('AnotherTestCI', { name: 'bob' });
            obj.foo();
        }
          ),
          100;
        is_deeply $code->eval_code(
            q{
            var ci = require('cla/ci');
            var obj = ci.build('AnotherTestCI', { name: 'bob' });
            obj.password('222');
            obj.connect();
        }
          ),
          { aa => 'bob', bb => 222 };
    }
};

subtest 'bytecode call serialized from js to perl' => sub {
    _setup();

    my $code = _build_code();

    my $json = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.createClass("TestCI",{
            superclasses: ['Status'],
            has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
            methods: {
                foo : function(){ return 100 },
                connect: function(){ return { aa: this.name(), bb: this.password() } }
            }
        });
    }
    );

    my $ci = ci->TestCI->new( name => 'joe' );

    is $ci->foo,      100;
    is $ci->password, 'xxx';
    is $ci->connect->{aa}, 'joe';
    is $ci->connect->{bb}, 'xxx';
};

subtest '__dirname: returns current dirname' => sub {
    _setup();

    my $code = _build_code();

    my $ret = $code->eval_code(
        q{
        __dirname.split("/").pop();
    }
    );

    is $ret, '.';
};

subtest '__filename: returns current filename' => sub {
    _setup();

    my $code = _build_code();

    my $ret = $code->eval_code(
        q{
        __filename;
    }
    );

    is $ret, 'EVAL';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
    );

    TestUtils->cleanup_cis;

    mdb->test_collection->drop;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
