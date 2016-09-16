---
title: cla poll - Monitorización
index: 5000
icon: console
---

`cla poll`: Herramienta de monitorización. Ejecutando `cla poll` sin ningún argumento se comprueba:

- Los procesos que se están ejecutando.
- La conexión al servicio web de Clarive.
- La conexión a *nginx*.
- La conexión a Mongo.

Las opciones del comando son las siguientes:

`-h` - Muestra la ayuda del comando específico.

    > cla poll -h

    NOMBRE
     poll - Comrpueba si los procesos se han iniciado

    Clarive Poll Monitoring
      Uso: cla poll

      Opciones:

          -h              esta ayuda
         --url_web        URL de Clarive web
         --url_nginx      URL de nginx web
         --api_key        api key para acceder a clarive
         --web            1=intenta conexión a clarive web, 0=omite
         --act_nginx      1=intenta conexión a nginx, 0=omite nginx
         --act_mongo      1=intenta conexión a mongo, 0=omite mongo
         --act_redis      1=intenta conexión a redis, 0=omite estado redis
         --timeout_web    segundos a esperar para la respuesta de clarive/nginx web, 0=sin timeout
         --error_rc       devuelve código para errores fatales
         --pid_filter     expresión regular para filtrar en los ficheros pid.

`--error_rc`: Define un nivel personalizado para los errores importantes. Tiene que ser un número y su valor predeterminado es 10.

`--web`: Si está indicado, se comprueba la conexión al servidor web Clarive, por defecto su valor se establece en 1. Si se indica con 0, no se hará la comprobación

`--url_web`: Host y puerto donde el servidor está corriendo. Si no tiene valor definido, la opción puede ser definida a través de:

- `--host <host servidor Web>` - Host se establecerá con el valor ‘localhost’.
- `-- port <puerto de escucha de Clarive>` - El valor del puerto se establece a ‘3000’.

`--api_key`: Muestra la clave API para acceder a Clarive.

`--timeout_web`:  Tiempo de espera para obtener respuesta de la web. Por defecto son 5 segundos. Si el parámetro se configura a 0, no habrá tiempo límite.

`--act_nginx`: Si está 0 la herramienta no comprobará la correcta conexión a nginx. Por defecto este valor es 1.

`--url_nginx`: Indica la URL de nginx.

`--act_mongo`: Comprueba la conexión a la base de datos Mongo. Para evitar está comprobaci´n hay que poner este argumento a 0. Por defecto el valor está a 1.

`--act_redis`: Comprueba la conexión al servidor Redis definido en el fichero de configuración o en el localhost y puerto 6379 si no está definido. Por defecto, está a 0. Si se quiere comprobar se tiene que pasar un 1 como argumento.


