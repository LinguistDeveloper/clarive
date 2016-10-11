---
title: cla config - Herramienta de configuracion
icon: console
---
* `cla config`:  Herramienta para generar un fichero de configuración o para mostrar la configuración actual de Clarive.
* Ejecutando el comando sin parámetros, pregunta al usuario si desea generar un nuevo fichero de configuración a través de una plantilla.
* Esta plantilla puede estar definida:
    De manera explicita, indicado como argumento el fichero de la plantilla deseada: `--template <fichero_plantilla>`.
    Si no se especifica, la plantilla generada se almacena en la ruta: `$CLARIVE_HOME/config/clarive.yml.template`.

 * Tras su ejecución, la herramienta pregunta acerca de la configuración de los parámetros. Los parámetros que se necesitan para el correcto uso del fichero de configuración son:
    `host`: Nombre de la instancia que identifica al servidor.
    `web host`: Host para publicar las urls en e-mails.
    `web port`: Puerto necesario para publicar las urls en los e-mail y en la interfaz.
    `site_key`: Una clave aleatoria usada para encriptar las contraseñas.
    `default theme`. 
     `time_zone_offset`: Establece la zona horaria.

* Tras esto, el fichero de configuración con los parámetros dados se crea y se almacena en el directorio: `$CLARIVE_HOME/config`. Su nomeclatura es:
    `<$env>.yml`: Si una opción se ha pasado como argumento de la forma: `--env <nombre_entorno>`.
    `<$CLARIVE_ENV>.yml.`: Si no se ha pasado ningún argumento.

* El comando tiene que subcomandos diferentes que pueden ser consultados a través de la ayuda:
            
        > cla help config

        Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.

        uso: cla [-h] [-v] [--config fichero] command <command-args>

        Subcomandos disponibles para la configuración (Muestra todas las opciones de configuración asi como las heredadas:
        config-show
        config-opts
        config-gen

        cla help <comando> para obtener todos los subcomandos.
        cla <comando> -h para ver las opciones del comando.
* `cla config-show`: Este comando muestra todos los parámetros de configuración definidos en los siguientes ficheros:

        `clarive.yml`.

        `global.yml`.
* Con la opción `--key <parameter>`, la salida solo muestra los parámetros definidos en el campo `<parameter>`.
* `cla config-opts`: Este comando muestra:

        Todos los parámetros de configuración de los ficheros de configuración de Clarive mencionados arriba.

        Algunas de los parámetros clave del entorno.

        Argumentos pasados a través de la linea de comandos.
* `cla config-gen`: Tiene el mismo comportamiento que el comando `cla config`.

