---
title: Extendiendo el sistema JS a través de módulos
index: 2000
icon: page
---

Para extender el código JS recomendamos utilizar dos estrategias:

## Módulos

Los módulos incluidos por el usuario deben ser almacenados en el sistema de archivos, bajo la carpeta 
`DECLARATIVE_BASE/plugins/[nombre-plugin]/carpeta modules`.

Para crear la carpeta de módulos, se recomienda
crear antes el plugin en el [directorio](setup/directories) `CLARIVE_BASE`.

```javascript
// crear el fichero plugins/myplugin/modules/myutil.js:
(function(){
    return {
        doThis: function(num) {
            print(""Esto es": " + num);
        }
    }
}());

// Ahora uselo en su código
var myutils = require("myutil");
if( myutils ) {
    myutils.doThis(123);
} else {
    print( "no se encuentra myutil" );
}
```

## Reglas

Escribe una regla independiente con la lógica necesaria para ser usada por otras reglas.
Luego invocar esa regla como parte de su código.

Escribe una regla con una operación en código JS con el siguiente contenido:


```javascript
var something = cla.stash("something");
cla.stash("myresults", something * 1000 );

var stash = { something: 123 };
cla.rule.run('my_rule_runner', stash);
print( "results=" + stash.myresults );  // obtienes 123000
```

Lea más sobre `cla.rule` [aquí](devel/js-api/rule)
