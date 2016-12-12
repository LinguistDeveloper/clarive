---
title: cla queue - Herramientas para la gestión de colas
index: 5000
icon: console
---

`cla queue`: Las herramientas de gestión de colas actúa a través de la implementación pub/sub de redis por lo que es necesario que un servidor redis y, al menos, un worker estén funcionando.

Sin ningún parámetro, se muestra todos los workers registrados. Se puede añadir la opción `-v` para ver además la configuración del worker.

Los subcomandos disponibles se pueden consultar a través de la opción de ayuda:

        > cla help queue

        uso: cla [-h] [-v] [--fichero de configuración] comando <comando-args>

        Subcomandos disponibles para queue:
        queue-pin
        queue-worker
        queue-de
        queue-key
        queue-flush

        cla help <comando> para obtener todos los subcomandos.
        cla <comando> -h para los opciones del comando.


`cla queue-ping`: Necesita el parámetro `–wid <worker_id>` donde worker_id es el ID al que se quiere realizar el ping.

Si la conexión está establecida, la salida será el estado de worker y su configuración.

`cla queue-workers`: Muestra el estado de los workers.

`cla queue-keys`: Muestra todas las claves que coincidan con una máscara establecida. Ésta se puede configurar:

- Como argumento en el comando `--mask <nombre_mascara>`. Muestra todas las claves con el nombre de la máscara.
- Si no se encuentra ningún argumento, la máscara coge el valor '*' y mostrará todas las claves.

`cla queue-del`: Elimina todas las claves que coinciden con la máscara. Está máscara puede configurarse de la misma manera que en el comando anterior.

- Como argumento en el comando `--mask <nombre_mascara>`. Elimina todas las claves con el nombre de la máscara.
- Si no se encuentra ningún argumento, la máscara coge el valor '*' y eliminará todas las claves.

`cla queue-flush`: Intenta hacer ping a cada worker registrado. Si se tiene éxito, se muestra un mensaje que dice todos los workers están en linea. Si alguno de los workers no responde se elimina al trabajador de la cola y se muestra un mensaje informando del suceso.
