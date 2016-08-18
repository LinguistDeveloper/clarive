---
title: Grid editor
index: 400
icon: grid
---
* Permite añadir una tabla con las columnas personalizadas en un tópico.
* La lista de elementos que pueden ser configurados dentro del fieldlet.

### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet.
    **Cabecera** - Se muestra en la parte central del formulario.
    **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico

### Anchura en canvas
* Establece el ancho que ocupará el elemento en el formulario.
* El valor máximo permitido es de 12 (100% de anchura).

### Ocultar en el modo lectura
* Indica si el campo se quiere ocultar en modo lectura.

### Ocultar en el modo edición
* Indica si el campo se quiere ocultar en modo edición.

### Campo obligatorio
* Indica si el campo tiene que ser completado obligatoriamente.


### Columnas
* Establece los campos y el formato de la tabla.
* Los nombres de las columnas van separados por ;.
* Después del nombre de la columna, hay que indicar el tipo de columna (si se omite, es un área de texto), o, en caso de querer un menú desplegable, las opciones.
* *Ejemplo* - Sub-Tarea,,250;Estado,combo_dbl,,Nuevo,Nuevo#En Progreso#Hecho;Fecha,,datefield

    Se crea una columna llamada Sub-Tarea, de tipo texto (se ha omitido el tipo pero hay que poner explicimante las ,) y limitado a 250 caracteres.
    A continuación se crea otra columna 'Estado', un combo desplegable con la opcion predeterminada al principio y tras la coma, las opciones separadas por almohadilla.
    Por último una columna llamada Fecha de tipo fecha
