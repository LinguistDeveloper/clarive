---
title: cla/db - MongoDB namespace
index: 5000
icon: page
---

El *namespace* de la base de datos tiene funciones diseñadas para hacer uso de la base de datos MongoDB donde se está ejecutando Clarive.

### Consideraciones generales

#### Expresiones regulares

El uso de expresiones regulares es necesario para la buscar en Mongo,
por lo cual se hace necesario generar un objeto `cla.regex ()` desde que las expresiones regulares en JavaScript no son compatibles
a través de la interfaz de Mongo.

Ejemplo:

```javascript
var db = require('cla/db');
var doc = db
        .getCollection("topic")
        .findOne({ title: cla.regex("there","i") });
```

##### Encadenar los métodos de cursor

Los métodos de cursor se pueden encadenar
antes de ser ejecutados.

```javascript
var db = require("cla/db");
var docs = db.getCollection('master_doc')
    .find()
    .fields({ bl: true, bls: true, _id: 0 })
    .limit(100)
    .all();
```

### db.getDatabase(nombre-DB)

Devuelve la conexión a la base de datos MongoDB dentro de 
una instancia Clarive MongoDB.

Con el objeto devuelto, se puede utilizar cualquier otro metodo `db`.

```javascript
var db = require('cla/db');
var mydb = db.getDatabase("mydb");
var coll = mydb.getCollection("mycoll");
coll.insert({ id: 1, txt:"my first doc" });
coll.findOne({ id: 1 });
```

### db.getCollection(nombre-colección)

Devuelve una colección de Mongo desde la base de datos.

Una colección es la analogía a una tabla en el mundo de las bases de datos relacionales.

No hay necesidad de crear una nueva colección, sólo utilícela
y se creará de Mongo.

### db.seq(nombre-secuencia, [resetear-contador])

Accede a la tabla de secuencias Clarive
para incrementar la secuencia.

```javascript
var db = require('cla/db');
var nextid  = db.seq('myseq'); // debe ser 1
var another = db.seq('myseq'); // debe ser 2
db.seq('myseq', 1); // reinicia la secuencia a 1
```

### collection.insert(documento)

Inserta un documento en una colección.

```javascript
var db = require('cla/db');
var coll = db.getCollection('mycoll');
coll.insert({ title: 'test', priority: 80, other: [ 1,2,3 ], nested: { a: 11, b: 22 } });
```

### collection.remove(consulta)

Elimina uno o más documentos de una colección.

```javascript
var db = require('cla/db');
var coll = db.getCollection('mycoll');
coll.remove({ title: 'test' });
```

### collection.update(consulta, opciones)

Actualiza documentos en una colección.

```javascript
var db = require('cla/db');
var coll = db.getCollection('mycoll');
coll.update({ title: 'test' }, { $set : { title: 'test2' } });
```

### collection.drop()

Elimina una colección.

```javascript
var db = require('cla/db');
var coll = db.getCollection('mycoll');
coll.drop();
```

### collection.clone()

Copia una colección a otra.

```javascript
var db = require('cla/db');
var coll = db.getCollection('mycoll');
coll.clone('mycoll-copy');
```

### collection.findOne(consulta, [campos])

Encuentra un documento en la colección
y lo devuelve.

Devuelve `undefined` si el documento no se ha encontrado.

```javascript
var db = require('cla/db');
var coll = db.getCollection('mycoll');
coll.insert({ id: 22, title: 'test' });
var doc = coll.findOne({ id: 22, title: 'test' });
print( doc.id );
```

### collection.find(consulta)

Devuelve un cursor con los resultados de la consulta, también 
llamado *set de resultados*.

```javascript
var db = require('cla/db');
var coll = db.getCollection('topic');
var cursor = coll.find({ priority: { $gt: 100 } });
while( cursor.hasNext() ) {
var doc = cursor.next();
print( doc.mid );
}
```

El cursor devuelto de la consulta no se ejecuta hasta que uno de los métodos 
del cursor es llamado (`next ()`, `count ()`, etc.);


### cursor.next()

Devuelve el siguiente documento en el conjunto de resultados del cursor.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
var doc = cursor.next();
```

### cursor.hasNext()

Devuelve verdadero o falso dependiendo de si el cursor
ya ha pasado por todas sus filas.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
if( cursor.hasNext() ) {
// ...
}
```

### cursor.forEach()

Itera en un set de resultados del cursor con una función de devolución de llamada (*callback*).

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
cursor.forEach(function(doc){
print( doc.mid );
});
```

### cursor.all()

Devuelve todos los documentos en el cursor a la vez.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
var docs = cursor.all();
for( var i=0; i < docs.length; i++ ) {
    print( docs[i].mid );
}
```

### cursor.count()

Devuelve el número de documentos recuperados por
un cursor.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
cla.printf( "Found %d rows", cursor.count() );
```

### cursor.limit(numero-filas)

Limita el número de documentos devueltos por el cursor.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
cursor.limit(10);
cla.printf( "Found %d rows", cursor.count() );   // imprime 10 filas
```

### cursor.skip(numero-filas)

Salta las primeras *n* filas del conjunto de resultados devueltos.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
cursor.skip(50);
cursor.limit(10);
cursor.forEach( function(doc){
cla.dump( doc );  // vuelca los documentos del 50 al 60 de la lista de resultados
});
```


### cursor.sort(objeto-ordenacion)

Configura la ordenación del resultado que será devuelto.

```javascript
var db = require('cla/db');
var cursor = db.getCollection('topic').find();
cursor.sort({ title: 1 }); // ordena por mid (como numéricamente)
cursor.sort({ m: 1 }); // ordena por mid (como numéricamente)
```

