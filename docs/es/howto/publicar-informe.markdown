---
title: Hacer publico un informe
index: 1
icon: wrench.gif
---

Cada vez que se realiza una exportación de cualquier tipo, ya sea un grid de tópicos o un informe, se genera un evento llamado *event.topic_list.export* que contiene los datos de dicha exportación; formato, parámetros, título, autor y fichero temporal generado.

Este fichero temporal se **elimina** cuando se termina el evento. Sin embargo, si se desea almacenar el informe en una URL fija y accesible, es necesario hacerlo mediante una regla de tipo evento.


## Configuracion de la regla  

Crearemos una regla de tipo evento donde el evento seleccionado será *event.topic_list.export*.

Una regla básica para el funcionamiento de la exportación es incluir el elemento *[service.artifacts.publish](Reglas/Paleta/Servicios/publish_files_according_catalog)* que permite publicar el informe en el repostorio de artefactos.

A continuación configuramos el servicio:

* **Repositorio**: Establecemos el repositorio como *public* para que se genere una URL accesible desde cualquier lugar.

* **Ruta**:  Seleccionamos el nombre del fichero y la extensión que se va a generar. La extensión viene dada por el parámetro *export_format* generado en el evento. Para el nombre del fichero se puede utilizar un nombre fijo o variable:  

    + *Nombre fijo*: El fichero se irá reemplazando a cada exportación (siempre que sea en el mismo formato): *fichero_exportado.${export_format}*.

    + *Nombre variable*: El nombre del fichero depende de una variable anteriormente dada, ya sea en un paso previo o cogida del stash: *${variable}.${export_format}*.

* **Origen**: Establece el origen del fichero. Este origen debe hacer referencia al fichero temporal que se ha generado con el evento *${export_temp_file}*.


Una vez configurados los parámetros y guardada la regla, relizamos una exportación de un informe o de un grid de tópicos a uno de los formatos disponibles en Clarive (HTML, CSV o YAML).

Para comprobar que la regla ha funcionado de manera correcta, accedemos a Herrramientas -> Artefactos y observamos que en el repositorio *Public* se ha guardado el informe con el nombre y la extensión configurados en la regla. En caso de querer compartir dichos informes, basta con copiar la ruta del informe deseado.
