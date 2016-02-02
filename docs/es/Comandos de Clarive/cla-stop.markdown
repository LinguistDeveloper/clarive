---
title: cla stop - Detiene todos los procesos
icon: console
---

* `cla stop`: Detiene todos los procesos del servidor. Esto es, intentará detener todos los sistemas que Clarive necesita para operar.

* Estos son: <br />

&nbsp; &nbsp;• *mongo*: Detiene el servidor de Mongo.  <br />

&nbsp; &nbsp;• *nginx*: Detiene el servidor nginx.  <br />

&nbsp; &nbsp;• *Clarive web server*: Detiene el servidor web. <br />

&nbsp; &nbsp;• *Clarive dispatcher*: Detiene el dispatcher. <br />


<br/>

* El comando admite los siguientes parámetros: <br />


&nbsp; &nbsp;• `--no_mongo`: Detiene todos los procesos salvo los relacionados con el servidor de Mongo. <br />

&nbsp; &nbsp;• `--redis`: Detiene todos los procesos salvo los relacionados con el servidor de Redis. <br />

&nbsp; &nbsp;• `--no_nginx`: Detiene todos los procesos salvo los relacionados con el servidor de nginx. 

