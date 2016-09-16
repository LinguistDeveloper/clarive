---
title: cla/ci - Clases CI
index: 5000
icon: page
---

En términos de programación, cada elemento de configuración (CI)
puede tener tanto los datos, como el comportamiento encapsulados en cada clase CI e instancia de CI.

## Instanciando un CI desde la Base de datos

Instanciar un CI significar cargar un CI existente desde la base de datos de CI de Clarive.

Esto se consigue utilizando la función `ci.load(mid)`.

```javascript
var ci = require("cla/ci");
var server = ci.load(123);
```

## Instanciando CIs

Para crear un CI, primero necesitamos cargar las clases de CI deseadas y guardarlas en una variable.

```javascript
var ci = require("cla/ci");
var GenericServer = ci.getClass('GenericServer');
```

Ahora podemos generar una instancia *en memoria* del CI. De manera genérica, esta instancia es útil, excepto cuando todavía no está guardada en la base de datos.

Para guardar el CI en la base de datos, tan solo  hay que llamar al método `save()`.

```javascript
var ci = require("cla/ci");
var GenericServer = ci.getClass('GenericServer');
var server = new GenericServer({ name: 'myhost', hostname:'myhost.intranet' });
server.save();
```

Este método  devuelve un `mid`, que identifica al CI en la base de datos.

## Creando nuestros propios CIs

Es posible crear sus propias clases de CI con sus correspondiente almacenamiento y métodos.

```javascript
var ci = require("cla/ci");
ci.create("MyClass",{
    has:{
        ipAddress: { is:"rw", isa:"Str", required: true }
    },
    superclasses: ['GenericServer']
});

var obj = ci.build("MyClass",{ ipAddress: 22, hostname:'myhost.intranet' });
obj.ipAddress();

//De manera alternativa
var MyClass = ci.getClass("MyClass");
var obj  = new MyClass({ ipAddress: '123.0.0.1', hostname:'myhost.intranet' });

// now all CI methods will be available
var mid = obj.save();
var again = ci.load(mid);
```

Una vez creada su propia clase de CI, no se pueden añadir nuevos métodos o atributos.

## Buscando CIs

La búsqueda de CIs se puede realizar de dos maneras diferentes, mediante la devolución de los objetos CI instanciados o en los documentos de la base de datos.


La principal diferencia está en que los documentos de la base de datos son más rápidos de
recuperar, pero puede ser utilizado en modo *sólo lectura*. Los objetos CI tienen métodos
que puede ser manipulados y persistidos.


### ci.find([clase], consulta)

Devuelve un cursor al conjunto de resultados de un CI en base de datos.

El cursor tiene los mismos métodos que un cursor en la base de datos

```javascript
var ci = require("cla/ci");
var rs = ci.find({ hostname: cla.regex("^127.0") });
rs.forEach(function(doc) {
    print( doc.mid );
});
```


Opcionalmente, una clase puede ser enviada como parámetro para limitar
la búsqueda a los documentos que pertenecen sólo a esa clase.

```javascript
var ci = require("cla/ci");
var rs = ci.find('Status', { name: cla.regex('QA') });
print( rs.next() );
```

### ci.findOne([clase], consulta, opciones)

Devuelve el primer documento que coincide con la consulta.

```javascript
var ci = require("cla/ci");
var doc = ci.findOne({ mid:"123" });
print( doc.mid );
```

Opcionalmente, una clase puede ser enviada como parámetro para limitar
la búsqueda a documentos que pertenecen sólo a esa clase.

```javascript
// find a document within the Status class only
var ci = require("cla/ci");
var doc = ci.findOne('Status', { name: cla.regex('^QA') });
```

### ci.load(mid)

Instancia un CI previamente almacenado en la base de datos.

### ci.delete(mid)

Elimina un CI con el `mid` dado.

## Disponibilidad general de una clase

Para ser capaz de hacer pleno uso de una clase CI fuera del código de una regla, la clase de CI debe ser cargada como parte del proceso de inicio de Clarive.

Ponga el archivo JS para la clase en el directorio `$CLARIVE_BASE/plugin/[plugin-name]/cis` para que pueda ser recogido por el comando `cla`durante el inicio del sistema.

## Meta Programación

La siguiente introspección del sistema de clases de CI está disponible:

### ci.listClasses([rol])

Devuelve un array con las clases CI cargadas en Clarive.

Con el parámetro opcional `role`, filtra la lista de un rol dado.

```javascript
var ci = require("cla/ci");
var all = ci.listClasses();
var appservers = ci.listClasses('ApplicationServer');
```

Esto es útil para comprobar si un módulo dependiente determinado se carga antes de intentar una operación dada.