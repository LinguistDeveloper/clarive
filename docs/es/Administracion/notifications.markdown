---
title: Notificaciones
icon: email
---
* Para acceder es necesario tener permisos de administración de la herramienta. 
* Para la configuración de las notificaciones se accede a través de Administración → <img class = "bali-topic-editor-image" src = "/static/images/icons/email.png" /> Notificaciones. 
* Esta ventana muestra una lista con las notificaciones existentes y un menú de acciones.
* La información se presenta de la siguiente manera:

<br />
## Columnas

<br />
#### Eventos
* Describe el evento y su acción asociada. 
* En Clarive, las notificaciones se configuran a través de eventos. 


<br />
#### Destinatarios
* Indica los destinatarios de la notificación.

<br />
#### Ámbitos
* Describe más propiedades de la notificación. Estas propiedades son:
    
    &nbsp; &nbsp;• *Proyecto*: Indica el proyecto definido al crear la notificación. Esto permite enviar notificaciones en función al proyecto donde ocurra el evento. <br />
    
    &nbsp; &nbsp;• *Categoría*: Indica las categorías por las que el evento podrá activarse.  <br />
    
    &nbsp; &nbsp;• *Categoría / Estado*: Define los estados de las categorías para la notificación.

<br />
#### Acción
* Indica el tipo de acción de la notificación.

<br />
#### Activado
* Todas las notificaciones pueden ser activadas o desactivadas. Esta columna muestra el estado a través de dos iconos <img  src = "/static/images/icons/start.png" /> o <img src ="/static/images/icons/stop.png "/>.
* Al igual que el resto de listas que hay en Clarive, tiene las mismas funcionalidades que las demás, esto es, posibilidad de ordenar una columna pinchando en el nombre de la misma, seleccionando las columnas que se quieren mostrar o realizar una [búsqueda](Primeros_pasos/search-syntax).

<br />

## Acciones disponibles

<br />
#### <img src = "/static/images/icons/add.gif" /> Crear
* Permite crear una nueva configuración. Para ello hay que configurar los siguientes parámetros: <br />

&nbsp; &nbsp;• `Evento` - Indica el tipo de evento, los nombres son intuitivos y vienen definidos por una regla nemotécnica: <br />
&nbsp; &nbsp;&nbsp;&nbsp;• Ejemplo: event.topic.create <br />
&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *event* - Indica el tipo de notificación (en este caso todos será de tipo **evento**). <br />
&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *topic* - Indica la categoría de la notificación. <br />
&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;• *create* - Indica la acción a realizar. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Como regla general, se describen los siguientes eventos: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Auth*: Sistema de autentificación.<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *File*: Archivo. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Job*: Trabajo. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Post*: Comentarios. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Repository*: Eventos. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Rule*: Reglas. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Topic*: Tópicos. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *User*: Creación de comentarios. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Ws*: Servicios web. <br />

excluior_ excluir de la notificacion 

por defecto hay noitis automáticas para cualquier evento de tópicos 

pirmero se sacan las notificacion, luego la excluison y luego se envian

config.notificacions.exclude_default si esta 



&nbsp; &nbsp;• `Enviar / Excluir` <br />

&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• Las notificaciones puede ser configuradas para ser enviadas o excluidas. <br />

&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• Por defecto Clarive tiene algunas notificaciones activadas como por ejemplo enviar una notificaciones al propietario del estado del tópico o al responsable de una categoría determinada. Esta notificacion se puede evitar añadiendo una notificación de tipo Exclusión.

&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• En el orden de las notificaciones para ser ejecutadas, primero se ejecutan las notificaciones de tipo exclusión y luego las de tipo enviar.

<br />


&nbsp; &nbsp;• `Pantilla` <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Son plantillas HTML que define el diseño de la notificación. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Es necesario seleccionar las opciones que comienzan por "generic". <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• La plantillas *generic.html* es la más sencilla compuesta por un título y un cuerpo. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• El resto de plantillas contienen elementos más concretos: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_assigned.html*: Plantilla más especifica para eventois de tipo `event.topic.modify_field`. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_post.html*: Utilizada comunmente para eventos sobre comentarios. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_rule.html*: Plantilla HTML optimizada para eventos de tipo regla. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *generic_topic.html*: Plantilla utilizada para eventos sobre tópicos. <br />

<br />

&nbsp; &nbsp;• `Asunto` - Para el asunto de la notificación es posible crear uno nuevo o utilizar el que tendrá por defecto. En caso de querer establecer un asunto personalizado hay que tener en cuenta: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Que el asunto sea breve. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• El asunto puede ser dinámico utilizando variables stash, por ejemplo `$ {username}`. <br />


<br />


&nbsp; &nbsp;• `Destinatarios` - A través de la opción de <img src = "/static/images/icons/add.gif" /> Crear, se selecciona los destinatarios de las notificaciones. Al pulsar el botón de crear, se abre una nueva ventana para especficar los destinatarios.

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Primera selección - Establece de qué manera aparecerán los destinatarios. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *To* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *CC* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *BCC* <br />


&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Segunda selección - Selecciona los destinatarios, estos pueden ser: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Usuarios* - Permite seleccionar a los usuarios que recibirán la notificación. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Roles* - Permite notificar del evento a un grupo de usuarios que tenga un mismo rol.<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Acciones* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Fields* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Owner* <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Email* - Envia la notificacion a los emails especficados, sean usuarios de la herramienta o no.<br />

<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• En algunos casos se necesita información adicional sobre el ámbito del evento, por ejemplo, las condiciones que se tienen que cumplir en un evento de despliegue. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Evento de tipo job*. Campo adicional: Proyecto - Especifica el proyecto para ser notificado. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Post*. Campos adicionales - Proyecto/Categoría/Estado. - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, categoría o estado.<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• *Topic*. Campos adicionales - Proyecto/Categoría/Estado. - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, categoría o estado. <br />

<br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;• Cada sistema de eventos tiene distintos comportamientos: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• Cuando se deja en blanco la definición de la notificación, la notificación sólo se pondrá en marcha si el evento también tiene el campo vacío. <br />


&nbsp; &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;• Cuando se marca la casilla "Todos", a la derecha de los campos, la condición se cumple para cualquier valor de los datos en el evento. <br />



<br />
#### <img src = "/static/images/icons/edit.gif" /> Editar
* Para habilitar la opción de editar una notificación, es necesario seleccionar una notificación ya existente.
* La ventana que se abre para la edición es la misma que para la creación.

<br />
#### <img src = "/static/images/icons/delete_.png" /> Borrar
* Permite eliminar una o varias notificaciones.

<br />
#### <img src = "/static/images/icons/start.png" /> Activar / <img src = "/static/images/icons/stop.png" /> Desactivar
* Permite activar o desactactivar una o varias notificaciones.

<br />
#### <img src = "/static/images/icons/import.png" /> Importar / <img src = "/static/images/icons/export.png" /> Exportar
* Dentro de las opciones del icono <img src = "/static/images/icons/wrench.gif" /> se encuentran las opciones para importar o exportar notificaciones.
* Para la **exportación**, es necesario seleccionar al menos una fila, una vez seleccionadas las notificaciones que se deseen exportar, el sistema generará un fichero YAML con los datos del evento.
* La opción de **importar** abrirá una ventana donde añadir el YAML de la notificación. Una vez añadido el código es necesario importarlo a través del botón <img src = "/static/images/icons/import.png" /> Importar que aparece en la parte superior de la ventana activa. Debajo, aparecerá el resultado de la importación.
* Si ha ido de manera correcta el sistema informará con un mensaje:
            
        ----------------| Notify:  |----------------
        Creado notificacion 
        Notify created with id 569cd49ee13823172da4a1 and event_key: 
        finalizado

