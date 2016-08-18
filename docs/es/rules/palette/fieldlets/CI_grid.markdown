---
title: CI Grid
index: 400
icon: grid
---
* Permite añadir una tabla de CIs en el formulario.
* La lista de elementos que pueden ser configurados dentro del fieldlet.


### Ubicación del fieldlet
* Indica en que parte de la vista se pondrá el fieldlet.

**Cabecera** - Se muestra en la parte central del formulario.

**Más información** - Se muestra en la pestaña de Más información situada en la parte inferior del tópico.



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
* El tipo de campo es **Grid** por defecto. Esto implica que los tópicos añadidos son mostrados en una tabla.


### Campo visible
* En caso de no haber seleccionado el tipo Tabla en la opción anterior, se establece el texto para mostrar en la opción seleccionada.
* Por defecto, es el titulo lo que se muestra.


### Filtro avanzado JSON
* Permite añadir un filtro avanzado JSON.
* En este ejemplo solo mostrará un proyecto para mostrar:

        {"name":"Nombre_proyecto"}
        {"moniker":"Alias_del_proyecto"}



Los campos seleccionables para poder filtrar se pueden consultar a través del REPL. En este caso el comando será: `ci->project->find_one();`

* También es posible aplicar intervalos para limitar los resultados. Para ello es necesario hacer uso de los comandos *lt* y *gt* propios de MongoDB.
* Así para mostrar solo proyectos creados durante un intervalo de tiempo bastaria con construir la siguiente query:

        {"ts": {"$gt":"2016-03-22","$lt":"2016-04-08" } }




### Método de selección
* Permite filtrar las posibles opciones seleccionables.

**Selección por rol**
**Selección por clase**


### Roles
* Se muestra una lista con los roles.
* Por defecto, el valor de este campo es **CI**.
* Si la opción *Selección por clase* está activada, el valor de este campo tiene que ser **CI**.



### Clase CI
* La selección de este campo solo está disponible si está activado la *selección por clase*
* Especifica la clase de CI que se va a mostrar en las opciones.

### Valor por defecto
* Se selecciona el valor que se quiere por defecto en el grid.
* Este campo estará habilitado cuando se seleccione una clase CI.


### Mostrar clase
* Indica si se quiere mostrar la clase de elemento en el formulario.
