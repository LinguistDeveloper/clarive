---
title: Un rápido vistazo a JavaScript
index: 2000
icon: page
---

Se trata de una cartilla rápida para ayudarte a empezar con el JavaScript en caso de que
Nunca visto antes.

Esta es una primera ayuda para comenzar a utilizar JavaScript en caso de no haberlo visto antes.

Para realizar estás pruebas, utilice el REPL de Clarive.
El REPL es una buena herramienta para comenzar con JavaSCript dentro de un entorno de automatización de Clarive. Consulte la documentación sobre el [REPL aquí](devel/repl) para aprender más de la herramienta.

## Hola mundo

Este es el programa más básico que se puede escribir:

```javascript
print('Hola mundo');
```

## Sintaxis básica

Todos los programas JS de Clarive son estrictos por defecto. Esto se hace estableciendo un `use strict` al comienzo de la evaluación del código.

Este es un ejemplo de código que fallará:

```javascript
xx = 20;
print(xx); // error de sintaxis debido a que no se ha definido el tipo de variable xx
```

## Declarando variables

Las variables se declaran con la palabra reservada `var`. JavaScript no tiene tipos por lo que no es necesario definirlos explícitamente.

```javascript
var foo;
foo = 100;
var bar = 10;
var edad,tiempo,direccion;
```

## Condicionales

Los condicionales en JavaScript se realizan mediante la instrucción `if`:

```javascript
var foo = false;
if( foo ) {
    bar();
} else {
    // ...
}

// además, se puede utilizar switch-case para gestionar condiciones adicionales

var xx = 100;
switch(xx) {
    case 100:
    print('bajo');
    break;
    case 200: print('alto');
}
```

## Bucles

Los bucles permiten repetir un código tantas veces como sean necesarias.
La mayoría de bucles en JS están construidos utilizando `for` y `while`.

```javascript
for( var i=10; i<100; i++ ) {
    print("Hola " + i);
    if( i > 20 ) {
        break;
    }
}
```

Otra manera elegante y limpia de iterar a través de arrays es usar `map()` que está soportado de manera nativa en Clarive JS.

```javascript
var arr = [1,2,3];
arr.map(function(el){
    print( "Este es " + el );
});
```

## Arrays

```javascript
var arr = [];
arr.push( 100 );

var arr2 = [1,2,3];
var arr3 = arr2.concat( arr, 100 );

print( arr3.join(',') );
```

## Objetos

```javascript
var obj = {};
obj[ 'miValor' ] = 100;

// las claves de objeto también se pueden anidar
obj = { direccion: {} };
obj['direccion']['cp'] = 90210;
```

También puede usar la notación reducida:

```javascript
var obj = { miValor: 200 };
// these are the same:
print( obj.miValor );
print( obj[ 'miValor' ] );
```

## Funciones

```javascript
function nada(name) {
    return "Nada es todo, querido " + name;
}

print( nada("Bob") );
```

## La consola

Existen un conjunto de los métodos de `console` implementados en el JS de Clarive.

```javascript
console.log({aa:11});
console.warn('Hola!');  // un error estándar
console.dir({aa:22});
console.info({aa:22});
console.assert(true, 'nada');
```

## Realizar plantillas y strings multilíneas

Para escribir strings multilíneas que pueden utilizarse en plantillas (por ejemplo, que tienen variables interpoladas), Clarive implementa el estándar de literales ECmascript ES6

Esto se hace entrecomillando la cadena con comillas sencillas:

```javascript
var txt = `Esto es 
un string
multilínea
`;

print(txt);
```

Este es también un buen mecanismo de plantillas, ya que
se pueden interpolar expresiones (incluyendo variables)
que se puede ejecutar como JavaScript en una función.

```javascript
var name = 'Joe';
var address = `111 Elm St.
Nowhere, NY 10001
`;
var html = `
<div>
    <strong>${name}</strong>
    <strong>${address}</strong>
</div>
`;

print(html);
```

No solo las variables pueden ser interpoladas, también es posible realizarlo con expresiones:

```javascript
num = 100;
print(`
Esto es el valor: ${num}
Esto es el doble: ${num * 2}
`);
```

Para evitar la interpolación de una variable o expresión, utilizar la barra invertida `\${...}`

```javascript
var bashScript = `
echo \${var};
exit 1;
`;
```

### Heredocs

Los strings en plantilla pueden ser extremadamente poderosos, y aquí es donde *heredocs*
(o [here-documents <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/Here_document)),
 lo simplifica, además, implementa el formato de string multilínea.


La ventaja de utilizar heredocs es que evita tener que
escapar las variables con plantilla (es decir `${myvar}`) lo cual podría entrar en conflicto
con el sistema actual de variables de Clarive, que utiliza también
la EcmaScript `$ {...}` para el formato de la variable.

Además

Además, otros lenguajes de scripting y sistemas de plantillas 
comparten este espacio (Bash, Perl, etc.) por lo que siempre es bueno contar con cadenas multilínea *no interpoladas* como heredocs.

Un *documento here* permite crear un string que se extienda en varias líneas
y que preserve los espacios en blanco y las nuevas líneas. 

Si ejecuta el siguiente código,
imprimirá exactamente lo que se ve a partir de la palabra Dear hasta la línea anterior a la segunda aparición de END_MESSAGE.

El documento comienza con los caracteres `<<` seguidos de una cadena arbitraria que se convierte en la marca final del documento, seguido de un punto y coma `;` (o salto de línea) que marca el final de la instrucción.

Es un poco extraño ya que la declaración no termina aquí. De hecho, el contenido del documento comienza con la linea posterior al punto y coma, (en nuestro caso con la palabra "Dear"), y continua hasta que PERL encuentra el final de linea marcado. En nuestro caso el string END_MESSAGE.

Todos estos son casos válidos en *heredocs*.

```javascript
var str = <<END_MESSAGE;
Aquí comienza el mensaje.

Un largo "string" .

END_MESSAGE


// fijese que el END_MESSAGE de cierre no acaba en punto y coma ;
print(str);
```
Otro ejemplo, no existe punto y coma despues de la marca final:

```javascript
var str = <<"END"
Hola.

Aqui.

END
print(str);
```

Las marcas de fin no pueden contener espacios y solo aceptan caracteres alfanuméricos con guiones bajos `_`.


## Gestión de los errores

El tratamiento de errores se debe hacer utilizando la declaración `Throw` (a menos que sea un error de log en Clarive JS) en ese caso es mejor utilizar una función más poderosa como es `cla.error()`.

Para atrapar los errores, se utiliza las declaraciones `try-catch` .

```js
try {
    if( algoQueNoEsCorrecto ) {
        throw new Error("Esto no está bien");
    }
    // ... Se sigue procesando por aquí...
} catch(e) {
    print( "Error capturado, todo bajo control: " + e);
}
```

## Mensajes generales de error en JavaScript

Aqui se describen, en general, mensajes de error relacionados con la sintaxis que pueden ser tratados por el intérprete de Clarive JS.


### `TypeError: invalid base value`

Este error indica que un método o atributo está siendo llamado dentro de una variable no definida, donde generalmetne se espera un tipo Objeto o Array.

Por ejemplo:

```js
var myfunc = function(){ return undefined };
var foo = myfunc();  // mi funcioón myfunc() devuelve undefined
print( foo.arg );   // Error valor base no válido
print( foo.doIt() );   // Tambien, error valor base no válido
```

Para solucionar esto, hay que comprobar siempre los objetos y arrays no definidos o vacios (*null*) antes de realizar métodos o atributos que llamen a dichos objetos si no está seguro de que esté haciendo lo correcto.

```js
var myfunc = function(){ return undefined };
var foo = myfunc();
if( foo != undefined ) {
    print( foo.arg );
} else {
    throw new Error("No es el valor que esperaba!");
}
```

### `ReferenceError: identifier '...' undefined `

Este error se produce cuando hay un intento de
utilizar una variable o función que no ha sido definida.

```
print( xxx );
// ReferenceError: identificador 'xxx' no definido
```

Recuerde que Clarive JS tiene las estructuras activadas por defecto, lo que requiere que 
cada variable sea declarada en el contexto actual.

### `TypeError: not callable`

Este error se produce cuando se intenta llamar a un método que
no es parte de un objeto. Por ejemplo:

```js
var obj = { age: function(){ return 19 } };
print( obj.age() ); // imprime 19
print( obj.name() ); // TypeError: not callable
```

### `SyntaxError: parse error`

Este error puede deberse a un error interno, el cual
puede ser que tenga más datos o información más abajo del mensaje.

### `SyntaxError: error parsing token`

Error causado por una sintaxis de JavaScript inválida como utilizar caracteres incorrecto o inválidos.

### `SyntaxError: unterminated statement`

Suele deberse a que falta algún punto y coma `;` en el código.

## Módulos incluidos

Clarive JS puede cargar módulos JavaScript desde el sistema de archivos.
El software se suministra desde módulos, tales como *Handlebars.js*
y *Underscore.js*.

Se pueden incluir más módulos en el directorio `plugins/[plugin]/modules` en la base de Clarive.

[Lea más sobre los plugins aquí](devel/plugins).

### Handlebars

Handlebars son un sistema de plantillas, para la sustitución de
cadenas dentro de otros datos del formulario.

```javascript
var hs = require('handlebars');
var tt = "Hola,\
    soy {{mom}}\
    ok?\
    ";
var foo = hs.compile(tt);
print( foo({ mom: "Johanna"}) );
```

Para más información, lea las [Handlebars.js <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://handlebarsjs.com/)

### Underscore

Underscore.js es una libreria de utilidades que añaden muchas funciones útiles para el objeto global `\_` (guión bajo)

```javascript
var _ = require('underscore');
_.each([1,2], function(x){ print(x) });
```

Para más información, lea las [referencias a la librería Underscore <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://underscorejs.org/)

## No implementado en Clarive

Estas son algunas de las funciones que no están implementadas por el intérprete de
Clarive JS:

- `alert()`, `confirm()` y otras funciones de mensajería
- `console.log()` y otros métodos `console`
- `window`, `document` y otras funciones relacionadas con DOM
- `system.` y otras funciones de NodeJS
- una máquina de eventos: Clarive JS cuenta con una interfaz de bloqueo y el código es no reentrante


Así que, básicamente, sólo recuerda:

- ***Clarive JS no es un intérprete del navegador, no tiene DOM o un concepto similar***
- ***Clarive JS no es NodeJS***

## Lecturas recomendadas

Nuestro objetivo es simplemente dar al lector unos conceptos básicos para comenzar con el lenguaje.

Para una aprender más profundamente acerca del lenguaje JavaSript, también de **Ecmascript**, recomendamos las siguientes lecturas:

- Guia: The Mozilla JavaScript - [https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide)
- Libro: JavaScript "The Good Parts" - [http://bdcampbell.net/javascript/book/javascript_the_good_parts.pdf <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://bdcampbell.net/javascript/book/javascript_the_good_parts.pdf)


