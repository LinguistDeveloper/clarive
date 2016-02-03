---
title: cla poll - Monitorizacion
icon: console
---
* `cla poll`: Herramienta de monitorización.  Monitoring tool. Without any option checks.
* Ejecutando `cla poll` sin ningun argumento se comprueba:

&nbsp; &nbsp;• Los procesos que se están ejecutando. <br />

&nbsp; &nbsp;• La conexión al servicio web de Clarive. <br />

&nbsp; &nbsp;• La conexión a *nginx*. <br />

&nbsp; &nbsp;• La conexión a Mongo.

* Las opciones del comando son las siguientes:

&nbsp; &nbsp;• `-h` - Muestra la ayuda del comando específico.

    >cla poll -h

    NAME
     poll - check if processes are started

    Clarive Poll Monitoring
      Usage: cla poll

      Options:

          -h               this help
         --url_web        clarive web url
         --url_nginx      nginx web url
         --api_key        api key to login to clarive
         --web            1=try clarive web connection, 0=skip
         --act_nginx     	    1=try nginx connection, 0=skip nginx
         --act_mongo            1=try mongo connection, 0=skip mongo
         --act_redis            1=try redis connection, 0=skip redis status
         --timeout_web    seconds to wait for clarive/nginx web response, 0=no timeout
         --error_rc       return code for fatal errors
         --pid_filter     regular expression to filter in pid files    


* `--error_rc`: Define un nivel personalizado para los errores importantes. Tiene que ser un número y su valor predeterminado es 10.
* `--web`: Si está indicado, se comprueba la conexión al servidor web Clarive, por defecto su valor se establece en 1. Si se indica con 0, no se hará la comprobación
* `--url_web`: Host y puertodonde el servidor está corriendo. Si no tiene valor definido, la opción puede ser definida a través de:

&nbsp; &nbsp;• `--host <host Web Server>` - Host se establecerá con el valor ‘localhost’. <br />

&nbsp; &nbsp;• `-- port <port where Clarive is listening>` - El valor del puerto se establece a ‘3000’. <br/>
    
* `--api_key`: Muestra la clave API para acceder a Clarive.
* `--timeout_web`:  Tiempo de espera para obtener respuesta de la web. Por defecto son 5 segundos. Si el parámetro se configura a 0, no habrá tiempo límite.
* `--act_nginx`: Si está 0 la herramienta no comprobará la correcta conexión a nginx. Por defecto este valor es 1.
* `--url_nginx`: Indica la URL de nginx.
* `--act_mongo`: Comprueba la conexión a la base de datos Mongo. Para evitar está comprobaci´n hay que poner este argumento a 0. Por defecto el valor está a 1.
* `--act_redis`: Comprueba la conexión al servidor Redis definido en el fichero de configuración o en el localhost y puerto 6379 si no está defindo. Por defecto, está a 0. Si se quiere comprobar se tiene que pasar un 1 como argumento.


