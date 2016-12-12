---
title: cla disp - Gestión del Dispatcher
index: 5000
icon: console
---

`cla disp`: Realiza operaciones relacionadas con el [dispatcher](admin/dispatcher).

Ejecutándolo sin ningún argumento, se inicia el servicio del dispatcher, encargado de iniciar todos los demonios.La manera en la que se inicie, esté duplicado o no, es utilizando la configuración de servicio.

El Dispatcher se comporta de la siguiente manera en función al estado de los demonios.

- Si un demonio ha sido desactivado desde la herramienta, el dispatcher para el demonio.
- Si el demonio ha sido activado, el dispatcher arranca el servicio.
- Si un demonio está activo, el dispatcher comprueba si se está ejecutando o no, si no lo está intentará reiniciar el servicio de nuevo.

La frecuencia que el dispatcher comprueba el estado de un demonio es un parámetro configurable llamado `frecuency`. Este valor, por defecto, son 30 segundos.

Este comando soporta dos opciones diferentes:

`-h`:  Muestra una breve ayuda en la pantalla:

    > cla disp –h

    Clarive Dispatcher
      Opciones comunes:

          --daemon        se realiza un fork y se inicia

    stop
      se para el servidor.

     restart
      reinicia el servidor.

     log
      imprime el fichero del log en la pantalla.

     tail
      sigue el fichero del log.

- `-daemon`: Ejecuta el servicio en segundo plano.

Este comando tiene diferentes opciones:

`disp-start`: Igual que el `cla disp`, descrito arriba.

`disp-stop`:  Para el dispatcher y sus servicios. A su vez, este comando dispone de dos opciones más.

- *no_wait_kill* - El dispatcher se elimina sin esperas. si está opción se está indicada, el dispatcher esperará 30 segundos antes de pararse.
- *keep_pidfile* - Mantiene en el fichero el PID del proceso.

`disp-log`: Imprime el log en la pantalla.

`disp-tail`: Muestra el final del fichero log, acepta los siguientes argumentos:

- *tail* - Número de lineas para mostrar. Por defecto muestra las últimas 500 líneas del log. Podemos modificar este número ejecutando el comando: cla disp-tail -tail=**numero-de-lineas**.
- *interval* - El número mínimo de segundos que va a esperar antes de que el fichero sea mostrado. Por defecto es 0,5 segundos.
- *maxinternal* - El número máximo de segundos que el sistema esperará, por defecto es 1.


