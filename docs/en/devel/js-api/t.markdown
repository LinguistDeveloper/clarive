---
title: cla/t - Testing
---

This module contains functions
that support Clarive plugin testing.

Typically, this module will be used
for testing within a `plugin/t/[test-case].js`
file, and can be tested with the command:

    cla plugin-prove test-case.js

The command will look for the file `test-case.js`
in the current installed plugins and test it.

For more information, read the [section about plugin testing here.](devel/plugin)

### t.subtest(name, function(){ ... })

Starts a new subtest, which is a group
of test cases related to a functionality.

The subtest `name` has to be unique in the test suite.

```
var t = require('cla/t');

t.subtest('testing it works', function(){
   t.is( 1, 1);
});

t.subtest('testing some other thing', function(){
   t.is( 1, 1, 'comparing 1 and 1');
});

t.doneTesting();
```

Grouping tests helps isolate individual comparisons
and test collections, creating a sense of scope and
improving test suite readability and maintainability.

### t.doneTesting()

Tells the test runner tests have concluded.

Can only be issued once during the test. Once
testing is done, no more tests can be run.

### t.ok(a,[name])

Passes if `a` is true.

### t.is(a,b,[name])

Passes if `a` and `b` are equal.

```javascript
var t = require('cla/t');
var x = 'aa';
t.is( x, 'aa' );
```

### t.isnt(a,b,[name])

Passes if `a` and `b` are different.

```javascript
var t = require('cla/t');
var x = 'bb';
t.isnt( x, 'aa' );
```

### t.like(a,b,[name])

Passes if `a` matches regex in `b`.

```javascript
var t = require('cla/t');
t.subtest('testing again here', function(){
   t.like( 'abc', cla.regex('a.*') );
});
```

### t.unlike(a,b,[name])

The opposite of `t.like()`

```javascript
var t = require('cla/t');
t.subtest('testing again here', function(){
   t.unlike( 'abc', cla.regex('^..$') );
});
```

### t.pass(msg)

Emits a pass signal manually, declaring
that the test is ok.

```javascript
var t = require('cla/t');
t.subtest('testing a pass', function(){
    var x = 10;
    if( x == 10 ) {
        t.pass('not a 10');
    }
});
```

### t.fail(msg)

Emits a pass signal manually, declaring
that the test has failed.

```javascript
var t = require('cla/t');
t.subtest('testing a fail', function(){
    var x = 10;
    t.ok( x );
    if( x != 10 ) {
        t.fail('not a 10');
    }
});
```

### t.plan(arg,numtests)

Controls how many and if tests will be run.

```
var t = require('cla/t');
t.plan( 'tests', 15 );
t.plan( 'skip_all', 'no internet connection, so no tests' );
```

### t.skip(msg,numtests)

Skips tests. This function is useful
to skip certain test cases when they
are not implemented or the conditions
are not right.

`skip()` needs to set the `numtests`
that will be skipped. To set the number
of tests, see `plan()`

```
var t = require('cla/t');
t.subtest('testing a fail', function(){
    t.plan( 'tests', 1 );
    var x = 10;
    if( x == 10 ) {
        t.skip("we're not ready to test this",1);
    }
});
```

### t.cmpDeeply(a,b,[name])

Compares complex data structures `a` and `b`,
such as Objects or Arrays, passing or failing the test
accordingly.

`t.cmpDeeply()` has a great number of special comparison
functions that help evaluate expressions partially, greatly
simplifying tests.

Here are some examples:

```javascript
var t = require('cla/t');
t.cmpDeeply([1,2],[1,2]);
t.cmpDeeply({aa:10, bb:20},{bb:20, aa:10});
t.cmpDeeply([1,2],[1, t.ignore() ]);
t.cmpDeeply([1,2], t.bag(2,1) );
t.cmpDeeply([1,2], t.set(2,1) );
```

#### t.ignore()

This is a convenient way to check that values or elements exist
in a data structure while not having to specify its actual value.

```javascript
var t = require('cla/t');
t.cmpDeeply(
    ['foo','bar',{ aa: 10 }],
    [t.ignore(), t.ignore(), { aa: t.ignore() } ]
);
```

#### t.re(regexp)

Allows partial comparisons of string values
using regular expressions.

```javascript
var t = require('cla/t');
var arr = ['foo','bar'];
t.cmpDeeply( arr, [ t.re('^f'), t.re('...') ] );
```

#### t.set(...)

This does a set comparison, that is, it compares two arrays but ignores the
order of the elements and it ignores duplicate elements, so

    t.cmpDeeply([1, 2, 2, 3], set(3, 2, 1, 1));

will be a pass.

#### t.bag(...)

This does a bag comparison, that is, it compares two arrays but ignores the
order of the elements so

  t.cmpDeeply([1, 2, 2], bag(2, 2, 1))

will be a pass.

#### t.superbagof(...)
#### t.subbagof(...)
#### t.supersetof(...)
#### t.subsetof(...)
#### t.noneof(...)

These operators allow for partial comparison of
arrays elements.

    t.cmpDeeply([11], t.subsetof(22,11) );  // PASS
    t.cmpDeeply([11,22,33], t.supersetof(22,11) );  // PASS

### t.all(...)

Groups many test comparisons in an `AND` fashion.

### t.any(...)

Groups many test comparisons in an `OR` fashion.

