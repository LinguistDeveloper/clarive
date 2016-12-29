---
title: Selector de tópicos
index: 5000
icon: combo_box
---

Permite añadir un tópico existente al nuevo tópico.

Permite además crear tópicos desde el formulario pulsando el botón: <img src="/static/images/icons/add.svg" />

La lista de elementos que pueden ser configurados dentro del fieldlet.


### Ubicación del fieldlet
Indica en que parte de la vista se pondrá el fieldlet.

- **Cabecera**- Se muestra en la parte central del formulario.
- **Más información**- Se muestra en la pestaña de Más información situada en la parte inferior del tópico.
- **Detalles** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el formulario.

El valor máximo permitido es de 12 (100% de anchura).


### Ocultar en el modo lectura

Indica si el campo se quiere ocultar en modo lectura.


### Ocultar en el modo edición

Indica si el campo se quiere ocultar en modo edición.


### Campo obligatorio

Indica si el campo tiene que ser completado obligatoriamente.


### Tipo

Permite definir la apariencia de la tabla en el tópico:

- **Único**- Permite seleccionar unicamente una opción.
- **Múltiple**- Permite al usuario añadir tantas opciones como desee.
- **Grid** - Las opciones seleccionadas se muestran en una tabla.

### Campo mostrado

En caso de no haber seleccionado el tipo Grid en la opción anterior, se establece el texto para mostrar en la opción seleccionada.

Por defecto, es el título lo que se muestra.


### Filtro avanzado JSON

Permite añadir un filtro avanzado JSON


        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Donde *id* es el [MID](concepts/mid) de la categoría.

También es posible aplicar intervalos para limitar los resultados. Para ello es necesario hacer uso de los comandos *lt* y *gt* propios de MongoDB.

Así para mostrar solo proyectos creados durante un intervalo de tiempo bastaria con construir la siguiente query:

        {"ts": {"$gt":"2016-03-22","$lt":"2016-04-08" } }

### Lista de columnas para mostrar en el grid

Permite seleccionar las columnas que serán mostradas en el grid.

Por defecto las columnas que se muestran son las de Nombre del tópico (muestra la categoría y el ID) y Título del tópico.


### Altura del grid en modo edición

Cuando se escoja el fieldlet de tipo grid, este campo define la altura del fieldlet.


### Tamaño de la página

Define el número de elementos que aparecerán en la lista de selección de tópico.

*Nota* - Opción solo disponible en el Tipo Grid del fieldlet


### Campo padre

Permite seleccionar los tópicos disponibles indicando el id de un fieldlet de otra regla de tipo formulario.


### Campo para filtrar

Permite filtrar la lista de los tópicos en función de un campo de este mismo formulario.

En el campo se completa con el ID del elemento que se quiere usar de filtro.

Por ejemplo, si en el formulario existen [opciones](rules/palette/fieldlets/pills) de categorías, la herramienta listará solo los tópicos de la categoría seleccionada en las opciones. Si el usuario cambia de opción, la lista también cambia a los tópicos de la otra categoría.

Este campo es obligatorio si el siguiente campo no está vacío.

### Datos para filtrar

Indica el campo por el que realizar el filtro.

Este campo es obligatorio si el campo anterior no está vacío.

### Tipo de filtro

Indica la lógica del filtro.

Por defecto, el tipo es OR.

Para más información, hay un *how-to* llamado [Filtros en fieldlets](how-to/filter-fieldlet).


### Tamaño de la página en el grid

Define el número de tópicos que aparecen en la tabla en modo visualización del tópico.

*Nota* - Opción solo disponible en el Tipo Grid del fieldlet


### ¿Mostrar los controles del grid?

Permite configurar cuando mostrar los controles del cuadro en modo visualización de tópico.

Las opciones son:

- **Solo si hay paginación**
- **Siempre**
- **Nunca**

### Ordenar por

Permite ordenar la tabla en modo visualización en función de la propiedad de los tópicos que se añada en este campo (title, created_on, modify_by, etc...).

Por defecto, se ordena por MID del tópico.

### Forma de ordenar

Establece el tipo de ordenación, ascendente o descendente.

Para más información, hay un how-to llamado [Filtros es fieldlets](how-to/filter-fieldlet).

### Columnas Customizables

Permite añadir columnas personalizadas en el fieldlet cuando es de tipo Grid.

**Id** - El id de la columna. Este campo es obligatorio y no puede ser cambiado una vez guardado.

**Nombre** - Nombre que aparecerá en la columna. Si no se especifica, éste será el id.

**Tipo** - Puede ser de tipo texto o variable. Este campo es obligatorio y no se puede modificar.

**Variable** - Este campo es obligatorio si el tipo es variable. Aparecen variables de tipo combo o array.

Para modificar el valor de la celda, hacer doble click en ella.
