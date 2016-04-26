use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
    TestEnv->setup( base => "$root/../../data/app-base" );
}

use TestUtils;

use BaselinerX::CI::generic_server;
use BaselinerX::CI::status;
use BaselinerX::Type::Menu;
use BaselinerX::Type::Service;

use_ok 'Clarive::Code::JS';
use Clarive::Code::Utils;

subtest 'evals js' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( '1 + 1', {} );

    is $ret, 2;
};

subtest 'console available' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( 'console', {} );

    ok ref $ret;
};

subtest 'extend cla namespace' => sub {
    my $code = _build_code( lang => 'js' );

    $code->extend_cla({ foo=>js_sub{ 321 } });
    my $ret = $code->eval_code( 'cla.foo();', {});

    is $ret, 321;
};

subtest 'extend global namespace' => sub {
    my $code = _build_code( lang => 'js' );

    $code->global_ns({ foo=>js_sub{ 999 } });
    my $ret = $code->eval_code( 'foo();', {});

    is $ret, 999;
};

subtest 'pragma transpile' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        "use transpiler(babel)";
        evens = [2,4,6,8]
        var odds = evens.map(v => v + 1);
        odds;
    });
    cmp_deeply $ret, [3,5,7,9];
};

subtest 'pragma transpile convert code' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        "use transpiler(test-trans)";
        ({ aa: 22 })});
    is $ret, 33;
};

subtest 'save vm creates globals' => sub {
    my $code = _build_code( lang => 'js' );

    $code->save_vm(1);
    $code->eval_code( 'var x = 100;', {});
    my $ret = $code->eval_code( 'x', {});

    is $ret, 100;
};

subtest 'save_vm enclose_code protects against globals' => sub {
    my $code = _build_code( lang => 'js' );

    $code->save_vm(1);
    $code->enclose_code(1);
    $code->eval_code( 'var x = 100;', {});
    ok exception { $code->eval_code( 'x', {}) };
};

subtest 'enclose code doesnt return value' => sub {
    my $code = _build_code( lang => 'js' );

    $code->enclose_code(1);
    my $ret = $code->eval_code( '100', {});

    is $ret, undef;
};

subtest 'require module underscore' => sub {
    my $code = _build_code( lang => 'js' );

    my $arr = $code->eval_code( 'var _ = require("underscore"); _.each([1,2],function(){})', {} );

    is_deeply $arr, [1,2];
};

subtest 'dispatches to toJSON' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    is $code->eval_code(q/toJSON('',{ pretty:true })/), '';
    is $code->eval_code(q/toJSON('foo',{ pretty:true })/), 'foo';
    is $code->eval_code(q/toJSON([1, 2, 3],{ pretty:true })/), qq/[\n   1,\n   2,\n   3\n]\n/;
    is $code->eval_code(q/toJSON({"foo":"bar"},{ pretty:true })/), qq/{\n   "foo" : "bar"\n}\n/;

    is $code->eval_code(q/toJSON([1, [2, 3], 4],{ pretty: true })/), qq/[\n   1,\n   [\n      2,\n      3\n   ],\n   4\n]\n/;
};

subtest 'exceptions catch internal errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );
    like exception { $code->eval_code( q/throw new Error('foo error!')/) }, qr/foo error!/;
    ok !exception { $code->eval_code( q/try { throw new Error('error!') } catch(e) {}/) };
};

subtest 'exceptions without JS.pm reference' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );
    $code->save_vm(1);
    my $vm = $code->initialize;

    $vm->set( errorHere => sub { die "died here" });

    unlike exception { $code->eval_code( q[errorHere()]) }, qr/at.*JS.pm/;
};

subtest 'exceptions catch external errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code(q{
            var fs = require("cla/fs");
            fs.openFile('cla-test-unknown')}) }, qr/Cannot open file cla-test-unknown/;
    ok !exception { $code->eval_code(q/try { fs.openFile('cla-test-unknown') } catch(e) {}/) };
};

subtest 'exceptions catch class not found errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( q{ require('cla/ci').getClass('XYZ123') }) }, qr/class.*XYZ123/;
};

subtest 'exceptions trap nested error' => sub {
    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( q{ cla.each([1,2],function(i){ cla.fooABC('foo') }); 11; }) }, qr/not callable/;
};

subtest 'exceptions throws double nested error' => sub {
    my $code = _build_code( lang => 'js' );
    $code->save_vm(1);

    my $vm = $code->initialize;
    $vm->set( barfoo => sub {
        die 123;
    });

    my $ret;
    like exception {
        $code->eval_code(q{
            cla.each([1,2],function(i){
                barfoo();
            });
        });
    }, qr/123/;
};

subtest 'exceptions trap try-catch nested error' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret;
    ok !exception {
        $ret = $code->eval_code(q{
            cla.each([1,2],function(i){
                try {
                    cla.fooABC('foo');
                } catch(e) {
                }
            });
            11;
        });
    };
    is $ret => 11;
};

subtest 'exceptions trap double try-catch nested error' => sub {
    my $code = _build_code( lang => 'js' );

    $code->save_vm(1);

    my $vm = $code->initialize;
    $vm->set( barfoo => sub {
        die 123;
    });

    my $ret;
    ok !exception {
        $ret = $code->eval_code(q{
            t = require('cla/t');
            cla.each([1,2],function(i){
                try {
                    barfoo();
                } catch(e) {
                    t.like( e+'', cla.regex('123') );
                }
            });
            11;
        });
    };
    is $ret => 11;
};

subtest 'returns js array' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{var x = [1,2,3]; x});

    is_deeply $ret,[1,2,3];
};

subtest 'returns js array from bare structure' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{[1,2,3];});

    is_deeply $ret,[1,2,3];
};

subtest 'bytecode call serialized from js to js' => sub {
    _setup();

    {
        my $code = _build_code( lang => 'js' );

        $code->eval_code(q{
            var ci = require('cla/ci');
            ci.create("AnotherTestCI",{
                superclasses: ['Status'],
                has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
                methods: {
                    foo : function(){ return 100 },
                    connect: function(me){ return { aa: me.name(), bb: me.password() } }
                }
            });
        });
    }
    {
        my $code = _build_code( lang => 'js' );

        is $code->eval_code(q{
            var ci = require('cla/ci');
            var obj = ci.build('AnotherTestCI', { name: 'bob' });
            obj.foo();
        }), 100;
        is_deeply $code->eval_code(q{
            var ci = require('cla/ci');
            var obj = ci.build('AnotherTestCI', { name: 'bob' });
            obj.password('222');
            obj.connect();
        }), { aa=>'bob', bb=>222 };
    }
};

subtest 'bytecode call serialized from js to perl' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $json = $code->eval_code(q{
        var ci = require('cla/ci');
        ci.create("TestCI",{
            superclasses: ['Status'],
            has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
            methods: {
                foo : function(){ return 100 },
                connect: function(me){ return { aa: me.name(), bb: me.password() } }
            }
        });
    });

    my $ci = ci->TestCI->new( name=>'joe' );
    is $ci->foo, 100;
    is $ci->password, 'xxx';
    is $ci->connect->{aa}, 'joe';
    is $ci->connect->{bb}, 'xxx';
};

subtest 'cla.register: register a menu' => sub {
    _setup();

    Baseliner::Core::Registry->add_class( undef, 'menu' => 'BaselinerX::Type::Menu' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{
        var reg = require('cla/reg');
        reg.register('menu.test',{ name: 'FooMenu' });
    });
    is( Baseliner::Core::Registry->get('menu.test')->name, 'FooMenu' );
};

subtest 'launch: register and launch a service' => sub {
    _setup();

    Baseliner::Core::Registry->add_class( undef, 'service' => 'BaselinerX::Type::Service' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{
        var reg = require('cla/reg');
        reg.register('service.test',{
            name: 'FooService',
            handler: function(){ return 99 }
        });
        reg.launch('service.test');
    });

    is $ret, 99;
    is( Baseliner::Core::Registry->get('service.test')->name, 'FooService' );
};

subtest 't: testing more js' => sub {
    _setup();

    Baseliner::Core::Registry->add_class( undef, 'service' => 'BaselinerX::Type::Service' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{
        var t = require('cla/t');
        t.ok(1,'this is ok');
        t.is(11,11,'is 11');;
        t.isnt(11,12);
        t.subtest('another',function(){
            t.like('hello',cla.regex('h.'));
            t.unlike('foo',cla.regex('h.'));
        });
        t.pass('my test');
        t.cmpDeeply([1,2],[1,2]);
        t.cmpDeeply({aa:10, bb:20},{bb:20, aa:10});
    });
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    mdb->test_collection->drop;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
