---
title: Topic selector with filter
index: 400
icon: combo_box
---

Permite añadir tópicos al formulario con más filtros que el grid de tópicos estandar.

Permite además crear tópicos desde el formulario pulsando el botón: <img src="/static/images/icons/add.gif" />

La lista de elementos que pueden ser configurados dentro del fieldlet.


### Ubicación del fieldlet

Indica en que parte de la vista se pondrá el fieldlet.

**Cabecera*- Se muestra en la parte central del formulario.

**Detalles*- Se muestra en la parte derecha del formulario, debajo de la sección de detalles.

**Más información*- Se muestra en la pestaña de Más información situada en la parte inferior del tópico.


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

**Único*- Permite seleccionar unicamente una opción.

**Múltiple*- Permite al usuario añadir tantas opciones como desee.

**Tabla*- Las opciones seleccionadas se muestran en una tabla.



### Campo visible
En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.
Por defecto, es el titulo lo que se muestra.

Permite añadir un filtro avanzado JSON.


        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


Donde id es el [MID](Conceptos/mid) de la categoría.



### Lista de columnas para mostrar en el grid
Permite seleccionar las columnas que serán mostradas en el grid.
Por defecto las columnas que se muestran son las de Nombre del tópico (muestra la categoria y el ID) y Título del tópico.
Se indica primero el dato de la columna y posteriormente el nombre de la columna, por ejemplo:
    *name;title;Proyectos.__project_name_list,**Proyectos**;name_status,**Estado**;Asignada.__user_name,**Asignada**,ci; prioridad,**Prioridad**;complejidad,**Complejidad***.

Mostrará las siguientes columnas con el siguiente contenido:
**Name*- Muestra el número de tópico en una columna llamada ID.
**Title*- Muestra el título del tópico en una columna llamada Título.
**Proyectos*- Muestra el nombre de los proyectos a través de la variable: *_project_name_list*.
**Estado*- Muestra el nombre del estado.
**Asignada*- Muestra el nombre de usuario asignado al tópico.
**Prioridad*- Muestra la prioridad del tópico.
**Complejidad*- Muestra la complejidad.

*Nota:Opción solo disponible en el Tipo Grid del fieldlet.



### Altura del grid en modo edición
Cuando se escoja el fieldlet de tipo grid, este campo define la altura del fieldlet.


### Tamaño de la página
Define el número de elementos que aparecerán en la lista de selección de tópico.
*Nota:Opción solo disponible en el Tipo Grid del fieldlet.



### Campo padre
Permite seleccionar los tópicos disponibles indicando el id de un fieldlet de otra regla de tipo formulario.


### Campo para filtrar
Permite filtrar la lista de los tópicos en función de un campo de este mismo formulario.
En el campo se completa con el ID del elemento que se quiere usar de filtro.
Por ejemplo, si en el formulario existen [opciones](Reglas/Paleta/Fieldlets/Pills) de categorías, la herramienta listará solo los tópicos de la categoría seleccionada en las opciones. Si el usuario cambia de opción, la lista también cambia a los tópicos de la otra categoría.

### Datos para filtrar
Indica el campo por el que realizar el filtro.
Si se sigue con el ejemplo anterior, si en las opciones aparecen el nombre de las categorías, el dato para realizar el filtro sería el nombre de la categoría: *category_name*.

