---
title: cla start - Inicia todos los procesos del servidor
icon: console
---
* `cla start`: Comienza todas las tareas de servidor. 
* Intenta iniciar todos los sistemas que Clarive necesita para operar.
* Estos son: <br />

&nbsp; &nbsp;• *mongo*: Inicia el servidor de Mongo con la configuración alojada en el fichero: `$CLARIVE_BASE/config/mongod.conf`.

&nbsp; &nbsp;• *nginx*: Inicia el servidor nginx.

&nbsp; &nbsp;• *Clarive web server*: Inicia el servidor web en modo demonio.

&nbsp; &nbsp;• *Clarive dispatcher*: El servicio del Dispatcher se inicia en modo demonio.

<br/> 
* Este comando permite las dos siguientes opciones: <br/> 

&nbsp; &nbsp;•  `--no_mongo`: Indica a Clarive que no inicie el servidor de Mongo. <br/> 

&nbsp; &nbsp;•  `--mongo_arbiter`: Para iniciar el servidor de réplica de Mongo. Recoge la configuración de `$CLARIVE_BASE/conf/mongo-arb.conf`. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Por defecto, Clarive no incluye este fichero de configuración. Se requiere consultar la documentación de Mongo para crear este fichero. <br />

&nbsp; &nbsp;•  `--redis`: Inicia tambien el servidor de Redis. <br/> 

&nbsp; &nbsp;•  `--no_nginx`: Evita iniciar el servidor nginx.

