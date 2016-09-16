---
title: Transpiladores, Babel, CoffeeScript y TypeScript
index: 5000
icon: page
---

Los transpiladores (o transcompiladores) de JavaScript son herramientas que convierte un lenguaje específico a JavaScript ES. Recoge como entrada el código fuente de un programa escrito en un lenguaje de programación y produce su equivalente en otro lenguaje de programación.

Clarive soporta transpiladores para filtrar y preprocesar código JS antes de ser ejecutado. Clarive incorpora además algunos transpiladores preinstalados:

- Babel (ES2015)
- CoffeeScript
- TypeScript

## Usando Transpiladores

Para disponer de su código de procesado a través de uno de los transpiladores instalados
utilizar un pragma especial de JavaScript creado para esta finalidad.

El pragma para activar la transpilación es:

```js
    "use transpiler([transpiler name])";
```

Esto tendrá el **cuerpo de todo el código fuente** transpilado,
independientemente de donde se declare el pragma.

Observe que, aunque transpilar no es una operación muy costosa, cada vez que se crea nuevo código fuente, debe de ser transpilado, lo que provoca más carga para el transpilador, y para parsear y convertir a JavaScript. Clarive cachea el código transpilado, por lo que la próxima ejecución solo costará lo mismo que si ya estuviera escrito en JavaScript, lo que mejora en un 100x la velocidad de ejecución.

Si experimenta problemas con el código transpilado cacheado, intente borrar la caché para forzar al programa a transpilar de nuevo su código.


## Babel

Babel permite utilizar los últimos desarrollos en el estándar EcmaScript (por ejemplo ES6) en la VM de Clarive JS que se ajusta a ES5.

```javascript
"use transpiler(babel)";

// Expresiones
evens = [2,4,6,8]
var odds = evens.map(v => v + 1);
var nums = evens.map((v, i) => v + i);

// Interpolate variable bindings
var name = "Bob", time = "hoy";
print(`Hola ${name}, como estás ${time}?`);

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
        console.log(`The ${this.name} dice ${this.voice}.`);
    }
}

var foo = new Animal('perro', 'woof');
foo.speak(); // El perro dice woof.
```

Para más información, consulte la información de Babel en [https://babeljs.io/docs/learn-es2015/](https://babeljs.io/docs/learn-es2015/)

## TypeScript

TypeScript es un superconjunto de JavaScript, que añade tipado estático y objetos basados en clases.

```typescript
"use transpiler(typescript)";

class Greeter {
    greeting: string;
    constructor(message: string) {
        this.greeting = message;
    }
    greet() {
        return "Hola, " + this.greeting;
    }
}

let greeter = new Greeter("mundo");
print( greeter.greet() );
```

Para más información:

- [http://www.typescriptlang.org/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://www.typescriptlang.org/)
- [https://en.wikipedia.org/wiki/TypeScript <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/TypeScript)


## CoffeeScript

CoffeeScript es un lenguaje de programación que se transcompila a JavaScript, añadiendo azúcar sintáctico inspirado en Ruby, Python y Haskell.

```coffeescript
"use transpiler(coffeescript)";

class Animal
  constructor: (@name) ->

  move: (meters) ->
    alert @name + " moved #{meters}m."

class Serpiente extends Animal
  move: ->
    alert "Culebrea..."
    super 5

class Caballo extends Animal
  move: ->
    alert "Galopa..."
    super 45

sam = new Serpiente "Sammy la pitón"
tom = new Caballo "Tommy el palomino" if true

sam.move()
tom.move()
```

Para más información:

- [https://en.wikipedia.org/wiki/CoffeeScript <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/CoffeeScript)
- [http://coffeescript.org/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://coffeescript.org/)

## Creando Transpiladores

Es posible crear transpiladores como parte de un plugin, añadiendo un proceso especial con la función anónima en la carpeta `[plugin]/transpiler/`.

Para la creación de un transpilador desde una librería estándar desde otro, se recomienda instalar primera la librería en el directorio `[plugin]/modules/`, después escribir un transpilador ligero que requiera (`require()`)la librería.

Este es un esqueleto de un proceso de un transpilador, por ejemplo: `[plugin]/transpiler/mytranspiler.js`:

```js
(function(code){
    var tr = require('mytranspiler-lib.js');
    return tr.transpile(code);
})
```

La función anónima recibe `code`como argumento, el cual contiene todo el cuerpo del código pre-transpilado.

La función debe devolver un string con el código transpilado.

Ahora, se puede usar en nuestro DSL de Clarive JS:

```js
"use transpiler(mytranspiler)";

// .. mi código pre-transpilado

```

