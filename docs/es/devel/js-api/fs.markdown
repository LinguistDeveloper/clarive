---
title: cla/fs - Acceso al sistema de ficheros locales
index: 5000
icon: page
---

Estas funciones son para el acceso al sistema de ficheros de la instancia del servidor Clarive.

Para la gestión del sistema de archivos de manera remota, consulte los agentes CI

### fs.createFile(fichero,contenido)

Crea y escribe contenido en un fichero de una sola vez.

```javascript
var fs = require('cla/fs');
fs.createFile("/tmp/myfile", "first line\nsecond line\n");
```

### fs.slurp(fichero)

Lee el contenido de un fichero y como si de un *string* se tratara de una sola vez.

```javascript
var fs = require('cla/fs');
var content = fs.slurp("/tmp/myfile");
```

### fs.openFile(ruta-fichero,modo)

Abre un fichero para leer y devuelve un identificador de archivo.

```javascript
var fs = require('cla/fs');
var fh = fs.openFile("/tmp/myfile", "r");
while( !fh.eof() ) {
    print( fh.readLine() );
}
```

### fh.readLine()

Lee una única linea de un fichero.

```javascript
var fs = require('cla/fs');
var fh = fs.openFile("/tmp/myfile", "r");
while( !fh.eof() ) {
    print( fh.readLine() );
}
```

Devuelve `undefined` si el fichero ha llegado al final.

### fh.readChunk(longitud)

Lee cualquier número de bytes de un archivo.

```javascript
var fs = require('cla/fs');
var fh = fs.openFile("/tmp/myfile", "r");
while( !fh.eof() ) {
    print( fh.readChunk(10) ); // lee sólo 10 bytes del archivo
}
```

Devuelve `undefined` si el fichero ha llegado al final.

### fh.eof()

Compruebe si el manejador de archivos (*filehandle*) ha alcanzado el final del archivo.

### fh.close()

Cierra un fichero.

```javascript
var fs = require('cla/fs');
var fh = fs.openFile("/tmp/myfile", "r");
fh.close();
```

### fh.fileno()

Devuelve el número del manejador de archivos (*filehandle*).

```javascript
var fs = require('cla/fs');
var fh = fs.openFile("/tmp/myfile", "r");
print( fh.fileno() );
```

### fs.iterateDir(ruta-directorio,cb)

Itera a través del contenido del directorio.

```javascript
var fs = require('cla/fs');
fs.iterateDir( "/tmp", function(file,path){
    if( fs.isDir(file) ) return; 
});
```

### fs.stat(fichero)

Devuelve la información sobre el estado de un fichero.

```javascript
var fs = require('cla/fs');
cla.dump( fs.stat("/tmp/myfile") );
```

No todos los campos son compatibles con todos los tipos de sistemas de archivos. Estos son los significados de los campos:

<pre>
 0 dev      número del dispositivo del sistema de archivos
 1 ino      número de inodo
 2 mode     modo de archivo (tipo y permisos)
 3 nlink    número de enlaces (duros) al archivo
 4 uid      ID numérico del propietario del archivo
 5 gid      ID numérico del grupo propietario del archivo
 6 rdev     el identificador de dispositivo (sólo para archivos especiales)
 7 size     tamaño total del archivo, en bytes
 8 atime    tiempo desde el último acceso en segundos
 9 mtime    tiempo desde la última modificación en segundos
10 ctime    tiempo desde el último cambio en el inode en segundos.
11 blksize  tamaño óptimo en bytes para I/O para interactuar con el fichero (puede variar de fichero a fichero)
12 blocks   número real de bloques específicos del sistema asignados en disco (a menudo, pero no siempre, 512 bytes cada uno)
</pre>


### fs.isDir(path)

Devuelve verdadero (*true*) si `path` es un directorio.

### fs.isFile(path)

Devuelve verdadero (*true*) si `path` es un fichero.

### fs.deleteFile(path)

Elimina el fichero.

```javascript
var fs = require('cla/fs');
fs.deleteFile("/tmp/myfile");
```

### fs.createDir()

Crea un directorio en el sistema de archivos,
pero no crea las rutas intermedias.

```javascript
var fs = require('cla/fs');
var dir = "/tmp/dad/son";
if( !fs.isDir(dir) ) {
    fs.createDir(dir);
}
```

### fs.createPath()

Crea un directorio en el sistema de archivos,
en este caso, creando la estructura de directorios necesaria.

```javascript
var fs = require('cla/fs');
var dir = "/tmp/dad/son";
fs.createPath(dir);
```

### fs.deleteDir()

Elimina un directorio vacío

```javascript
var fs = require('cla/fs');
fs.deleteDir("/tmp/dad/son");
```

Devuelve verdadero (*true*) si el directorio se ha borrado de manera correcta.