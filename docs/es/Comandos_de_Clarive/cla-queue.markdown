---
title: cla queue - Herramientas de gestion de colas
icon: console.svg
---
* `cla queue`: Las herramientas de gestión de colas actúa a través de la implementación pub/sub de redis por lo que es necesario que un servidor redis y, al menos, un worker estén funcionando.
* `cla-queue`: Sin ningún parámetro, se muestra todos los workers registrados. Se puede añadir la opción `-v` para ver además la configuración del worker.
* Los subcomandos disponibles se pueden consultar a través de la opción de ayuda:
            
        > cla help queue
        Clarive - Copyright(C) 2010-2015 Clarive Software, Inc.

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for queue (queue management tools):
        queue-pin
        queue-worker
        queue-de
        queue-key
        queue-flush

        cla help <command> to get all subcommands
        cla <command> -h for command options.
    

<br />
* `cla queue-ping`: Necesita el parámetro `–wid <worker_id>` donde worker_id es el ID al que se quiere realizar el ping.

<br/>
* Si la conexión está establecida, la salida será el estado de worker y su configuración.

<br/>
* `cla queue-workers`: Muestra el estado de los workers.

<br/>* `cla queue-keys`: Muestra todas las claves que coincidan con una máscara establecida. Ésta se puede configurar: <br />

&nbsp; &nbsp; • Como argumento en el comando `--mask <nombre_mascara>`. Muestra todas las claves con el nombre de la máscara. <br />

&nbsp; &nbsp; • Si no se encuentra ningún argumento, la máscara coge el valor '*' y mostrará todas las claves. <br />

<br/>
* `cla queue-del`: Elimina todas las claves que coinciden con la máscara. Está máscara puede configurarse de la misma manera que en el comando anterior.
<br/>
* `cla queue-flush`: Intenta hacer ping a cada worker registrado. Si se tiene éxito, se muestra un mensaje que dice todos los workers están en linea. Si alguno de los workers no responde se elimina el trabajor de la cola y se muestra un mensaje informando del suceso.