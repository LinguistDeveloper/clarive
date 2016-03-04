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
use_ok 'Clarive::Code::Utils';

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

done_testing;
