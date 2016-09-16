---
title: cla/process - Información del proceso
index: 5000
icon: page
---

La extensión de Clarive process se encarga de conseguir información útil sobre el sistema y los procesos del mismo.


### cla.pid()

Saca el ID del proceso que esta ejecutando el código.

```javascript
var proc = require("cla/process");
proc.pid();
```

### cla.title()

Saca el nombre del proceso que está ejecutando el código.

```javascript
var proc = require("cla/process");
proc.title();
```

### cla.arch()

Saca la arquitectura del sistema.

```javascript
var proc = require("cla/process");
proc.arch();
```

### cla.os()

Saca el sistema operativo.

```javascript
var proc = require("cla/process");
proc.os();
```

### cla.env()

Saca todas las variables de entorno del sistema y sus valores.

```javascript
var proc = require("cla/process");
proc.env();
```

También se puede especificar una variable de entorno para obtener su valor.

```javascript
var proc = require("cla/process");
proc.env('BASELINER_DEBUG');
```


### cla.argv()

Saca el vector de argumentos que esté empleando el código ejecutado.

```javascript
var proc = require("cla/process");
proc.argv();
```

### cla.args()

Saca el número de argumentos que está utilizando el proceso del código.

```javascript
var proc = require("cla/process");
proc.args();
```

