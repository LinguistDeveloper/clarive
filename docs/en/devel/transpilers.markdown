---
title: Transpilers, Babel, CoffeeScript and TypeScript
index: 5000
icon: page
---

JavaScript transpilers (or transcompilers) are tools that convert a specific
language code into ES JavaScript. It takes the source code of a program written
in one programming language as its input and produces the equivalent source
code in another programming language.

Clarive supports using transpilers
to filter and preprocess JS code before being executed.
Clarive also ships with a few transpilers pre-installed:

- Babel (ES2015)
- CoffeeScript
- TypeScript

## Using Transpilers

To have your code processed through one of the installed transpilers
use a special JavaScript pragma created for this.

The pragma to activate transpiling is this:

```js
    "use transpiler([transpiler name])";
```

This will have the __full current body of source code__ transpiled,
independently of where the pragma is declared.

Notice that althought transpiling is not a very expensive operation,
everytime new unique source code is created, it has to be transpiled, which means
loading the transpiler, parsing and converting to JavaScript. Clarive caches the
transpiled code, so the next execution will only cost the same as if it were written
in plain JavaScript, which can mean a 100x or more improvement in execution speed.

If you believe you're having issues with transpiled code cached, try wiping the cache
to force it to be transpiled again.

## Babel

Babel allows you to use the latest developments in the EcmaScript standard (ie. ES6)
in the Clarive JS VM, which conforms up to ES5.

```javascript
"use transpiler(babel)";

// Expression bodies
evens = [2,4,6,8]
var odds = evens.map(v => v + 1);
var nums = evens.map((v, i) => v + i);

// Interpolate variable bindings
var name = "Bob", time = "today";
print(`Hello ${name}, how are you ${time}?`);

class Animal {
    constructor(name, voice) {
        this.name = name;
        this.voice = voice;

        this._eyes = 2;
    }
    get eyes() {
        return this._eyes;
    }
    speak() {
        console.log(`The ${this.name} says ${this.voice}.`);
    }
}

var foo = new Animal('dog', 'woof');
foo.speak(); // The dog says woof.
```

For more information, checkout the Babel documentation
at [https://babeljs.io/docs/learn-es2015/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://babeljs.io/docs/learn-es2015/)

## TypeScript

TypeScript is a strict superset of JavaScript, and adds optional static typing
and class-based object-oriented programming to the language

```typescript
"use transpiler(typescript)";

class Greeter {
    greeting: string;
    constructor(message: string) {
        this.greeting = message;
    }
    greet() {
        return "Hello, " + this.greeting;
    }
}

let greeter = new Greeter("world");
print( greeter.greet() );
```

For more information:

- [http://www.typescriptlang.org/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://www.typescriptlang.org/)
- [https://en.wikipedia.org/wiki/TypeScript <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/TypeScript)

## CoffeeScript

CoffeeScript is a programming language that transcompiles
into JavaScript, adding syntatic surgar that resembles Ruby, Python
and Haskell.

```coffeescript
"use transpiler(coffeescript)";

class Animal
  constructor: (@name) ->

  move: (meters) ->
    alert @name + " moved #{meters}m."

class Snake extends Animal
  move: ->
    alert "Slithering..."
    super 5

class Horse extends Animal
  move: ->
    alert "Galloping..."
    super 45

sam = new Snake "Sammy the Python"
tom = new Horse "Tommy the Palomino" if true

sam.move()
tom.move()
```

For more info:

- [https://en.wikipedia.org/wiki/CoffeeScript <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/CoffeeScript)
- [http://coffeescript.org/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://coffeescript.org/)

## Creating Transpilers

Transpilers can be created as part of a plugin, by adding a special procesor
anonymous function to the `[plugin]/transpiler/` folder.

For creating a transpiler from a standard transpiler library,
it is recommended you install first the library in `[plugin]/modules/`, then
write a lightweight transpiler that `require()`s the library.

This is the transpiler procesor skelleton,
ie `[plugin]/transpiler/mytranspiler.js`:

```js
(function(code){
    var tr = require('mytranspiler-lib.js');
    return tr.transpile(code);
})
```

The anonymous function receives `code` as an argument, which is the full body
of the pre-transpiled code.

The function must return a string with the transpiled code.

Now, we can use it in our Clarive JS DSL:

```js
"use transpiler(mytranspiler)";

// .. my pre-transpiled code ..

```

