---
title: Ficheros de configuración de Clarive
index: 500
icon: page
---

El fichero de configuración de Clarive es un archivo [YAML](concepts/yaml) personalizado por el usuario que contiene los parámetros específicos de la instalación

## Entornos y --env

El archivo de configuración también se llama **archivo de entorno de configuración** de
Clarive, y designado como `[env].yml` en este manual.

Cada vez que se inicia Clarive desde la linea de comandos, o se instala como servicio de Windows, se define la configuración del entorno

Cada vez que se inicia un proceso Clarive desde la línea de comandos, o al instalar
un servicio de Windows, se define el entorno de configuración tal y como está en el archivo de configuración.

Por ejemplo, para iniciar el servidor web de Clarive:

	cla web-start --env [env].yml


## Configuración de las variables

Los parámetros de configuración (o claves) deben de estar definidas en el fichero de configuración.

También es posible definir los parámetros desde la linea de comandos utilizando el formato `--<parámetro> valor`.

Para ver ejemplos sobre cómo crear o establecer ciertos valores,
por favor refiérase a la configuración del producto Clarive
archivo, ubicado en `CLARIVE_HOME/config/config.yml`.
*No cambiar este archivo, ya que se puede sobrescribir
por las actualizaciones o parches futuros*


### tmp_dir

Ubicación del directorio de archivos temporales.

Por defecto está ubicado en `CLARIVE_HOME/tmp`.

### log_dir

Ubicación del directorio de los logs de Clarive,
así como los logs del servidor web y del *dispatcher*.


Por defecto está ubicado en `CLARIVE_HOME/log`.

### job_dir

Ubicación del directorio de los *jobs*.

### pid_dir

Ubicación del directorio para PID y el proceso de
ficheros pid y de bloqueo (`.pid` y `.lock`).

### Depurador (debug)

Establece este valor en 1 o mayor para empezar Clarive en modo de depuración. Cuanto mayor sea el valor, mayor es el número de mensajes de depuración y nivel de detalle.

### mongo

`mongo:` La sección de configuración se describe [por separado en el documento de instalación MongoDB](setup/mongo).