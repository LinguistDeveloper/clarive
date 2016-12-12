---
title: Clarive JavaScript DSL
index: 5000
icon: page
---

El acceso a la poderosa funcionalidad Clarive del DSL JS
se inicia con el objeto `cla`:

Estos son los espacios (*namespace*) de primer nivel disponibles:

- `cla` - primer nivel del namespace y los accesos directos a otras utilidades de uso frecuente.
- `cla/ci` - manipulación de CIs.
- `cla/console` - objeto de la consola JavaScript.
- `cla/db` - manipulación de la base de datos MongoDB.
- `cla/log` - logs.
- `cla/fs` - manipulación de los ficheros del sistema.
- `cla/path` - manipulación de las rutas de los ficheros.
- `cla/rule` - manipulación de reglas.
- `cla/sem` - semáforos.
- `cla/t` - testing.
- `cla/util` - utilidades generales.
- `cla/web` - herramientas web.
- `cla/ws` - reglas Webservice Petición/Respuesta.

Hay mas *namespaces* disponibles para el desarrollador y pueden ser añadidas mediante módulos `requier()`.

## Funciones Cla

El namespace Cla encapsula todas las clases, *singletons* y funciones disponibles en la API JS de Clarive.

La mayoría de las funciones útiles están a un nivel inferior de anidación en el namespace, pero muchas de las funciones comunes se proporcionan como propiedades directas a Cla.


#### cla.stash()

Obtiene y establece los datos dentro y fuera del [stash](concepts/stash) actual.

```javascript
cla.stash("filename", "/tmp/file.txt");
print( cla.stash("filename") );

// it also supports nested data structures with JSON pointers
cla.stash("/domain/filename", "/tmp/file.txt");
print( cla.stash("domain.filename") );
```

Para leer el conjunto de datos en los niveles anidados, Clarive
implementa un subconjunto de punteros JSON estándar:

- `/foo/bar` - obtener/establece la clave `stash.foo.bar`
- `/foo/bar` - desactiva los punteros, obtener/establece la clave `stash["/foo/bar"]`
- `foo/bar` - no hay puntero si no comienza el string con la barra `/`, por lo que obtiene/establece la clave `stash["foo/bar"]`
- `/foo/0` - obtiene/establece la clave `stash["foo"][0]` desde un array.
- `/foo/0/bar` - obtiene/establece la clave `stash["foo"][0]["bar"]` desde un objeto en un array.

#### cla.config()

Obtiene y establece los datos de configuración dentro del sistema de configuración de Clarive.

El sistema de configuración de Clarive está construido en base a la combinación de tres capas de valores:

- A partir de los archivos de entorno actuales y globales (*clarive.yml*, *env.yml*)
- Los parámetros enviados a través de la linea de comandos al arrancar el servidor.

```javascript
// obtiene el valor de los workers en el archivo clarive.yml
var wks = cla.config("workers");

// nuestra actual base de datos
var dbname = cla.config("/mongo/dbname");
```

Esto es útil para crear archivos específicos `.yml`
y poner ahí la configuración de la automatización.

#### cla.configTable()

Obtiene y establece los datos de configuración desde/hacia la [Tabla de configuración](concepts/config-table).

El sistema de configuración de Clarive está construido en base a la combinación de tres capas de valores:

```javascript
// coge el valor de los workers en el fichero clarive.yml
var gitHome = cla.configTable('config.git.home');
```

La tabla de configuración es una tabla plana con valores separados con puntos `.` , 
como por ejemplo `config.git.home`.

Esto también es útil para crear valores de configuración globales que pueden ser cambiados fácilmente sin necesidad de editar la regla, aunque en general, es mejor 
utilizar [variables](concepts/variable) (CI) para ello.

#### cla.parseVars(target,dato)

Esta función reemplaza las variables de Clarive (`${varname}`)
en strings o cualquier estructura de datos anidada, como arrays u objetos.
El valor de las variables vendrá o bien el por el argumento `dato`o por el [stash](concepts/stash).

```javascript
cla.stash("foo", 99);
var txt = cla.parseVars("Esto mide"); // esto mide 99 centímetros

cla.stash("name", "Haley");
var txt = cla.parseVars("Hola ${name}", { name: "Joe" });  // Hola Joe
```

### cla.printf(fmt,args)

Imprime un string formateado con la habitual convención de *printf* de la función printf de la librería C.


```javascript
var fs = require('cla/fs');
cla.printf("Este fichero es de %d bytes", fs.stat("/tmp/myfile").size );
```

### cla.sprintf(fmt,args)

Imprime un string formateado con la habitual convención de *printf* de la función sprintf de la librería C.

```javascript
var fs = require('cla/fs');
var msg = cla.sprintf("Este fichero es de %d bytes", fs.stat("/tmp/myfile").size );
print( msg );
```

### cla.dump(datos)

Imprime los datos en una estructura de datos utilizando el formato YAML.

### cla.loc(lang,str,argumentos)

Localiza la cadena de texto usando el formato de I18N
para el idioma especificado en la cadena lang.
Esta función utiliza los archivos de traducción I18N de Clarive.


```javascript
var jobNum = 1234;
var msg = cla.loc("es","Job %1 iniciado", jobNum );
print( msg );
```

### cla.lastError()

Devuelve en un string el último error.

```javascript
print( cla.lastError() );
```

