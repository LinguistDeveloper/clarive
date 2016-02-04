---
title: Milestones
index: 400
icon: milestone
---
* Permite añadir un plan con fechas para poder realizar un seguimiento del estado del proyecto.
* La lista de elementos que pueden ser configurados dentro del fieldlet.

<br />
### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet. <br />

&nbsp; &nbsp;• **Cabecera** - Se muestra en la parte central del formulario. <br />

&nbsp; &nbsp;• **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico.<br />

<br />
### Anchura en canvas
* Establece el ancho que ocupará el elemento en el formulario.
* El valor máximo permitido es de 12 (100% de anchura).

<br />
### Ocultar en el modo lectura
* Indica si el campo se quiere ocultar en modo lectura.

<br />
### Ocultar en el modo edición
* Indica si el campo se quiere ocultar en modo edición.

<br />
### Campo obligatorio
* Indica si el campo tiene que ser completado obligatoriamente.

<br />
### Columnas
* Indica las columnas que se muestran en la tabla.
* Su funcionamiento es el mismo que el explicado en el Editor de tablas.
* Establece los campos y el formato de la tabla.
* Los nombres de las columnas van separados por **;**.
* Después del nombre de la columna, hay que indicar el tipo de columna (si se omite, es un área de texto), o, en caso de querer un menú desplegable, las opciones.
* *Ejemplo* - Sub-Tarea,,250;Estado,combo_dbl,,Nuevo,Nuevo#En Progreso#Hecho;Fecha,,datefield <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Se crea una columna llamada Sub-Tarea, de tipo texto (se ha omitido el tipo pero hay que poner explicimante las ,) y limitado a 250 caracteres. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• A continuación se crea otra columna 'Estado', un combo desplegable con la opcion predeterminada al principio y tras la coma, las opciones separadas por almohadilla. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• Por último una columna llamada Fecha de tipo fecha.<br />