---
title: Actualizando desde versiones anteriores
index: 700
icon: page
---

Después de descargar el software, se recomienda descomprimir
en un directorio diferente del directorio actual.
También puede utilizar el mismo directorio y sobrescribir los archivos.

## Manteniendo el mismo directorio para Clarive

Si decide mantener el mismo directorio que la versión anterior de Clarive, es necesario hacer
una copia de seguridad de carpetas `$CLARIVE_BASE/local` y` $CLARIVE_BASE/clarive` y reemplazarlos con los nuevos.


## Nuevo directorio para Clarive

Cuando se utiliza un directorio diferente, es necesario actualizar la variable de entorno
$CLARIVE_BASE con el directorio donde desea descomprimir la nueva versión.

    export CLARIVE_BASE=/opt/clarive

También hay que mover las carpetas de los logs, las extensiones y las configuraciones, etc..

    mv $CLARIVE_BASE_OLD $CLARIVE_BASE
    rm -rf $CLARIVE_BASE/local
    rm -rf $CLARIVE_BASE/clarive

Una vez que estos pasos se han realizado, la nueva versión
del directorio se descomprime en el nuevo directorio `$ CLARIVE_BASE`


## Las migraciones de datos

Las migraciones de datos pueden ser requeridos cuando se inicia el servidor (*dispatcher*
o un servidor web).

Cuando se necesitan las migraciones, se mostrará el siguiente mensaje:

    pid_file: /opt/clarive/logs/cla-web-host-3000.pid
    (I)2015-03-04 21:19:38.057[74032] [B::Mongo:81] Mongo: new connection to db `acmebank`
    (D)2015-03-04 21:19:38.062[74032] [cache:43] CACHE Setup ok: expire_seconds 90000 driver Mongo
    ERROR: Migrations are not up to date. Run with --migrate flag or use migra- commands

Para remediar esta situación, inicie el servidor o dispatcher con la opción `--migrate` añadido:

    cla web-start --env [myenv] --migrate

Esto inicializará la migración, después de lo cual se iniciará el servidor/dispatcher
de manera automática.

