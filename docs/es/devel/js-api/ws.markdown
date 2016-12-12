---
title: cla/ws - Webservice namespace
index: 5000
icon: page
---

Este *namespace* sostiene la llamada a la gestión de servicio web Clarive 
y es útil para escribir reglas de tipo webservices que escuchen las llamadas 
entrantes en un URL de Clarive.


### ws.request()

Devuelve el objeto de la petición, con los siguientes valores:

#### req.args()

Devuelve los argumentos de la ruta de la petición y se descomponen
en un array.

```javascript
var ws = require("cla/ws");
var req = ws.request();
var args = req.args();
for( var i=0; i<args.length; i++) {
    print( args[i] );
}
```

Por ejemplo, si la regla se invoca con
la URL `http://clariveurl/rule/json/myrule/path1/path2`,
los `req.args ()` devolverá el array `['path1','path2']`.

#### req.body()

Devuelve el cuerpo (*body*) de la petición.

```javascript
var ws = require("cla/ws");
var req = ws.request();
print( req.body() );  // el cuerpo puede ser una cadena de texto enorme
```

#### req.headers([header])

Devuelve las cabeceras de petición como un objeto. Si se especifican los parámetros de cabecera, sólo devuelve el valor de la cabecera dada.

```javascript
var ws = require("cla/ws");
var req = ws.request();
print( req.headers('accept-language') );
```

Algunas de las cabeceras comunes se pueden obtener de una llamada al navegador:

[https://en.wikipedia.org/wiki/List_of_HTTP_header_fields <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/List_of_HTTP_header_fields)

Cómo enviar cabeceras (mi cabecera y otras) con una llamada al comando `curl`:

`curl -Hmyheader=123 -Hanother=bar http://clariveurl/rule/json/myrule`

#### req.params()

Devuelve los parámetros de la consulta de solicitud.

```javascript
var ws = require("cla/ws");
var req = ws.request();
var fooParam = req.params('foo');  // in case this was called http://.../?foo=bar
```

#### req.type()


Devuelve el formato esperado de la petición por el solicitante.


Por lo general, este formato debe ser transparente para el desarrollador,
pero puede ser útil para devolver respuestas específicamente construidas.

#### req.url()

La URL completa de la petición.

```javascript
var ws = require("cla/ws");
var req = ws.request();
print( req.url() );   // something like: http://clariveurl/rule/json/myrule
```

### ws.response()

Manipula los valores y opciones de la respuesta del servicio web.

```javascript
var ws = require("cla/ws");
var res = ws.response();
```

#### res.data(clave, valor)

Establece un par clave-valor en un hash (objeto) de los datos de respuesta.

Esto es útil para devolver los valores en formatos JSON para los clientes 
de *webservices*.

```javascript
var ws = require("cla/ws");
var res = ws.response();
res.data("foo", 1234);
res.data("bar", { xx: 10, yy: [1,2,100] });
```

#### res.body(valor)

El cuerpo de la respuesta le permite definir 
el texto que compone el contenido del cuerpo.

```javascript
var ws = require("cla/ws");
var res = ws.response();
res.body("<html><body><h1>Título</h1></body></html>");
```

**Importante**: recuerde que el cliente espera
un formato de salida diferente dependiendo de la solicitud
URL: JSON, YAML, *raw* y soap. Así que asegúrese de que la respuesta
sigue a lo que el cliente está esperando a la hora de establecer directamente el  `res.body ()`.

El establecimiento de un cuerpo de la respuesta, se borrarán todos los pares de claves y valores anteriores
que se establecieron antes.

La configuración del cuerpo de respuesta eliminará cualquier par clave-valor que se ha establecido anteriormente.

#### res.status(código)

Permite que el desarrollador establezca el código de estado de la respuesta.

