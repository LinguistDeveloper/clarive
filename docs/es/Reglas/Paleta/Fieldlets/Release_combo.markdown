---
title: Release combo
index: 400
icon: combo_box
---
* Añade al tópico una lista desplegable de tópicos de categorias de tipo Release.
* La lista de elementos que pueden ser configurados dentro del fieldlet.


### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet.

&nbsp; &nbsp;• **Cabecera** - Se muestra en la parte central del formulario.

&nbsp; &nbsp;• **Cuerpo** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.

&nbsp; &nbsp;• **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico.


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
* Este fieldlet unicamente acepta que se añada una única opción en el formulario del tópico.


### Campo visible
* En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.
* Por defecto, es el titulo lo que se muestra.


### Filtro avanzado JSON
Permite añadir un filtro avanzado JSON

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


&nbsp;&nbsp;• Donde id es el [MID](Conceptos/mid) de la categoría.


### Campo Release
* Establece la dependencia entre este tópico de tipo Release y los tópicos dependientes.
* Se realiza a través de este campo que se completa con el ID del campo del formulario de dichos tópicos dependientes.