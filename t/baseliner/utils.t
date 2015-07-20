use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;

use Baseliner::Utils qw(_pointer);

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

done_testing;
