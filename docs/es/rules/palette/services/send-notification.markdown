---
title: Send notification
icon: job
---
Servicio para enviar notificaciones. El formulario para configurar tiene los siguientes campos:

* **Para**: Seleccionamos los usuarios a los que les vamos a enviar la notificación. 
Permite rellenar el campo con usuarios, roles o emails ajenos a los usuarios de Clarive.

* **CC**: Seleccionamos los usuarios a los que les vamos a enviar la notificación en copia. 
Permite rellenar el campo con usuarios, roles o emails ajenos a los usuarios de Clarive.

* **Asunto**: Asunto del mensaje. Permite el uso de variables *${variable}*

* **Cuerpo**: Cuerpo del mensaje. Permite el uso de variables *${variable}*

* **Ruta del adjunto**: Adjunta un fichero o un directorio. Hay que añadir la ruta del fichero o directorio que se va a adjuntar.
Si es un directorio, los ficheros incluidos en el mismo serán comprimidos y enviados en un archivo con extensión *.zip*.
El tamaño máximo permitido será el valor indicado en la variable de configuración *max_attach_size* en `Configuración`.
Es posible utilizar variables para definir el fichero adjunto.

Ejemplos de rutas utilizando variables:

	${ruta_variable}/tmp/clarive/docs.zip

	/tmp/${Clarive_home}/doc${version}.doc

	${Clarive_home}/output/file.${extension_fichero}


*Nota*: Si el fichero excede el máximo permitido, la notificación se enviará sin ficheros adjuntos.

* **Nombre del fichero**: Renombra el fichero adjunto. Si este campo se deja vacío, el nombre del fichero adjunto será el nombre por defecto.