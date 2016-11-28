---
title: Desplegable de releases
index: 5000
icon: combo-box
---

Añade al tópico una lista desplegable de tópicos de categorías de tipo Release.

La lista de elementos que pueden ser configurados dentro del fieldlet.


### Ubicación del fieldlet

Indica en que parte de la vista se pondrá el fieldlet.

- **Cabecera** - Se muestra en la parte central del formulario.
- **Cuerpo** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.
- **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el formulario.

El valor máximo permitido es de 12 (100% de anchura).


### Ocultar en el modo lectura

Indica si el campo se quiere ocultar en modo lectura.


### Ocultar en el modo edición

Indica si el campo se quiere ocultar en modo edición.


### Campo obligatorio

Indica si el campo tiene que ser completado obligatoriamente.

### Selecciona tópicos en categorías

Selecciona una o más categorías a mostrar de tipo Release.

### Selecciona tópicos por estados

Selecciona uno o más estados para mostrar.

### Excluir los estados seleccionadas

Excluye los estados seleccionados en el punto anterior y muestra el resto que **no** están seleccionados.

### Tipo

Este fieldlet unicamente acepta que se añada una única opción en el formulario del tópico.


### Campo mostrado

En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.

Por defecto, es el titulo lo que se muestra.


### Filtro avanzado JSON

Permite añadir un filtro avanzado JSON

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Donde *id* es el [MID](concepts/mid) de la categoría.

También es posible aplicar intervalos para limitar los resultados. Para ello es necesario hacer uso de los comandos *lt* y *gt* propios de MongoDB.

Así para mostrar solo proyectos creados durante un intervalo de tiempo bastaria con construir la siguiente query:

        {"ts": {"$gt":"2016-03-22","$lt":"2016-04-08" } }


### Campo Release

Establece la dependencia entre este tópico de tipo Release y los tópicos dependientes.

Se realiza a través de este campo que se completa con el ID del campo del formulario de dichos tópicos dependientes.

### Campo para filtrar

Permite filtrar la lista de los tópicos en función de un campo de este mismo formulario.

Este campo es obligatorio si el siguiente campo no está vacío.

### Datos para filtrar

Indica el campo por el que realizar el filtro.

Este campo es obligatorio si el campo anterior no está vacío.

### Tipo de filtro

Indica la lógica del filtro.

Por defecto, el tipo es OR.

Para más información, hay un *how-to* llamado [Filtros en fieldlets](how-to/filter-fieldlet).