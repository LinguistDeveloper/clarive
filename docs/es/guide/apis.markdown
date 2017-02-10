---
title: Usando las APIs de Clarive
index: 4000
---

La API de Clarive no ofrece *endpoints* de URL fuera de caja. Se tienen que
definir previamente. Esto significa, crear reglas de servicios web
(*webservice*) y después orientarla al *endpoint* de su aplicación externa.

Las reglas webservices pueden utilizar *endpoints* tanto REST como SOAP, lo
cual mejora la conectividad y centraliza la ejecución de la lógica
implementada.

Los elementos básicos de la API de Clarive están disponibles dentro de la
regla, utilizando operaciones de la paleta o con código JavaScript
directamente.


Por lo tanto, la forma recomendad de Clarive de implementar las llamadas a
nuestra API es:

1) Escribir una regla de tipo webservice que exponga la URL final.  2) llamar a
dicha URL externamente, estableciendo el formato de devolución de los datos en
la propia URL.


#### ¿Por qué no ofrecemos un simple API REST?

Proponer una API REST significa que el usuario puede automatizar secuencias
lógicas desde herramientas externas, lenguajes de programación o scripts.

Desde Clarive creemos firmemente que crear scripts fuera de la herramienta
puede traer problemas, especialmente cuando Clarive es una herramienta de
automatización con características como el monitorizado avanzado, gestión de
logs, control de concurrencia y manejo de eventos incorporados. Además,
incluimos modos de testing y *dry-run* que pueden ayudar al usuario a la
depuración de su entrega automática.

Por ejemplo, el usuario puede crear un script que crea un tópico, se rellena
con alguna información y posteriormente se despliegue a otro estado.

Pero, en su lugar, lo mismo se puede hacer en una regla webservice, se puede
escribir una regla que haga esto mismo, y después, se llama a ese *endpoint*
con algo como cURL (el comando `curl` puede ser utilizado para llamar a URLs
REST).


#### Construyendo Plugins

Si eres un proveedor independiente o un programador que quiere integrar su
herramienta con Clarive escribiendo un plugin, es necesario que parte de su
plugin sea ejecutado bajo Clarive, esta parte, se tiene que instalar en el
directorio `CLARIVE_BASE/plugins`.

### La API Clarive

Aquí hay una lista con las características primarias de la API de Clarive
expuestas a través de las operaciones de regla:

- crear, actualizar, eliminar, listas de tópicos.
- crear, actualizar, eliminar, listas de CIs.
- gestión de despliegues y pases.
- notificaciones.
- gestión de eventos.
- semáforos.
- aprovisionamiento.
- análisis de impacto.
- operaciones de MongoDB.
- etc.

En la [guía de desarrollo](devel/intro) se describe mas detalladamente lo que
la API de Clarive ofrece a los desarrolladores.


#### Formatos de devolución de datos

Los datos que devuelven las reglas webservice pueden ser en los formatos:

- JSON
- YAML
- XML
- Raw - solo texto plano o datos binarios devueltos por la regla.

Tan solo hay que añadir el formato deseado en la URL, de la siguiente manera:

    http(s)://servidor-clarive/rule/[json|yaml|xml|raw]/[regla-id]

### Autentificación

Los *endpoints* de los webservices pueden ser públicos o requerir
autentificación.

Los *endpoints* públicos son accesibles para todo el mundo. Nunca implementar
en un servicio web público operaciones sensibles. Los servicios web pueden ser
útiles para informes de datos que son públicos como por ejemplo JSON.

El método de autentificación es a través de la **clave API**. Las claves API
son gestionadas por el usuario.

Desde Clarive recomendamos crear usuarios específicos con los permisos
necesarios para utilizar servicios web.
