---
title: Desplegable de proyectos
index: 5000
icon: combo_box
---

Añade al tópico una lista desplegable de proyectos.

La lista de elementos que pueden ser configurados dentro del fieldlet.


### Ubicación del fieldlet

Indica en que parte de la vista se pondrá el fieldlet.

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

- **Único** - Permite seleccionar unicamente una opción.
- **Múltiple** - Permite al usuario añadir tantas opciones como desee.
- **Tabla** - Las opciones seleccionadas se muestran en una tabla.

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

### Clase CI

Especifica la clase de CI que se va a mostrar en las opciones.

Tipicamente este combose se utilizan los CIs de tipo *proyecto*.

### Valor por defecto

Permite mostrar un valor por defecto en el combo.

### Roles

Selecciona los roles que se mostrarán en el grid.

### Descripción

Selecciona la descripción que será mostrada al mostrar el listado de opciones.

- **Nombre** - Muestra el nombre del elemento.
- **Entorno** - Muestra el nombre y los entornos separados por comas.
- **Clase** - Muestra el nombre y el tipo de objeto que es.
- **Nemónico** - Muestra el nombre y el nemónico especificado en la configuración del CI.
