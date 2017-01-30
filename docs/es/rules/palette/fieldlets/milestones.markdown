---
title: Milestones
index: 5000
icon: fieldlet-milestones
---

Permite añadir un plan con fechas para poder realizar un seguimiento del estado del proyecto.

La lista de elementos que pueden ser configurados dentro del fieldlet.

### Ubicación del fieldlet
Indica en que parte de la vista se pondrá el fieldlet.

- **Cabecera** - Se muestra en la parte central del formulario.
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

### Columnas

Indica las columnas que se muestran en la tabla.

Los nombres de las columnas van separados por **;**.

Después del nombre de la columna, hay que indicar el tipo de columna (si se omite, es un área de texto), o, en caso de querer un menú desplegable, las opciones.

    fecha_inicial,datefield; fecha_final, datefield; notas, text;


#### Tipos disponibles

- **Datefield** - Introduce un campo con un calendario desplegable para añadir una fecha.
- **Textfield** - Añade un campo de texto de una fila en la columna
- **Text** - Añade un cuadro de texto en la columna (tres filas) para añadir una descripción u observaciones por ejemplo.
