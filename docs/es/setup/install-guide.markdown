---
title: Guía rápida de instalación
index: 100
icon: page
---

El objetivo de este articulo es proporcionar al administrador una guía de instalación o actualización de Clarive Software a la versión 6.4 utilizando los pasos descritos a continuación.


# Prerequisitos

Los prerrequisitos para la instalación de Clarive están especificados en las [Especificaciones técnicas](setup/specs).

# Descarga del software

<!--  Waiting for a solution to how customers can download Clarive software

Los ficheros de instalación de Clarive están disponibles en:

[http://www.clarive.com/install <img class='ext-link' src='static/images/icons/window-new.svg' />](http://www.clarive.com/install)

En caso de que no encuentre una versión compatible con su sistema operativo, póngase en contacto con nosotros a través de: `support@clarive.com`.

Sigue los pasos especificados en la página web de la instalación.

Este articulo describe dicha información para los usuarios que lo necesiten. -->

### MongoDB

Clarive se ejecuta sobre una base de datos, en este caso MongoDB.

MongoDB puede ser descargado desde la siguiente página web:

[https://www.mongodb.org/downloads <img class='ext-link' src='static/images/icons/window-new.svg' />](https://www.mongodb.org/downloads)

Seleccione la versión estable 3.0.

# Nueva Instalación

## Variables de entorno


El directorio en el que desea descomprimir el software de
Clarive se define en la variable de entorno.

Se deben definir cuatro variables de entorno más:

```bash
export CLARIVE_BASE=/opt/clarive

export CLARIVE_HOME=$CLARIVE_BASE/clarive
export LD_LIBRARY_PATH=$CLARIVE_BASE/local/lib
export CLARIVE_ENV=your_environment
export PATH="$CLARIVE_HOME/bin:$CLARIVE_BASE/local/bin:$CLARIVE_BASE/local/sbin:$PATH"
```
Las variables marcadas tienen que modificarse en base al entorno de la instalación

El software descomprime los ficheros en `$CLARIVE_BASE`.

Dentro de la variable de entorno `$PATH`, es necesario incluir la ruta donde está alojado MongoDB:

```bash
export MONGO_DB=/opt/mongo
export PATH="$MONGO_DB/bin:$PATH"
```

## Nuevos directorios

Es necesario crear los siguientes directorios si no han sido creados en los pasos previos:

```bash
$CLARIVE_BASE/config
$CLARIVE_BASE/jobs
$CLARIVE_BASE/logs
$CLARIVE_BASE/tmp/nginx/client
```

## Licencia

Por defecto, la configuración se almacena en el fichero *clarive.yml* alojado en el directorio `$CLARIVE_HOME/config`. Adicionalmente, en este fichero, se incluye la licencia.

Se necesita crear un fichero de configuración para el entorno en `$CLARIVE_BASE/config` llamado `$CLARIVE_ENV.yml`. Hay que incluir la licencia en este fichero.

Use la licencia de la compañía si ya ha sido adquirida.

## Configuración

El archivo de configuración que se ha creado para su entorno
requiere de un mínimo de datos que permita el correcto funcionamiento de la herramienta.

Por defecto, los valores que se encuentran en el archivo son los que se cogen:

    $CLARIVE_HOME/config/clarive.yml.


Los valores del archivo de configuración del entorno que son necesarios serán sobrescritos.

### Configuración NGINX

Nginx está incluido dentro de Clarive. Sin embargo, es necesario
para crear un archivo de configuración

    $CLARIVE_BASE/config/nginx.conf

A continuación, un ejemplo de configuración nginx:

```nginx
pid  ../logs/nginx.pid;
events {
    worker_connections  1024;
}

http {
    server {
        listen       80;
        server_name  localhost;

        access_log  ../logs/nginx.access.log  combined;
        error_log   ../logs/nginx.error.log;

        location / {
            proxy_pass http://localhost:3000;

            proxy_redirect     off;
            proxy_set_header   Host             $host;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host  $host;
        }
    }
}
```

### Configuración MongoBD

En el archivo de configuración, es necesario especificar la base de datos Mongo.
Para ello, en el archivo de configuración del entorno se tiene que especificar:

```yaml
mongo:
    dbname: your_database_name
```

Además de especificar la base de datos que utilizará Clarive, se necesita un archivo de configuración de MongoDB.
Una posible ruta podría ser:


    $CLARIVE_BASE/config/mongod.conf

Un ejemplo de una configuración básica de MongoDB podría ser:

```properties
fork=true
dbpath=/opt/mongo/data/
logpath=/opt/clarive/logs/mongod.log
pidfilepath=/opt/clarive/logs/mongod.pid
logappend=true
journal=true
port=27017
bind_ip=127.0.0.1
setParameter=failIndexKeyTooLong=false
```

## Arranque y acceso

### Arrancar Nginx

Para arrancar nginx como root:

```bash
cla exec nginx -c $CLARIVE_BASE/config/nginx.conf
```

### Arrancar MongoDB

Para arrancar MongoDB:

```bash
mongod -f $CLARIVE_BASE/config/mongod.conf
```

### Arrancar Clarive

Clarive hace diferencia entre la parte web y el dispatcher.
Ambos tienen que ser arrancados de manera separada:

```bash
cla web-start --env your_environment --daemon
cla disp-start --env your_environment --daemon

cla web-stop --env your_environment
cla disp-stop --env your_environment
```

### Parar Clarive

Al igual que en la fase de arranque, para parar Clarive es necesario
parar los dos procesos; la parte web y el dispatcher:

```bash
cla web-stop --env your_environment
cla disp-stop --env your_environment

cla web-stop --env your_environment
cla disp-stop --env your_environment
```

### Acceso a Clarive via Web

La URL de acceso a la instancia de Clarive es:

    http://localhost:3000
    user: local/root
    password: admin

