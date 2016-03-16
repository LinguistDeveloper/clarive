use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use Try::Tiny;

use Baseliner::Utils qw(_slurp);
use BaselinerX::CI::generic_server;
use JavaScript::Duktape;
use_ok 'Clarive::Code::Utils';

subtest 'from_camel_class' => sub {
    { package BaselinerX::CI::FooBar; use Moose; };
    is from_camel_class('FooBar'), 'FooBar';
    { package BaselinerX::CI::boo_foo; use Moose; };
    is from_camel_class('BooFoo'), 'boo_foo';
};

subtest 'template_literals: kung foo' => sub {

    is template_literals(q{``}), q{''};
    is template_literals(qq{`x\nx`}), qq{'x\\n\\\nx'};
    is template_literals(qq{`x\nx\n\n`}), qq{'x\\n\\\nx\\n\\\n\\n\\\n'};
    is template_literals(q{`x${foo}x`}), q{'x'+(function(){return(foo);})()+'x'};
    is template_literals(q{`x${foo}${foo}x`}), q{'x'+(function(){return(foo);})()+''+(function(){return(foo);})()+'x'};
    is template_literals(q{`${foo}`}), q{''+(function(){return(foo);})()+''};
    is template_literals(q{`${"foo"}`}), q{''+(function(){return("foo");})()+''};
    is template_literals(q{`x\${foo}x`}), q{'x${foo}x'};
    is template_literals(q{`\${bar}\${foo}\${"baz}`}), q{'${bar}${foo}${"baz}'};
    is template_literals(q{`x\'\'x`}), q{'x\'\'x'};
    is template_literals(q{`x'x`}), q{'x\'x'};
};

subtest 'here docs: kung foo' => sub {

    is heredoc(qq{var x = <<END;\nEND\n}), qq{var x = '';};
    is heredoc(qq{var x = <<END;\ntext\nEND\n}), qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<"END";\ntext\nEND\n}), qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<'END';\ntext\nEND\n}), qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<END;\n'text'\nEND\n}), qq{var x = '\\'text\\'\\\n';};
    is heredoc(qq{var x = <<END;\n"text"\nEND\n}), qq{var x = '"text"\\\n';};
    is heredoc(qq{var x = <<END;\n\\"text\\"\nEND\n}), qq{var x = '\\"text\\"\\\n';};
    is heredoc(qq{var x = <<END;\n\\'text\\'\nEND\n}), qq{var x = '\\\\'text\\\\'\\\n';};
    is heredoc(qq{var x = <<END\ntext\nEND\n}), qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<ANOTHER_TEXT\ntext\nANOTHER_TEXT\n}), qq{var x = 'text\\\n';};
    is heredoc(qq{var x = <<END\n\n\ntext\nEND\n}), qq{var x = '\\\n\\\ntext\\\n';};
    is heredoc(qq{var x = <<END;\r\nlala\r\nEND\r\n}), qq{var x = 'lala\\\n';};

    # not heredoc
    isnt heredoc(qq{var x = << END;\ntext\nEND\n}), qq{var x = 'text\\\n';};
    isnt heredoc(qq{var x = <<END;\ntext\nEND;\n}), qq{var x = 'text\\\n';};
    isnt heredoc(qq{var x = <<END-HERE;\ntext\nEND-HERE\n}), qq{var x = 'text\\\n';};
};

subtest 'pv_address: looks like an address' => sub {
    my $buf = "hello";
    like pv_address($buf), qr/[0-9abcdef]+/;
};

subtest 'peek: get an SV address and make sure its there' => sub {
    my $buf = "hello";
    is peek( pv_address($buf), 5), 'hello';
};

subtest 'to_bytecode: turn js into bytecode' => sub {
    my $js = JavaScript::Duktape->new();
    $js->set( foo=>sub{
        my $duk = shift;
        my $code = shift;
        my ($bc,$len) = to_bytecode( $duk, $code );
        my $bc_hex = unpack 'H*', $bc;
        is $len, length($bc);
        like $bc_hex, qr/^ff00/; # duktape bytecode always start with ff00 (but could change...)
    });
    $js->eval("foo(function(){ return { aa:101 } });");
};

done_testing;
