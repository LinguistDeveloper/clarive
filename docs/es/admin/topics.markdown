---
title: Administracion de topicos
icon: topic
---
* La administración de tópicos se ubica dentro de las opciones de **Administración → <img src="/static/images/icons/topic.svg" /> Categorías**.

## Categorías
**Categorías**

### Columnas
**Columnas**

#### Categoría
**Categoría**: Indica el nombre de la categoría y el color de la misma tal y como se mostrará en los tópicos. 

#### ID
* Muestra el identificador único de cada categoría. 

#### Acrónimo
* Indica el sobrenombre de la categoría. Configurable dentro de las opciones de cada categoría.

#### Descripción
* Descripción de la categoría. 

#### Tipo
* Indica el tipo de categoría.

### Opciones

#### <img src = "/static/images/icons/add.svg" alt='Nueva categoría' /> Crear
* Permite crear una nueva categoría. 
* Al pulsar en `Crear` se abre una nueva ventana con todas las opciones para crear una categoría a medida.

- `Categoría`: Especifica el nombre de la nueva categoría.
- `Acrónimo`: Indica el sobrenombre de la categoría nueva.
- `Descripción`: Permite describir con más detalle la categoría, finalidad de la misma, uso, etc...
- `Tipo`: Indica el tipo de categoría. Los tipos disponibles son:
- *Normal*: Se trata de una categoría estandar, utilizado para las colaboraciones en un proceso de entrega continua. Por ejemplo, son categorías de tipo normal Requerimientos, Incidencia, Tarea, Consulta, etc...
- *Cambio*: Un tópico de esta categoría se utiliza para realizar un seguimiento de los cambios a nivel de código que forman parte del proceso.
- *Release*: Esta categoría se utiliza para poder desplegar a otros entornos. Generalmente a los tópicos de tipo Release se asignan tópicos de una categoría de tipo Cambio para desplegar los nuevos cambios en el código en otros entornos.
- `Elije color`: Selecciona el color con el que se identificará a los tópicos.
- `Grid por defecto` : permite utilizar un reporte como un grid personalizado.
- `Formulario`: Selecciona el [formulario](rules/rule-concepts) con el que se completará la información de un tópico.
- `Dashboard` : permite seleccionar un dashboard para ver la informacion en el tópico.
- `Proveedores`: Especifica el proveedor de la categoría. Éste puede ser creado de manera interna o se puede utilizar cualquiera de las integraciones permitidas por Clarive como Bugzilla, Basecamp, Trac, Redmine, BMC Remedy, Jira, etc...
- `Opciones`: Permite crear tópicos de solo lectura. Usado en las integraciones para evitar sobreescribir información.
- `Lista de estados`: Permite seleccionar los [estados](admin/status) que estarán disponibles en los tópicos de la categoría. Este grid muestra todos los estados disponibles y creados como elementos CI y su descripción. Es importante que las categorías tengan al menos un estado inicial y otro final.

* Una vez guardado, la categoría aparecerá en la lista de categorías


#### <img src = "/static/images/icons/edit.svg" alt='Editar categoría' /> Editar
* Permite editar la categoría seleccionada.
* En modo Editar, aparece una nueva pestaña `Flujo de trabajo`. En ella se especifica el flujo de estados que el tópico podrá transitar siempre en función de los roles.

	- **Flujo de trabajo** - En esta pestaña aparecen los roles disponibles y los estados disponibles.

	- Para crear una transición en función de un rol, primero se selecciona el rol y a continuación, en el menú desplegable, el estado desde el cual comenzará la transición.

	- Tras ello, aparecerá en la lista los estados de la categoría disponibles y donde se elegirán los destinos de la transición.

	 Para confirmar el flujo, pulsar <img src = "/static/images/icons/down.svg"/>.

	- En caso de desear eliminar una de las transiciones, se puede realizar de dos maneras diferentes:
	- Para eliminar una transición, se selecciona la transición a borrar y se pulsa en <img src = "/static/images/icons/delete.svg"/> Borrar fila.

	- Para eliminar más de una transición de un rol especifico, se selecciona el rol en la lista de la izquierda y las transiciones a la derecha. A continuación pulsar el botón de desasignar <img src = "/static/images/icons/clear-all.svg"/>.


### <img src = "/static/images/icons/delete.svg" alt='Borrar categoría' /> Borrar
* Permite eliminar todas las categorías que están seleccionadas.
* El sistema alertará de la acción y pedirá confirmación para seguir con el borrado evitando así borrados accidentales.
* Las categorías no se puede eliminar si hay instancias de ésta en la base de datos. Estos casos deben ser revisados primero y eliminados despues antes de borrar la categoría. De esta manera se garantiza la integridad de la base de datos


### <img src = "/static/images/icons/copy.svg" alt='Duplicar categoría' /> Duplicar
* Permite duplicar la categoría seleccionada. 
* Esta nueva categoría tendrá las mismas propiedades que la original, nombre, color, formulario, estados disponibles, flujos de trabajo etc..
* Solo va a tener diferente el nombre que será el nombre de la categoría original seguido del ID generado para esta nueva categoría.
* Tras duplicar una categoría es **recomendable** editarla y cambiar el nombre, descripción y demás elementos que pueden provocar confusión entre la categoría original y la duplicada.

### <img src = "/static/images/icons/wrench.svg" alt='Import_export' /> Importar/Exportar
* El sistema permite importar y exportar los tópicos seleccionados en caso de que querer copiar las categorías existentes de un sistema a otro.
* Al pulsar en  <img src = "/static/images/icons/export.svg" alt='Exportar' /> Exportar, se abrirá una nueva ventana con el código YAML de las categorías seleccionadas.
* Al pulsar en <img src = "/static/images/icons/import.svg" alt='Import' /> Importar, se abrirá una nueva ventana donde pegar el código generado durante la exportación. 
* Una vez pulsado en `Importar` se podrá ver el progreso y estado de la importación en la parte inferior de la ventana.