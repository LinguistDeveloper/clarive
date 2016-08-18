---
title: Task grid
index: 400
icon: grid
---
* Permite añadir tareas en el tópico.
* La lista de elementos que pueden ser configurados dentro del fieldlet.

### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet.

    **Cabecera** - Se muestra en la parte central del formulario.
    **Cuerpo** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.
    **Detalles** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.
    **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico.
    **Entre** - Los ficheros adjuntos se muestran en la parte derecha del formulario debajo de la sección de detalles.

### Anchura en canvas
* Establece el ancho que ocupará el elemento en el formulario.
* El valor máximo permitido es de 12 (100% de anchura).

### Ocultar en el modo lectura
* Indica si el campo se quiere ocultar en modo lectura.

### Ocultar en el modo edición
* Indica si el campo se quiere ocultar en modo edición.

### Campo obligatorio
* Indica si el campo tiene que ser completado obligatoriamente.


### Tipo
* Permite definir la apariencia de la tabla en el tópico:
    **Único** - Permite seleccionar unicamente una opción.
    **Múltiple** - Permite al usuario añadir tantas opciones como desee.
    **Tabla** - Las opciones seleccionadas se muestran en una tabla.


### Campo visible
* En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.
* Por defecto, es el título lo que se muestra.

### Filtro avanzado JSON
Permite añadir un filtro avanzado JSON


       {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Donde id es el [MID](concepts/mid) de la categoría.
