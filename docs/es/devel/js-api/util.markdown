---
title: cla/util - Utilidades generales
index: 5000
icon: page
---

Utilidades generales para el *namespace*

### util.dumpYAML(dato)

Vuelca el argumento `dato` como [YAML](concepts/yaml).

```javascript
var util = require("cla/util");
var data = { foo: 123 };
print( util.dumpYAML(data) );
```

### util.loadYAML(dato)

Carga `dato` desde un [YAML](concepts/yaml) *string*.

```javascript
var util = require("cla/util");
var yaml = "---\nfoo: 12\n";
print( util.loadYAML(yaml) );
```

### util.dumpJSON(dato)

Vuelca el argumento `dato` como [JSON <img class='ext-link' src='static/images/icons/window-new.svg' />](https://en.wikipedia.org/wiki/JSON).

```javascript
var util = require("cla/util");
var data = { foo: 123 };
print( util.dumpJSON(data) );
```

### util.loadJSON()

Carga `dato` desde un [JSON <img class='ext-link' src='static/images/icons/window-new.svg' />](https://en.wikipedia.org/wiki/JSON) *string*.

```javascript
var util = require("cla/util");
var json = '{ "foo": 30 }'
print( util.loadJSON(json) );
```

### util.unaccent(str)

Elimina acentos y otros caracteres extraños de una cadena dada,
sustituyéndolos por su carácter distintivo equivalente sin acento.

```javascript
var util = require("cla/util");
print( util.unaccent("résumé") ); // devuelve "resume"
```

### util.benchmark(n,codigo)


Ejecuta el bloque de `codigo` un total de` n` veces e imprime el tiempo como resultado.
 de los tiempos. Esto es útil para ayudar a problemas de rendimiento o a probar cómo el rendimiento de un código antes de utilizarlo en producción.

```javascript
var util = require("cla/util");
util.benchmark(1000, function(){
    for( var i=0; i<100; i++) {
        var x = i * 2;
    }
});
```

Que imprime los siguientes resultados (en función del rendimiento del sistema):

`timethis 100:  4 wallclock secs ( 4.16 usr +  0.03 sys =  4.19 CPU) @ 23.87/s (n=100)`

