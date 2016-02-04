---
title: Calculated numberfield
index: 400
icon: number.png
---
* Permite realizar una operación de cálculo recibiendo los valores a operar de fieldets de tipo [numérico](Reglas/Paleta/Fieldlets/Numberfield).
* La lista de elementos que pueden ser configurados dentro del fieldlet.


<br />
### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet. <br />

&nbsp; &nbsp;• **Cuerpo** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.

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
### Operación
* Especifica, con los parámetros necesarios la operación matemática a realizar.
* *Ejemplo:* $1+$2 - Hace la suma de los dos elementos indicandos en el siguiente campo.

<br />
### Campos de la operación
* Se especifica los campos que se van a utilizar en la operación.
* Los campos, que son los IDs de los fieldlets de tipo numérico, van separados con comas.
* *Ejemplo:* id1, id2 - Donde id1 y id2 indican dos fieldlets de tipo numérico creados anteriormente en la regla. <br />

&nbsp; &nbsp;• En este ejemplo, la variable $1 puesta en el campo Operación haria referencia a id1 y el $2 al id2.