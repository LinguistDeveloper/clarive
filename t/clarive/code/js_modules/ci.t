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

subtest 'dispatches to CI instance' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var obj = ci.load('123'); obj.name()});

    is $ret, 'New';
};

subtest 'dispatches to CI attribute method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status'); (new Status({'mid': '123'})).icon()});

    like $ret, qr{static/images};
};

subtest 'dispatches to CI method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var obj = ci.load('123');
        obj.delete();
    });

    ok !mdb->master->find_one( { mid => '123' } );
};

subtest 'dispatches CI set method with argument' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var obj = ci.load('123');
        obj.name('joe');
        obj.name();
    });

    is $ret, 'joe';
};

subtest 'dispatches to CI method returning object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my @ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status');
        var obj = (new Status).searchCis(); obj.mid()});

    is scalar @ret, 1;
    is $ret[0], '123';
};

subtest 'CI creation / use' => sub {
    _setup();

    {
        my $code = _build_code( lang => 'js' );

        is $code->eval_code(q{
            var ci = require('cla/ci');
            ci.create("FooFooTestCI",{
                superclasses: ['Status'],
                has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
                methods: {
                    foo : function(){ return 100 },
                    connect: function(me){ return { aa: me.name(), bb: me.password() } }
                }
            });
            var ci = require('cla/ci');
            var obj = ci.build('FooFooTestCI', { name: 'bob' });
            obj.foo();
        }), 100;
    }
};

subtest 'CI creation and isLoaded' => sub {
    _setup();

    {
        my $code = _build_code( lang => 'js' );

        ok $code->eval_code(q{
            var ci = require('cla/ci');
            ci.create("BarTestCI",{
                superclasses: ['Status'],
                has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
                methods: {
                    foo : function(){ return 100 },
                    connect: function(me){ return { aa: me.name(), bb: me.password() } }
                }
            });
            ci.isLoaded('BarTestCI');
        });
    }
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;

    mdb->test_collection->drop;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
