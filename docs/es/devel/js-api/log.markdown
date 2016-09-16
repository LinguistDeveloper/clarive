---
title: cla/log - Clases de log
index: 5000
icon: page
---

El log es útil para imprimir los mensajes e informar al sistema de registros de Clarive.

Además, cuando se utiliza en el contexto de trabajos, los mensajes del log se reportan
tanto para el archivo de log como para el registro de trabajo durante la ejecución del mismo.

### Comportamiento común

Todas las funciones de registro tienen un comportamiento argumento común.

Todas las funciones de los logs tienen un comportamiento de los argumentos común.

El primer argumento es, o bien una cadena de mensaje, o un objeto que se descargó.

El segundo argumento puede ser un objeto para ser descargado o un archivo con contenido descargable, en caso de ser un log de un trabajo.

### log.info(msg, args)

Un mensaje informativo.

```javascript
var log = require('cla/log');
log.info("Esta es una información sin formato", { foo: 123 });
```

### log.debug(msg, args)

Un mensaje informativo a un nivel más inferior.

```javascript
var log = require('cla/log');
log.debug("Esta es una información sin formato", { foo: 123 });
```

### log.warn(msg, args)

Un mensaje de advertencia.

```javascript
var log = require('cla/log');
log.warn("Una advertencia");
```

### log.error(msg, args)

Un mensaje de error

```javascript
var log = require('cla/log');
log.error("Un error");
```

### log.fatal(msg, args)

Mensaje de error que también lanza una excepción.
