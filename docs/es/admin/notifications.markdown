---
title: Notificaciones
index: 4
icon: email
---

En el menú de 'Administración' seleccionamos
<img class = "bali-topic-editor-image" src = "/static/images/icons/email.svg" /> Notificaciones.

Se muestra el panel principal una tabla con las notificaciones de Clarive y una barra superior con las acciones disponibles (botones).

La información se presenta de la siguiente manera:

### Eventos

Se basan en el procedimiento de creación de notificaciones.

Las notificaciones Clarive están configuradas por los eventos.

Compruebe el "Evento ..." para obtener más información sobre la clasificación de eventos en Clarive.

### Destinatarios

Los destinatarios de las notificaciones. Más información en 'Crear Notificación: El destinatario ...'.

### Ámbitos

Describe más propiedades de la notificación. Estas propiedades son:

- *Proyecto* - Indica el proyecto definido al crear la notificación. Esto permite enviar notificaciones en función al proyecto donde ocurra el evento.
- *Entorno* - Indica el entorno definido para la notificación.
- *Estado* - Indica el estado final que se quiere para la notificación.
- *Paso* - Indica el paso que se quiere para la notificación.
- *Categoría* - Indica las categorías por las que el evento podrá activarse.
- *Categoría/Estado* - Define los estados de las categorías para la notificación.

### Acción

Indica el tipo de acción de la notificación, Enviar o Excluir.

#### Activado

Todas las notificaciones pueden ser activadas o desactivadas.

Esta columna muestra el estado a través de dos iconos <img  src = "/static/images/icons/start.svg" /> o <img src ="/static/images/icons/stop.svg"/>.

Todos los encabezados de columna tienen la misma funcionalidad que en el resto de paneles de Clarive.

Al hacer clic en el botón de la columna, podemos organizar información y seleccionar las columnas que desea ver en el panel.

### <img src = "/static/images/icons/add.svg" /> Crear

Permite crear una nueva notificación.

Para ello hay que configurar los siguientes parámetros:

- `Event`: La gama de eventos es extensa pero intuitiva, ya que su sintaxis es la siguiente norma concreta:
<p style = "text-align: center; font-weight: bold"> Ejemplo: event.topic.create → event elemento + acción + item </p>

Se resume a continuación:

- *event* - Mostrar el tipo de notificación. En este caso son del tipo **evento** .
- *topic* - Indica la categoría de la notificación
- *create* - Indica la acción a realizar.

Como regla general, se describen los siguientes eventos:

*Auth* - Sistema de autenticación.

*File* - Archivo.

*Job* - Trabajo.

*Post* - Comentarios.

*Repository* - Eventos.

*Rule* - Reglas.

*Topic* - Tópicos.

*User* - Creación de comentarios.

*Ws* - Servicios web.


- `Enviar / Excluir` - Las notificaciones puede ser configuradas para ser enviadas o excluidas.

Las notificaciones que se aplican a cada evento creado
se calcula mediante un algoritmo que decide qué notificaciones aplicar y luego calcula las exclusiones.

- `Pantilla` - Son plantillas HTML que define el diseño de la notificación.

Es necesario seleccionar las opciones que comienzan por "generic".

La plantillas *generic.html* es la más sencilla compuesta por un título y un cuerpo.

- El resto de plantillas contienen elementos más concretos:
  - *generic_assigned.html* - Plantilla más especifica para eventos de tipo `event.topic.modify_field`.
  - *generic_post.html* - Utilizada comúnmente para eventos sobre comentarios.
  - *generic_rule.html* - Plantilla HTML optimizada para eventos de tipo regla.
  - *generic_topic.html* - Plantilla utilizada para eventos sobre tópicos.
- `Asunto` - Para el asunto de la notificación es posible crear uno nuevo o utilizar el que tendrá por defecto. En caso de querer establecer un asunto personalizado hay que tener en cuenta:

Que el asunto sea breve.

El asunto puede ser dinámico utilizando variables stash (por ejemplo `$ {username}`).

- `Destinatarios` - A través de la opción de 
<img src = "/static/images/icons/add.svg" /> Crear, se selecciona los destinatarios de las notificaciones. Al pulsar el botón de crear, se abre una nueva ventana para especificar los destinatarios.
   * Primer combo:
      - *To*
      - *CC*
      - *BCC*
    * Segundo combo:
      - *Usuarios* - Permite seleccionar a los usuarios que recibirán la notificación.
      - *Roles* - Permite notificar del evento a un grupo de usuarios que tenga un mismo rol.
      - *Acciones* - Seleccionado una acción, envía una notificación a todos los usuarios que tienen asignado esta acción.
      - *Fields* - Permitir a enviar una notificación a los usuarios que se especifican en un fieldlet de tipo *user combobox*
      - *Owner* - Envía una notificación al propietario del tópico
      - *Email* - Envía la notificación a los e-mails especificados, sean usuarios de la herramienta o no.
    * En algunos casos se necesita información adicional sobre el ámbito del evento, por ejemplo, las condiciones que se tienen que cumplir en un evento de despliegue.
      - *Job* - Campo adicional: Proyecto/Entorno/Estado - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, entorno o estado. Los eventos de tipo step tiene un campo adicional Paso, el cuál permite avisar en función del paso.
      - *Post* - Campos adicionales - Proyecto/Categoría/Estado. - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, categoría o estado.
      - *Topic* - Campos adicionales - Proyecto/Categoría/Estado. - Permite realizar un mejor sistema de notificaciones al poder avisar en función del proyecto, categoría o estado.


Cada sistema de eventos tiene distintos comportamientos:

- Cuando se deja en blanco la definición de la notificación, la notificación sólo se pondrá en marcha si el evento también tiene el campo vacío.
- Cuando se marca la casilla "Todos", a la derecha de los campos, la condición se cumple para cualquier valor de los datos en el evento.

Una vez completado todos los campos pulsar en el botón 'OK' para crear la nueva notificación.

#### <img src = "/static/images/icons/edit.svg" /> Editar

Para habilitar la opción de editar una notificación, es necesario seleccionar una notificación ya existente.

La ventana que se abre para la edición es la misma que para la creación.


#### <img src = "/static/images/icons/delete.svg" /> Borrar
Permite eliminar una o varias notificaciones.


#### <img src = "/static/images/icons/start.svg" /> Activar / <img src = "/static/images/icons/stop.svg" /> Desactivar
Permite activar o desactivar una o varias notificaciones.


#### <img src = "/static/images/icons/import.svg" /> Importar / <img src = "/static/images/icons/export.svg" /> Exportar

Dentro de las opciones del icono <img src = "/static/images/icons/wrench.svg" /> se encuentran las opciones para importar o exportar notificaciones.

Para la **exportación**, es necesario seleccionar al menos una fila, una vez seleccionadas las notificaciones que se deseen exportar, el sistema generará un fichero YAML con los datos de la notificación.

La opción de **importar** abrirá una ventana donde añadir el YAML de la notificación a importar.
