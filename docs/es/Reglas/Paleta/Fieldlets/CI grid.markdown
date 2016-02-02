---
title: CI Grid
index: 400
icon: grid
---

    
<br />

* Permite añadir una tabla de CIs en el formulario.

* La lista de elementos que pueden ser configurados dentro del fieldlet.

<br />
### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet. <br />

&nbsp; &nbsp;• **Cabecera** - Se muestra en la parte central del formulario. <br />

&nbsp; &nbsp;• **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico


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
### Método de selección
* Permite filtrar las posibles opciones seleccionables. <br />

&nbsp; &nbsp;• **Selección por rol** <br />

&nbsp; &nbsp;• **Selección por clase**


<br />
### Roles

* Se muestra una lista con los roles.

* Si la opción *Selección por clase* está activada, el valor de este campo tiene que ser **CI**


<br />
### Clase CI

* La selección de este campo solo está disponible si está activado la *selección por clase*

* Especifica la clase de CI que se va a mostrar en las opciones.

<br />
### Mostrar clase

* Indica si se quiere mostrar la clase de elemento en el formulario.