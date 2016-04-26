use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use Try::Tiny;

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

    is $code->eval_code(q/toJSON('')/), '';
    is $code->eval_code(q/toJSON('foo')/), 'foo';
    is $code->eval_code(q/toJSON([1, 2, 3])/), qq/[\n   1,\n   2,\n   3\n]\n/;
    is $code->eval_code(q/toJSON({"foo":"bar"})/), qq/{\n   "foo" : "bar"\n}\n/;

    is $code->eval_code(q/toJSON([1, [2, 3], 4])/), qq/[\n   1,\n   [\n      2,\n      3\n   ],\n   4\n]\n/;
};

subtest 'exceptions catch internal errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( q/throw new Error('error!')/) }, qr/error!/;
    ok !exception { $code->eval_code( q/try { throw new Error('error!') } catch(e) {}/) };
};

subtest 'exceptions catch external errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code(q{
            var fs = require("cla/fs");
            fs.openFile('unknown')}) }, qr/Cannot open file unknown/;
    ok !exception { $code->eval_code(q/try { fs.openFile('unknown') } catch(e) {}/) };
};

subtest 'exceptions catch class not found errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( q{ require('cla/ci').getClass('XYZ123') }) }, qr/class.*XYZ123/;
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
