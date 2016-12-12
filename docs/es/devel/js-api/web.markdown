---
title: cla/web - Herramientas Web
index: 5000
icon: page
---

Este *namespace* contiene funciones útiles
para el protocolo web y las comunicaciones, tales la
invocación a APIs REST y SOAP servicios web en general.


<pre>
 CLAVE                     VALOR POR DEFECTO
---------------------------------------------------------
agent                    "clarive/js"
from                     undef
conn_cache               undef
cookie_jar               undef
default_headers          HTTP::Headers->new
local_address            undef
ssl_opts                 { verify_hostname:   1 }
max_size                 undef
max_redirect             7
parse_head               1
protocols_allowed        undef
protocols_forbidden      undef
requests_redirectable    ['GET', 'HEAD']
timeout                  180
---------------------------------------------------------
</pre>

### web.agent(opciones)

Crea un nuevo objeto de agente web.
El objeto de agente web es análogo a un navegador web o al comando `curl`, de manera que puede ser utilizado para elaborar
peticiones web.

En este ejemplo, invocamos al servicio web REST `GET` que devuelve el contenido en un JSON.

```javascript
var web = require("cla/web");
var util = require("cla/util");
var ag = web.agent();
var res = ag.get('http://jsonplaceholder.typicode.com/posts');
if( res.isSuccess() ) {
    var content = res.content();   // este el contenido del fichero, en formato JSON.
    var arr = util.loadJSON( res.content() );
    cla.dump( arr[4] );
    cla.printf( "El título es: %s", arr[4].title );
} else {
    cla.printf("Algo fue mal (code=%d): %s", res.code(), res.message() )
    // or: throw Error( cla.sprintf("Algo fue mal (code=%d): %s", res.code(), res.message() ) );
}
```

Estos son los métodos del agente REST, que tienen un manejo muy similar:

- `GET` - agent.get(url,opciones)
- `POST` - agent.post(url,opciones)
- `PUT` - agent.put(url,opciones)
- `DELETE` - agent.delete(url,opciones)
- `HEAD` - agent.head(url,opciones)

Argumentos comunes a los métodos REST:

- `agent.METHOD(url)` - invocar la URL dada con el método especificado
- `agent.METHOD(url,{ key: value, ... })` - donde la forma es un conjunto clave-valor de datos del formulario
- `agent.METHOD(url,{ key: value, ... }, 'Field', Value, ...)` - donde se pueden añadir otros campos, tales como `Content-type`, etc.
- `agent.METHOD(url,[ 'Header', val, 'Content', { ..form content..} ])` - esto es para las formas más elaboradas,
con diferentes formatos de cabecera y de contenido.


```javascript
var web = require("cla/web");
var ag = web.agent();
var url = 'http://jsonplaceholder.typicode.com/posts';
ag.post( url, { foo: 11, bar: 22 });
```

Todos los métodos devuelven un objeto `response`, el cual se describe a continuación:

#### response.content([bytes])

Devuelve el contenido del cuerpo de la respuesta del servidor.

El argumento opcional `bytes`permite controlar el número de bytes devueltos en la función.

#### response.code()

El código del estado de la respuesta.

#### response.message()

El mensaje de respuesta para el código dado, por ejemplo, un mensaje de error.

#### response.isSuccess()

Devuelve `true` si el la petición se ha realizado correctamente.

#### agent.request(request,fichero)

Se trata de una petición genérica.

#### agent.mirror(url,fichero)

Réplica (descargas) la URL al fichero, pero solo si es necesario (por ejemplo, si se ha cambiado y los ficheros son diferentes).

```javascript
var web = require("cla/web");
var ag = web.agent();
ag.mirror('http://jsonplaceholder.typicode.com/posts', '/tmp/posts.json');
```

#### agent.isOnline(opciones)

Comprueba si el agente está online y puede realizar peticiones, por ejemplo, si el servidor de Clarive tiene conectividad a red.

```javascript
var web = require("cla/web");
var ag = web.agent();
if( ag.isOnline() ) {
    // ... llama a varios webservices ...
}
```

