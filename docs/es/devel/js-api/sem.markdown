---
title: cla/sem - Control de semáforos
index: 5000
icon: page
---

Este *namespace* contiene
funciones que permiten al desarrollador
usar semáforos en su código.

#### sem.take(clave,código)

Toma un semáforo para ejecutar el bloque de código
pasado como argumento.

```javascript
var sem = require("cla/sem");
var log = require("cla/log");
var ret = sem.take('abc', function(){
    cla.sleep(0.05);
    log.info( 'mi ejemplo' );
    return 123;
});
print( ret );
```

Esto consume 1 ranura de semáforos. Normalmente, esto significa que ningún otro proceso puede tomar el mismo semáforo, salvo que un administrador haya aumentado la disponibilidad de la ranura del semáforo en cuyo caso puede coger más de un proceso.

La ranura del semáforo es liberada al final.

#### sem.purge(clave)

Purga todos los semáforos que están bloqueados por la clave dada, 
liberando simultáneamente todos los procesos que están en espera
de un semáforo.

Esta función es útil para desbloquear los recursos del sistema que
han bloqueados y no fueron liberados.