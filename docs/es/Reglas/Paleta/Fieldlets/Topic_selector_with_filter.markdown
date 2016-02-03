---
title: Topic selector with filter
index: 400
icon: combo_box
---
    
<br />
* Permite añadir tópicos al formulario con más filtros que el grid de tópicos estandar.
* La lista de elementos que pueden ser configurados dentro del fieldlet.

<br />
### Ubicación del fieldlet* Indica en que parte de la vista se pondrá el fieldlet. <br />

&nbsp; &nbsp;• **Cabecera** - Se muestra en la parte central del formulario. <br />

&nbsp; &nbsp;• **Detalles** - Se muestra en la parte derecha del formulario, debajo de la sección de detalles.<br />

&nbsp; &nbsp;• **Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico.<br />

<br />
### Anchura en canvas* Establece el ancho que ocupará el elemento en el formulario.
* El valor máximo permitido es de 12 (100% de anchura).

<br />
### Ocultar en el modo lectura* Indica si el campo se quiere ocultar en modo lectura.

<br />
### Ocultar en el modo edición* Indica si el campo se quiere ocultar en modo edición.

<br />
### Campo obligatorio* Indica si el campo tiene que ser completado obligatoriamente.

<br />
### Tipo* Permite definir la apariencia de la tabla en el tópico: <br />

&nbsp; &nbsp;• **Único** - Permite seleccionar unicamente una opción. <br />

&nbsp; &nbsp;• **Múltiple** - Permite al usuario añadir tantas opciones como desee. <br />

&nbsp; &nbsp;• **Tabla** - Las opciones seleccionadas se muestran en una tabla.


<br />
### Campo visible* En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.
* Por defecto, es el titulo lo que se muestra.


<br />
### Filtro avanzado JSON* Permite añadir un filtro avanzado JSON

            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde id es el [MID](Conceptos/mid) de la categoría.


<br />
### Lista de columnas para mostrar en el grid
* Permite seleccionar las columnas que serán mostradas en el grid.
* Por defecto las columnas que se muestran son las de Nombre del tópico (muestra la categoria y el ID) y Título del tópico.
* *Nota:* Opción solo disponible en el Tipo Grid del fieldlet


<br />
### Altura del grid en modo edición
* Cuando se escoja el fieldlet de tipo grid, este campo define la altura del fieldlet.

<br />
### Tamaño de la página
* Define el número de elementos que aparecerán en la lista de selección de tópico.
* *Nota:* Opción solo disponible en el Tipo Grid del fieldlet


<br />
### Campo padre* Permite seleccionar los tópicos disponibles indicando el id de un fieldlet de otra regla de tipo formulario.

<br />
### Campo para filtrar* Permite filtrar la lista de los tópicos en función de un campo de este mismo formulario. 
* En el campo se completa con el ID del elemento que se quiere usar de filtro.
* Por ejemplo, si en el formulario existen [opciones](Reglas/Paleta/Fieldlets/Pills) de categorías, la herramienta listará solo los tópicos de la categoría seleccionada en las opciones. Si el usuario cambia de opción, la lista también cambia a los tópicos de la otra categoría. 

### Datos para filtrar
* Indica el campo por el que realizar el filtro.
* Si se sigue con el ejemplo anterior, si en las opciones aparecen el nombre de las categorías, el dato para realizar el filtro sería el nombre de la categoría: *category_name*.

