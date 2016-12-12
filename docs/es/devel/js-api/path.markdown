---
title: cla/path - Manipulación de rutas
index: 5000
icon: page
---


Estas aplicaciones son útiles para la modificación de los nombres de las rutas si están rotas o montarlas juntas, y puede ser útil para el cálculo de rutas relativas

### path.basename(ruta)

Recoge el nombre y la extensión del archivo de una ruta.


```javascript
var path = require("cla/path");
var filepath = "/tmp/dir/file.txt";
print( path.basename(filepath) ); // imprime file.txt
```

### path.dirname(ruta)

Extrae el directorio de una ruta.

```javascript
var path = require("cla/path");
var filepath = "/tmp/dir/file.txt";
print( path.dirname(filepath) ); // imprime /tmp/dir
```

### path.extname(ruta)

Extrae la extensión del fichero de una ruta.

```javascript
var path = require("cla/path");
var filepath = "/tmp/dir/file.txt";
print( path.extname(filepath) ); // imprime txt
```

### path.join(ruta)

Concatena varias partes para crear una única ruta

```javascript
var path = require("cla/path");
var path1 = "/tmp";
var path2 = "dad";
print( path.join(path1,path2,"file.txt") ); // imprime /tmp/dad/file.txt
```


