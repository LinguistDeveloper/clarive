---
title: cla/t - Testing
index: 5000
icon: page
---

Este módulo contiene funciones
que refuerzan el plugin de testing de Clarive.

De manera genérica, se utilizará este módulo
para las pruebas dentro de un fichero `plugin/t/[test-case].js`, y 
se puede probar con el comando:

    cla plugin-prove test-case.js

El comando buscará el archivo `test-case.js`
en los pluguns y lanzará la prueba.

Para más información, lea la [sección sobre los plugins de pruebas aqui](devel/plugins).

### t.subtest(nombre, function(){ ... })

Comienza un nuevo subtest  el cual es un grupo de casos de prueba asociado a una funcionalidad.

El subtest `nombre`  tiene que ser único en el paquete de pruebas.

```perl
var t = require('cla/t');

t.subtest('testing it works', function(){
   t.is( 1, 1);
});

t.subtest('testing some other thing', function(){
   t.is( 1, 1, 'comparing 1 and 1');
});

t.doneTesting();
```

La agrupación de pruebas ayuda a aislar las comparaciones individuales
y colecciones de prueba, creando una sensación de alcance y
mejorar la legibilidad conjunto de pruebas y mantenimiento.

### t.doneTesting()

Le dice al proceso que ejecuta los test que han concluido.

sólo puede ser declarado una vez durante la prueba. Una vez que la
realización de pruebas está terminado, no se ejecutan más.

### t.ok(a,[nombre])

Pasa si `a` es verdadero (*true*)

### t.is(a,b,[nombre])

Pasa si `a` y `b` son iguales.

```javascript
var t = require('cla/t');
var x = 'aa';
t.is( x, 'aa' );
```

### t.isnt(a,b,[nombre])

Pasa si `a` y `b` son diferentes.

```javascript
var t = require('cla/t');
var x = 'bb';
t.isnt( x, 'aa' );
```

### t.like(a,b,[nombre])

Pasa si `a` coincide usando una expresión regular con `b`

```javascript
var t = require('cla/t');
t.subtest('testea aqui otra vez', function(){
   t.like( 'abc', cla.regex('a.*') );
});
```

### t.unlike(a,b,[nombre])

Lo contrario a `t.like()`

```javascript
var t = require('cla/t');
t.subtest('testing again here', function(){
   t.unlike( 'abc', cla.regex('^..$') );
});
```

### t.pass(msj)

Emite una señal de pase manualmente, declarando
que la prueba es correcta.

```javascript
var t = require('cla/t');
t.subtest('testing a pass', function(){
    var x = 10;
    if( x == 10 ) {
        t.pass('not a 10');
    }
});
```

### t.fail(msj)

Emite una señal de pase manualmente, declarando
que la prueba es incorrecta.

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

Controla el número de pruebas y si se llevarán a cabo.

```javascript
var t = require('cla/t');
t.plan( 'tests', 15 );
t.plan( 'skip_all', 'no internet connection, so no tests' );
```

### t.skip(msj,num-tests)

Omite las pruebas. Esta función es útil
saltarse determinados casos de prueba cuando se
no se implementan o las condiciones
no están bien.

`Skip ()` tiene que establecer el `num tests`
que se saltará. Para establecer el número
de ensayos, véase `plan de ()`


`skip()` tiene que establecer el `numtests`
que se saltará. Para establecer el número de tests `plan()`.

```javascript
var t = require('cla/t');
t.subtest('probando un fallo', function(){
    t.plan( 'tests', 1 );
    var x = 10;
    if( x == 10 ) {
        t.skip("este test no está preparado",1);
    }
});
```

### t.cmpDeeply(a,b,[nombre])

Compara estructuras de datos complejas `a` y `b`, como Objetos o Arrays.

`t.cmp_Deeply ()` tiene un gran número de funciones especiales de comparación que ayudan a evaluar expresiones parcialmente, en gran medida
simplificando los tests

```javascript
var t = require('cla/t');
t.cmpDeeply([1,2],[1,2]);
t.cmpDeeply({aa:10, bb:20},{bb:20, aa:10});
t.cmpDeeply([1,2],[1, t.ignore() ]);
t.cmpDeeply([1,2], t.bag(2,1) );
t.cmpDeeply([1,2], t.set(2,1) );
```

#### t.ignore()

Esta es la mejor manera de comprobar que existen valores o elementos
en una estructura de datos sin tener que especificar su valor real.

```javascript
var t = require('cla/t');
t.cmpDeeply(
    ['foo','bar',{ aa: 10 }],
    [t.ignore(), t.ignore(), { aa: t.ignore() } ]
);
```

#### t.re(regexp)

Permite comparaciones parciales de *strings* usando expresiones regulares.

```javascript
var t = require('cla/t');
var arr = ['foo','bar'];
t.cmpDeeply( arr, [ t.re('^f'), t.re('...') ] );
```

#### t.set(...)

Esto hace una comparación en conjunto, es decir, que compara dos arrays, pero ignora el
orden de los elementos y no tiene en cuenta los elementos duplicados, por lo que

    t.cmpDeeply([1, 2, 2, 3], set(3, 2, 1, 1));

pasará los tests.

#### t.bag(...)

Esto hace una comparación *bag*, es decir, que compara dos arrays pero ignora el
orden de los elementos de modo que

  t.cmpDeeply([1, 2, 2], bag(2, 2, 1))

pasará los tests.

#### t.superbagof(...)
#### t.subbagof(...)
#### t.supersetof(...)
#### t.subsetof(...)
#### t.noneof(...)

Estos operadores permiten la comparación parcial de
elementos de los arrays.

    t.cmpDeeply([11], t.subsetof(22,11) );  // PASS
    t.cmpDeeply([11,22,33], t.supersetof(22,11) );  // PASS

### t.all(...)

Agrupa muchas comparaciones de los test en un operador `AND`

### t.any(...)

Agrupa muchas comparaciones de los test en un operador `OR`