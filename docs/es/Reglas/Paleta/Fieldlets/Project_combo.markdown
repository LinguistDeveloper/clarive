---
title: Project combo
index: 400
icon: combo_box
---

    
<br />

* Añade al tópico una lista desplegable de proyectos.

* There are a list of elements can be configured in the fieldlet:


* La lista de elementos que pueden ser configurados dentro del fieldlet.

<br />
### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet. <br />

&nbsp; &nbsp;• **Detalles** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.<br />

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
### Tipo
* Permite definir la apariencia de la tabla en el tópico: <br />

&nbsp; &nbsp;• **Único** - Permite seleccionar unicamente una opción. <br />

&nbsp; &nbsp;• **Múltiple** - Permite al usuario añadir tantas opciones como desee. <br />

&nbsp; &nbsp;• **Tabla** - Las opciones seleccionadas se muestran en una tabla.


<br />
### Campo visible
* En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.

* Por defecto, es el titulo lo que se muestra.

<br />
### Filtro avanzado JSON
* Permite añadir un filtro avanzado JSON

            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde id es el [MID](Conceptos/mid) de la categoría.



<br />
### Clase CI

* Especifica la clase de CI que se va a mostrar en las opciones. 

* En este combo, lo comun es que aparezcan los CI de tipo *proyecto*.

<br />
### Valor por defecto

* Permite mostrar un valor por defecto en el combo.

* El o los proyectos que se quieran poner por defecto tienen que estar especficados por el ID del CI.

<br />
### Roles
* Selecciona los roles que se mostrarán en el grid.