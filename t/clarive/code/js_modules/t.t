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

subtest 't: testing more js' => sub {
    _setup();

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
        t.cmpDeeply([1,2],[1, t.ignore() ]);
        t.cmpDeeply([1,2], t.bag(2,1) );
        t.cmpDeeply([1,2], t.set(2,1) );
        t.cmpDeeply([11], t.subsetof(22,11) );
        t.cmpDeeply([11,{ aa: 22 }], [t.ignore(),{ aa: t.ignore() }], 'multiple ignore' );
        t.cmpDeeply( ['abc'], [ t.re('b') ] );
    });
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
