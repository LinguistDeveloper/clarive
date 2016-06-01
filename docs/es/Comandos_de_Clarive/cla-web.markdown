---
title: cla web - Administracion de servidores Web
index: 10
icon: console.svg
---
* `cla web`: Realiza operaciones relacionadas con el servicio web Clarive.
* Por sí mismo se inicia servicio web Clarive.
* Soporta las siguientes opciones: <br />

&nbsp; &nbsp;• `--env <entorno>`: Se utiliza para configurar los parámetros. <br />

&nbsp; &nbsp;• `--r`: Servidor reinicia si hay algún cambio en las rutas: <br />

&nbsp; &nbsp;&nbsp;&nbsp;• *lib*. <br />

&nbsp; &nbsp;&nbsp;&nbsp;• *conf*. <br />

&nbsp; &nbsp;&nbsp;&nbsp;• *features/\*/lib*, excepto si los cambios se detectan en ficheros de la ruta features/#* . <br />

&nbsp; &nbsp;&nbsp; &nbsp; El valor por defecto es 0. <br />

&nbsp; &nbsp;• `--R <ruta>`: El servidor se reinicia si hay algún cambio en la ruta indicada en `<ruta>`. <br />

&nbsp; &nbsp;• `--host <hostname>`: Host o dirección IP para iniciar el servidor web. Si no se define, el host se coge de los archivos de configuración. <br />

&nbsp; &nbsp;• `--port <portnum>`: Puerto Web. Su valor por defecto es 3000. <br />

&nbsp; &nbsp;• `--daemon`: Servidor Web se inicia como un demonio. <br />

&nbsp; &nbsp;• `--workers <workersnum>`: Número de trabajadores para iniciar. <br />

&nbsp; &nbsp;• `--engine [Standalone|Twiggy|Starman|Starlet]`: Servidor web PSGI. Su valor por defecto es Starman. <br />

&nbsp; &nbsp; Si el servidor web se inicia en modo demonio, el log anterior será comprimido y se comienza a limpiar los procesos *log*, los logs son borrados dependiendo del parámetro *log_keep* que se puede pasar como argumento para `cla web`.


&nbsp; &nbsp;• `--log_keep <lognumber>`: Número de logs que se pueden almacenar en la carpeta de logs. <br />

&nbsp; &nbsp;• `--log_file <logfile>`: Nombre del fichero de log. <br />

* Este comando dispone de subcomandos que pueden ser consultados a través de la ayuda:
            
        > cla help web

        Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for web (Start/Stop web server):

        web-tail
        web-start
        web-stop
        web-log
        web-restart

        cla help <command> to get all subcommands.
        cla <command> -h for command options.
    

<br />
&nbsp; &nbsp;• `web-start`: Al igual que el `start` descrito anteriormente. <br />

&nbsp; &nbsp;• `web-stop`:  Detiene el servidor web. Este comando acepta los siguientes parámetros: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *no_wait_kill* - El dispatcher se elimina sin esperas. si está opción se está indicada, el dispatcher esperará 30 segundos antes de pararse. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• *keep_pidfile* - Mantiene en el fichero el PID del proceso. <br />

&nbsp; &nbsp;• `web-restart`: Reincia el servidor web. <br />

&nbsp; &nbsp;• `web-log`: Imprime el fichero log en pantalla . <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `web-tail`: Muestra el final del fichero log, acepta los siguientes argumentos: <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *tail* - Número de lineas para mostrar. Por defecto muestra las últimas 500 líneas del log. <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *interval* - El número mínimo de segundos que va a esperar antes de que el fichero sea mostrado. Por defecto es 0,5 segundos. <br />

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *maxinternal* - El número máximo de segundos que el sistema esperará, por defecto es 1.


