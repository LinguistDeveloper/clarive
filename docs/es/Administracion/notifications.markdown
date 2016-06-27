---
title: Notificaciones
icon: email
---

* Para acceder es necesario tener permisos de administración de la herramienta.
* Para la configuración de las notificaciones se accede a través de Administración → <img class = "bali-topic-editor-image" src = "/static/images/icons/email.svg" /> Notificaciones.

* Esta ventana muestra una lista con las notificaciones existentes y un menú de acciones.
* La información se presenta de la siguiente manera:


## Columnas


#### Eventos
* Describe el evento y su acción asociada.
* En Clarive, las notificaciones se configuran a través de eventos.



#### Destinatarios
* Indica los destinatarios de la notificación.


#### Ámbitos
* Describe más propiedades de la notificación. Estas propiedades son:
    
    *Proyecto*: Indica el proyecto definido al crear la notificación. Esto permite enviar notificaciones en función al proyecto donde ocurra el evento.

    *Entorno*: Indica el entorno definido para la notificación.

    *Estado*: Indica el estado final que se quiere para la notificación.

    *Paso*: Indica el paso que se quiere para la notificación. 
    
    *Categoría*: Indica las categorías por las que el evento podrá activarse.  
    
    *Categoría / Estado*: Define los estados de las categorías para la notificación.


#### Acción
* Indica el tipo de acción de la notificación.


#### Activado
* Todas las notificaciones pueden ser activadas o desactivadas. Esta columna muestra el estado a través de dos iconos <img  src = "/static/images/icons/start.png" /> o <img src ="/static/images/icons/stop.png "/>.
* Al igual que el resto de listas que hay en Clarive, tiene las mismas funcionalidades que las demás, esto es, posibilidad de ordenar una columna pinchando en el nombre de la misma, seleccionando las columnas que se quieren mostrar o realizar una [búsqueda](Primeros_pasos/search-syntax).
* Además, se pueden filtrar los resultados en función de la acción o del estado de la notificación. Para ello, pinchar en la pestaña situada en el lateral del campo Acción o del campo Activado y, a continuación, seleccionar el filtro que se desee.



## Acciones disponibles

#### <img src = "/static/images/icons/add.svg" /> Crear
* Permite crear una nueva configuración. Para ello hay que configurar los siguientes parámetros: <br />

Ejemplo: event.topic.create

*event* - Indica el tipo de notificación (en este caso todos será de tipo **evento**).

*topic* - Indica la categoría de la notificación.

*create* - Indica la acción a realizar.

Como regla general, se describen los siguientes eventos:

*Auth*: Sistema de autentificación.

*File*: Archivo.

*Job*: Trabajo.

*Post*: Comentarios.

*Repository*: Eventos.

*Rule*: Reglas.

*Topic*: Tópicos.

*User*: Creación de comentarios.

*Ws*: Servicios web.


`Enviar / Excluir` 

Las notificaciones puede ser configuradas para ser enviadas o excluidas. 

Por defecto Clarive tiene algunas notificaciones activadas como por ejemplo enviar una notificaciones al propietario del estado del tópico o al responsable de una categoría determinada. Esta notificacion se puede evitar añadiendo una notificación de tipo Exclusión.

En el orden de las notificaciones para ser ejecutadas, primero se ejecutan las notificaciones de tipo exclusión y luego las de tipo enviar.



`Pantilla` 

Son plantillas HTML que define el diseño de la notificación. 

Es necesario seleccionar las opciones que comienzan por "generic". 

La plantillas *generic.html* es la más sencilla compuesta por un título y un cuerpo. 

El resto de plantillas contienen elementos más concretos: 

*generic_assigned.html*: Plantilla más especifica para eventois de tipo `event.topic.modify_field`. 

*generic_post.html*: Utilizada comunmente para eventos sobre comentarios. 

*generic_rule.html*: Plantilla HTML optimizada para eventos de tipo regla. 

*generic_topic.html*: Plantilla utilizada para eventos sobre tópicos. 



`Asunto` - Para el asunto de la notificación es posible crear uno nuevo o utilizar el que tendrá por defecto. En caso de querer establecer un asunto personalizado hay que tener en cuenta: 

Que el asunto sea breve. 

El asunto puede ser dinámico utilizando variables stash, por ejemplo `$ {username}`.

`Destinatarios` - A través de la opción de <img src = "/static/images/icons/add.gif" /> Crear, se selecciona los destinatarios de las notificaciones. Al pulsar el botón de crear, se abre una nueva ventana para especficar los destinatarios.

*To* 

*CC* 

*BCC* 


Segunda selección - Selecciona los destinatarios, estos pueden ser: 

*Usuarios* - Permite seleccionar a los usuarios que recibirán la notificación. 

*Roles* - Permite notificar del evento a un grupo de usuarios que tenga un mismo rol.

*Acciones* 

*Fields* 

*Owner* 

*Email* - Envia la notificacion a los emails especficados, sean usuarios de la herramienta o no.



En algunos casos se necesita información adicional sobre el ámbito del evento, por ejemplo, las condiciones que se tienen que cumplir en un evento de despliegue. 

*Evento de tipo job*. Campo adicional: Proyecto/Entorno/Estado - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, entorno o estado. Los eventos de tipo step tiene un campo adicional Paso, el cuál permite avisar en función del paso.

*Post*. Campos adicionales - Proyecto/Categoría/Estado. - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, categoría o estado.

*Topic*. Campos adicionales - Proyecto/Categoría/Estado. - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, categoría o estado. 



Cada sistema de eventos tiene distintos comportamientos: 

Cuando se deja en blanco la definición de la notificación, la notificación sólo se pondrá en marcha si el evento también tiene el campo vacío. 


Cuando se marca la casilla "Todos", a la derecha de los campos, la condición se cumple para cualquier valor de los datos en el evento. 



#### <img src = "/static/images/icons/edit.svg" /> Editar

* Para habilitar la opción de editar una notificación, es necesario seleccionar una notificación ya existente.
* La ventana que se abre para la edición es la misma que para la creación.


#### <img src = "/static/images/icons/delete_.png" /> Borrar
* Permite eliminar una o varias notificaciones.


#### <img src = "/static/images/icons/start.png" /> Activar / <img src = "/static/images/icons/stop.png" /> Desactivar
* Permite activar o desactactivar una o varias notificaciones.


#### <img src = "/static/images/icons/import.png" /> Importar / <img src = "/static/images/icons/export.png" /> Exportar
* Dentro de las opciones del icono <img src = "/static/images/icons/wrench.svg" /> se encuentran las opciones para importar o exportar notificaciones.
* Para la **exportación**, es necesario seleccionar al menos una fila, una vez seleccionadas las notificaciones que se deseen exportar, el sistema generará un fichero YAML con los datos del evento.
* La opción de **importar** abrirá una ventana donde añadir el YAML de la notificación. Una vez añadido el código es necesario importarlo a través del botón <img src = "/static/images/icons/import.png" /> Importar que aparece en la parte superior de la ventana activa. Debajo, aparecerá el resultado de la importación.
* Si ha ido de manera correcta el sistema informará con un mensaje:

        ----------------| Notify:  |----------------
        Creado notificacion
        Notify created with id 569cd49ee13823172da4a1 and event_key:
        finalizado

