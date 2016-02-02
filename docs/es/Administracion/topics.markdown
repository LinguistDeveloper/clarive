---
title: Administracion de topicos
icon: topic
---

* La administración de tópicos se ubica dentro de las opciones de **Administración → Tópicos**.

* Dentro de la ventana de Administración de tópicos, se mostrarán dos partes diferenciadas. La primera está orientada para los tópicos, con el listado de las categorias existentes. En la segunda, en la parte inferior, se muestran las etiquetas y sus diferentes opciones.

<br />
## Categorias

<br />
### Columnas

<br />
#### Categoría

* Indica el nombre de la categoría y el color de la misma tal y como se mostrará en los tópicos. 

<br />
#### ID

* Muestra el identificador único de cada categoría. 

<br />
#### Acrónimo

* Indica el sobrenombre de la categoría. Configurable dentro de las opciones de cada categoría.

<br />
#### Descripción

* Descripción de la categoría. 

<br />
#### Tipo

* Indica el tipo de categoría.

<br />
### Opciones

<br />
#### <img src = "/static/images/icons/add.gif" alt='Nueva categoría' /> Crear

* Permite crear una nueva categoría. 

* Al pulsar en `Crear` se abre una nueva ventana con todas las opciones para crear una categoría a medida.

&nbsp; &nbsp;• `Categoría`: Especifica el nombre de la nueva categoría. <br />

&nbsp; &nbsp;• `Acrónimo`: Indica el sobrenombre de la categoría nueva. <br />

&nbsp; &nbsp;• `Descripción`: Permite describir con más detalle la categoría, finalidad de la misma, uso, etc...<br />

&nbsp; &nbsp;• `Tipo`: Indica el tipo de categoría. Los tipos disponibles son: <br />.

&nbsp; &nbsp;&nbsp; &nbsp;• *Normal*: Se trata de una categoría estandar, utilizado para las colaboraciones en un proceso de entrega continua. Por ejemplo, son categorias de tipo normal Requerimientos, Incidencia, Tarea, Consulta, etc... <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *Cambio*: Un tópico de esta categoría se utiliza para realizar un seguimiento de los cambios a nivel de código que forman parte del proceso. <br />

 &nbsp; &nbsp;&nbsp; &nbsp;• *Release*: Esta categoría se utiliza para poder desplegar a otros entornos. Generalmente a los tópicos de tipo Release se asignan tópicos de una categoría de tipo Cambio para desplegar los nuevos cambios en el código en otros entornos.
<br/>

&nbsp; &nbsp;• `Elije color`: Selecciona el color con el que se identificará a los tópicos. <br />

&nbsp; &nbsp;• `Grid por defecto`<br />

&nbsp; &nbsp;• `Formulario`: Selecciona el [formulario](Reglas/rule-concepts) con el que se completará la información de un tópico. <br />

&nbsp; &nbsp;• `Dashboard`<br />

&nbsp; &nbsp;• `Proveedores`: Especifica el proveedor de la categoria. Éste puede ser creado de manera interna o se puede utilizar cualquiera de las integraciones permitidas por Clarive como Bugzilla, Basecamp, Trac, Redmine, BMC Remedy, Jira, etc...<br />

&nbsp; &nbsp;• `Opciones`: Permite crear tópicos de solo lectura. Usado en las integraciones para evitar sobreescribir información. <br />

&nbsp; &nbsp;• `Lista de estados`: Permite seleccionar los [estados](Administracion/status) que estarán disponibles en los tópicos de la categoria. Este grid muestra todos los estados disponibles y creados como elementos CI y su descripción. Es importante que las categorias tengan al menos un estado inicial y otro final.


* Una vez guardado, la categoría aparecerá en la lista de categorías


<br/>
#### <img src = "/static/images/icons/edit.gif" alt='Editar categoría' /> Editar

* Permite editar la categoría seleccionada.

* En modo Editar, aparece una nueva pestaña `Flujo de trabajo`. En ella se especifica el flujo de estados que el tópico podrá transitar siempre en función de los roles.

&nbsp; &nbsp;•**Flujo de trabajo** - En esta pestaña aparecen los roles disponibles y los estados disponibles.<br/>

&nbsp; &nbsp;&nbsp; &nbsp;• Para crear una transición en función de un rol, primero se selecciona el rol y a continuación, en el menú desplegable, el estado desde el cual comenzará la transición.<br/>

&nbsp; &nbsp;&nbsp; &nbsp;• Tras ello, aparecerá en la lista los estados de la categoria disponibles y donde se elegirán los destinos de la transición.<br/> 

&nbsp; &nbsp;&nbsp; &nbsp;• Para confirmar el flujo, pulsar <img src = "/static/images/icons/down.png"/>.<br/>

&nbsp; &nbsp;&nbsp; &nbsp;• En caso de desear eliminar una de las transiciones, se puede realizar de dos maneras diferentes: <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• Para eliminar una transición, se selecciona la transición a borrar y se pulsa en <img src = "/static/images/icons/delete_.png"/> Borrar fila. <br />

&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;• Para eliminar más de una transición de un rol especifico, se selecciona el rol en la lista de la izquierda y las transiciones a la derecha. A continuación pulsar el botón de desasignar <img src = "/static/images/icons/remove.png"/> 



<br/>
### <img src = "/static/images/icons/delete_.png" alt='Borrar categoría' /> Borrar

* Permite eliminar todas las categorías que están seleccionadas.

* El sistema alertará de la acción y pedirá confirmación para seguir con el borrado evitando asi borrados accidentales.

* Las categorias no se puede eliminar si hay instancias de ésta en la base de datos. Estos casos deben ser revisados primero y eliminados despues antes de borrar la categoría. De esta manera se garantiza la integridad de la base de datos


<br/>
### <img src = "/static/images/icons/copy.gif" alt='Duplicar categoría' /> Duplicar

* Permite duplicar la categoría seleccionada. 

* Esta nueva categoria tendrá las mismas propiedades que la origina, nombre, color, formulario, estados disponibles, flujos de trabajo etc..

* Solo va a tener diferente el nombre que será el nombre de la categoria original seguido del ID generado para esta nueva categoría.

* Tras duplicar una categoría es **recomendable** editarla y cambiar el nombre, descripción y demás elementos que pueden provocar confusión entre la categoría original y la duplicada.

<br/>
### <img src = "/static/images/icons/wrench.gif" alt='Import_export' /> Importar/Exportar

* El sistema permite importar y exportar los tópicos seleccionados en caso de que querer copiar las categorías existentes de un sistema a otro.

* Al pulsar en  <img src = "/static/images/icons/export.png" alt='Exportar' /> Exportar, se abrirá una nueva ventana con el código YAML de las categorías seleccionadas.

* Al pulsar en <img src = "/static/images/icons/import.png" alt='Import' /> Importar, se abrirá una nueva ventana donde pegar el código generado durante la exportación. 

* Una vez pulsado en `Importar` se podrá ver el progreso y estado de la importación en la parte inferior de la ventana.