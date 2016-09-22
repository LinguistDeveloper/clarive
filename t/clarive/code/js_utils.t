use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use JavaScript::Duktape;

use_ok 'Clarive::Code::JSUtils';

subtest 'from_camel_class' => sub {
    { package BaselinerX::CI::FooBar; use Moose; };
    is from_camel_class('FooBar'), 'FooBar';

    { package BaselinerX::CI::boo_foo; use Moose; };
    is from_camel_class('BooFoo'), 'boo_foo';
};

subtest 'from_camel_class: throws when no class found' => sub {
    like exception { from_camel_class('UnknownClass') }, qr/Could not find a CI class named `UnknownClass`/;
};

subtest 'template_literals: kung foo' => sub {
    is template_literals(q{``}),               q{''};
    is template_literals(qq{`x\nx`}),          qq{'x\\n\\\nx'};
    is template_literals(qq{`x\nx\n\n`}),      qq{'x\\n\\\nx\\n\\\n\\n\\\n'};
    is template_literals(q{`x${foo}x`}),       q{'x'+(function(){return(foo);})()+'x'};
    is template_literals(q{`x${foo}${foo}x`}), q{'x'+(function(){return(foo);})()+''+(function(){return(foo);})()+'x'};
    is template_literals(q{`${foo}`}),         q{''+(function(){return(foo);})()+''};
    is template_literals(q{`${"foo"}`}),       q{''+(function(){return("foo");})()+''};
    is template_literals(q{`x\${foo}x`}),      q{'x${foo}x'};
    is template_literals(q{`\${bar}\${foo}\${"baz}`}), q{'${bar}${foo}${"baz}'};
    is template_literals(q{`x\'\'x`}),                 q{'x\'\'x'};
    is template_literals(q{`x'x`}),                    q{'x\'x'};
};

subtest 'here docs: kung foo' => sub {

    is heredoc(qq{var x = <<END;\nEND\n}),                        qq{var x = '';};
    is heredoc(qq{var x = <<END;\ntext\nEND\n}),                  qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<"END";\ntext\nEND\n}),                qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<'END';\ntext\nEND\n}),                qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<END;\n'text'\nEND\n}),                qq{var x = '\\'text\\'\\\n';};
    is heredoc(qq{var x = <<END;\n"text"\nEND\n}),                qq{var x = '"text"\\\n';};
    is heredoc(qq{var x = <<END;\n\\"text\\"\nEND\n}),            qq{var x = '\\"text\\"\\\n';};
    is heredoc(qq{var x = <<END;\n\\'text\\'\nEND\n}),            qq{var x = '\\\\'text\\\\'\\\n';};
    is heredoc(qq{var x = <<END\ntext\nEND\n}),                   qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<ANOTHER_TEXT\ntext\nANOTHER_TEXT\n}), qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<END\n\n\ntext\nEND\n}),               qq{var x = '\\\n\\\ntext\\\n';};
    is heredoc(qq{var x = <<END;\r\nlala\r\nEND\r\n}),            qq{var x = 'lala\\\n';};

    # not heredoc
    isnt heredoc(qq{var x = << END;\ntext\nEND\n}),          qq{var x = 'text\\\n';};
    isnt heredoc(qq{var x = <<END;\ntext\nEND;\n}),          qq{var x = 'text\\\n';};
    isnt heredoc(qq{var x = <<END-HERE;\ntext\nEND-HERE\n}), qq{var x = 'text\\\n';};
};

subtest 'pv_address: looks like an address' => sub {
    my $buf = "hello";

    like pv_address($buf), qr/[0-9abcdef]+/;
};

subtest 'peek: get an SV address and make sure its there' => sub {
    my $buf = "hello";

    is peek( pv_address($buf), 5 ), 'hello';
};

subtest 'to_bytecode: turns js into bytecode' => sub {
    my ( $bc, $len );

    my $js = JavaScript::Duktape->new();
    $js->set(
        foo => sub {
            my $code = shift;

            ( $bc, $len ) = to_bytecode( $js->duk, $code );
        }
    );
    $js->eval("foo(function(){ return { aa:101 } });");

    is $len, length($bc);

    my $bc_hex = unpack 'H*', $bc;
    like $bc_hex, qr/^ff00/;    # duktape bytecode always start with ff00 (but could change...)
};

subtest '_serialize: HASH' => sub {
    cmp_deeply( _serialize( {}, { aa => 11 } ), { aa => 11 } );
};

subtest '_serialize: ARRAY' => sub {
    cmp_deeply( _serialize( {}, [ 1, 2, 3 ] ), [ 1, 2, 3 ] );
};

subtest '_serialize: SCALAR' => sub {
    is( _serialize( {}, 'str' ), 'str' );
};

subtest '_serialize: CODE into js_sub' => sub {
    is( _serialize( {}, sub { 11 } )->(),      11 );
    is( _serialize( {}, sub { shift } )->(33), 33 );
};

subtest '_serialize: CODE into bytecode' => sub {
    my $vm = JavaScript::Duktape->new;

    local $Clarive::Code::JS::CURRENT_VM = $vm;

    my $code = $vm->eval('var x = function(){ }; x');
    my $ser = _serialize( { to_bytecode => 1 }, $code );

    is ref($ser), 'CODE';
};

subtest '_serialize: blessed methods camelized' => sub {
    {

        package Foo;
        sub bar_bar { 22 }
    };
    my $obj = bless { aa => 11 } => 'Foo';
    my $serial = _serialize( {}, $obj );
    is $serial->{barBar}->(), 22;
};

subtest '_serialize: blessed wrapped' => sub {
    my $obj = bless { aa => 11 } => 'Foo';

    cmp_deeply( _serialize( { wrap_blessed => 1 }, $obj ),
        { __cla_js => 'Foo', obj => unpack( 'H*', Util->_dump($obj) ) } );
};

subtest '_serialize: serializes Regepx' => sub {
    my $type = _serialize( {}, qr/regexp/ );

    cmp_deeply( $type, { __cla_js => 'regex', re => '(?^:regexp)' } );
};

subtest '_serialize: detects cycles' => sub {
    my $data = { foo => 'bar' };
    $data->{baz} = $data;
    my $type = _serialize( {}, $data );

    is_deeply $type,
      {
        'baz' => '__cycle_detected__',
        'foo' => 'bar'
      };
};

subtest 'unwrap_types: basic scalar' => sub {
    cmp_deeply( [ unwrap_types('foo') ], ['foo'] );
    cmp_deeply( [ unwrap_types(22) ],    [22] );
};

subtest 'unwrap_types: blessed is reblessed' => sub {
    {

        package TestFoo;
        sub aa { shift->{aa} }
    };
    my $serial = { __cla_js => 'TestFoo', obj => unpack( 'H*', Util->_dump( bless { aa => 12 } => 'TestFoo' ) ) };
    my ($obj) = unwrap_types($serial);

    is $obj->aa, 12;
};

subtest 'serialize and unwrap a regexp' => sub {
    my $doc  = qr/a.c/;
    my $ser  = _serialize( {}, $doc );
    my ($re) = unwrap_types($ser);

    like 'abc', $re;
};

subtest 'unwrap_types: unwraps default HASH type' => sub {
    my ($ret) = unwrap_types( { foo => 'bar' } );

    is_deeply $ret, { foo => 'bar' };
};

subtest 'js_sub: wrap funcs' => sub {
    my $vm = JavaScript::Duktape->new;
    local $Clarive::Code::JS::CURRENT_VM = $vm;

    $vm->set(
        each => Clarive::Code::JSUtils::js_sub(
            sub {
                my $arr = shift;
                my $cb  = shift;
                for (@$arr) {
                    $cb->($_);
                }
            }
        )
    );

    my $ret = $vm->eval('var x=0; each([11,22], function(i){ x+=i }); x');

    is $ret, 33,;
};

subtest 'js_sub: rewrap funcs' => sub {
    my $vm = JavaScript::Duktape->new;

    local $Clarive::Code::JS::CURRENT_VM = $vm;

    $vm->set(
        each => Clarive::Code::JSUtils::js_sub(
            sub {
                my $arr = shift;
                my $cb  = shift;
                for (@$arr) {
                    Clarive::Code::JSUtils::js_sub( \&$cb )->($_);
                }
            }
        )
    );

    my $ret = $vm->eval('var x=0; each([11,22], function(i){ x+=i }); x');

    is $ret, 33,;
};

subtest 'js_sub: rewrap func with nested call' => sub {
    my $vm = JavaScript::Duktape->new;

    local $Clarive::Code::JS::CURRENT_VM = $vm;

    $vm->set(
        inc => Clarive::Code::JSUtils::js_sub(
            sub {
                return 1 + shift();
            }
        )
    );
    $vm->set(
        each => Clarive::Code::JSUtils::js_sub(
            sub {
                my $arr = shift;
                my $cb  = shift;
                for (@$arr) {
                    Clarive::Code::JSUtils::js_sub( \&$cb )->($_);
                }
            }
        )
    );

    my $ret = $vm->eval(q{ var x=0; each([11,22], function(i){ x+=i; x=inc(x); }); x });

    is $ret, 35,;
};

subtest 'js_sub: handle rewrap func with error in nested call' => sub {
    my $vm = JavaScript::Duktape->new;

    local $Clarive::Code::JS::CURRENT_VM = $vm;

    $vm->set(
        inc => Clarive::Code::JSUtils::js_sub(
            sub {
                die("failing here");
            }
        )
    );
    $vm->set(
        each => Clarive::Code::JSUtils::js_sub(
            sub {
                my $arr = shift;
                my $cb  = shift;
                for (@$arr) {
                    Clarive::Code::JSUtils::js_sub( \&$cb )->($_);
                }
            }
        )
    );

    like exception { $vm->eval(q{ var x=0; each([11,22], function(i){ x+=i; x=inc(x); }); x }) }, qr/failing here/;
};

subtest 'to_duk_bool: transforms perl boolean to js boolean' => sub {
    my $vm = JavaScript::Duktape->new;

    local $Clarive::Code::JS::CURRENT_VM = $vm;

    $vm->set( val_true  => Clarive::Code::JSUtils::to_duk_bool(1) );
    $vm->set( val_false => Clarive::Code::JSUtils::to_duk_bool(0) );

    my $ret = $vm->eval(q{ val_true === true && val_false === false });

    ok $ret;
};

subtest 'load_module: throws when unknown module' => sub {
    like exception { Clarive::Code::JSUtils::load_module('unknown') },
      qr/Could not find module `unknown` in the following plugins:/;
};

subtest 'load_module: loads modules from cla' => sub {
    like Clarive::Code::JSUtils::load_module('cla/util'), qr/cla.loadCla/;
};

subtest 'load_module: loads module' => sub {
    like Clarive::Code::JSUtils::load_module('handlebars'), qr/handlebars/;
};

subtest '_map_instance: returns undef when nothing passed' => sub {
    is _map_instance(), undef;
};

subtest '_map_instance: maps perl instance' => sub {
    {

        package SomeClass;
        sub my_method { 22 }
        sub _private  { }
    };
    my $obj = bless { aa => 11 } => 'SomeClass';

    my $instance = _map_instance($obj);

    is ref $instance->{myMethod}, 'CODE';
    ok !exists $instance->{_private};
};

subtest '_map_instance: maps moose instance' => sub {
    {

        package Foo;
        use Moose;
        has moose_attr => qw(is ro);
        sub moose_my_method { 22 }
        sub _moose_private  { }
    };
    my $obj = bless { aa => 11 } => 'Foo';

    my $instance = _map_instance($obj);

    is ref $instance->{mooseMyMethod}, 'CODE';
    is ref $instance->{mooseAttr},     'CODE';
    ok !exists $instance->{_moosePrivate};
};

subtest '_map_ci: maps and loads ci' => sub {
    _setup();

    TestUtils->create_ci('variable', mid => '123');

    my $instance = _map_ci('variable', '123');

    ok exists $instance->()->{bl};
};

subtest '_bc_sub: 123' => sub {
    my $vm = JavaScript::Duktape->new;

    local $Clarive::Code::JS::CURRENT_VM = $vm;

    my $cb = $vm->eval('var f = function () { return 123 }; f');

    my $bytecode = _bc_sub($cb);

    local $Clarive::Code::JS::CURRENT_VM;

    is $bytecode->(), 123;
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
}
