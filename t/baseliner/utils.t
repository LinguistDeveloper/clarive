use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;

BEGIN {
    TestEnv->setup;
}

use Baseliner::Utils qw(_pointer query_grep);
use Clarive::mdb;

####### _pointer 

subtest '_pointer returns value from valid structures' => sub {
    is _pointer( 'foo', { foo => 'bar' } ), 'bar';
    is _pointer( 'foo.bar', { foo => { bar => 'baz' } } ), 'baz';
    is _pointer( 'foo.[0].bar', { foo => [ { bar => 'baz' } ] } ), 'baz';
    is _pointer( 'foo.[1].bar.[0]', { foo => [ {}, { bar => ['baz'] } ] } ), 'baz';
};

subtest '_pointer returns undef from valid structures' => sub {
    is _pointer( '[0]', [] ), undef;
    is _pointer( 'hello', { foo => 'bar' } ), undef;
};

subtest '_pointer returns undef from invalid structures' => sub {
    is _pointer( '[0]', {} ), undef;
    is _pointer( 'hello', [] ), undef;
};

subtest '_pointer throws on invalid structures' => sub {
    like exception { _pointer( '[0]', {}, throw => 1 ) }, qr/array ref expected at '\.'/;
    like exception { _pointer( 'hello', [], throw => 1 ) }, qr/hash ref expected at '\.'/;
    like exception { _pointer( 'hello.[0]', { hello => {} }, throw => 1 ) }, qr/array ref expected at 'hello'/;

    like exception { _pointer( '[0].foo.[1]', [ { foo => {} } ], throw => 1 ) }, qr/array ref expected at '\[0\]\.foo'/;
};

####### query_grep

my @rows = (
    { id=>'bart', name=>'Bart Simpson' },
    { id=>'lisa', name=>'Lisa Simpson' },
    { id=>'moe', name=>'Moe' },
    { id=>'kasim', name=>'Kasim' },
);

subtest 'query_grep finds rows single field' => sub {
    is scalar query_grep( query=>'bart', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'"Bart"', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'simpson', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'Simpson', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"sim"', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'"Sim"', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"Sim" -bart', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'+Si', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'ba +Si', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'li ba +Si', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'ba?t', fields=>['name'], rows=>\@rows ), 1;
    #is scalar query_grep( query=>'"Sim" -"Bart"', fields=>['name'], rows=>\@rows ), 1;
};

subtest 'query_grep finds rows single field masked' => sub {
    is scalar query_grep( query=>'S?mp', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'Simp*', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'+lisa Simp*', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'+lisa Simp*', fields=>['name'], rows=>\@rows ), 1;
};

subtest 'query_grep all fields' => sub {
    is scalar query_grep( query=>'Simp', all_fields=>1, rows=>\@rows ), 2;
    is scalar query_grep( query=>'bart', all_fields=>1, rows=>\@rows ), 1;
};

subtest 'query_grep finds rows single field regexp' => sub {
    is scalar query_grep( query=>'/S..p/', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'/S.*ps/', fields=>['name'], rows=>\@rows ), 2;
};

subtest 'query_grep finds rows multi-field' => sub {
    is scalar query_grep( query=>'bart', fields=>['name','id'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'bart Bart', fields=>['name','id'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'simpson', fields=>['name','id'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'Simpson', fields=>['name','id'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"sim"', fields=>['name','id'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'"Sim"', fields=>['name','id'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"Sim" -bart', fields=>['name','id'], rows=>\@rows ), 1;
};

subtest 'query_grep finds none' => sub {
    is scalar query_grep( query=>'hank', fields=>['name','id'], rows=>\@rows ), 0;
    is scalar query_grep( query=>'"bart"', fields=>['name'], rows=>\@rows ), 0;
    is scalar query_grep( query=>'-k -m -l -b', fields=>['name'], rows=>\@rows ), 0;
};

done_testing;
