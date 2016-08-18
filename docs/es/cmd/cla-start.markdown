---
title: cla start - Inicia todos los procesos del servidor
icon: console.svg
---
* `cla start`: Comienza todas las tareas de servidor.
* Intenta iniciar todos los sistemas que Clarive necesita para operar.
* Estos son:
    *mongo*: Inicia el servidor de Mongo con la configuración alojada en el fichero: `$CLARIVE_BASE/config/mongod.conf`.
    *nginx*: Inicia el servidor nginx.
    *Clarive web server*: Inicia el servidor web en modo demonio.
    *Clarive dispatcher*: El servicio del Dispatcher se inicia en modo demonio.

* Este comando permite las dos siguientes opciones:
     `--no_mongo`: Indica a Clarive que no inicie el servidor de Mongo.
     `--mongo_arbiter`: Para iniciar el servidor de réplica de Mongo. Recoge la configuración de `$CLARIVE_BASE/conf/mongo-arb.conf`.
Por defecto, Clarive no incluye este fichero de configuración. Se requiere consultar la documentación de Mongo para crear este fichero.
     `--redis`: Inicia tambien el servidor de Redis.
     `--no_nginx`: Evita iniciar el servidor nginx.

