---
title: Calendario
index: 400
icon: calendar
---
* Muestra un calendario en el dashboard.
* En la configuración del dashlet existen varias opciones para personalizarlo:

<br />
### Altura en canvas
* Define la altura en numero de filas que se le da al dashlet.
* El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

<br />
### Anchura en canvas
* Establece el ancho que ocupará el elemento en el dashboard.
* El valor máximo permitido es de 12 (100% de anchura).

<br/>
### Frecuencia de autorefresco
* Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

<br />
### Consulta de calendario
* El usuario decidirá qué tipo de consulta desea ver en el calendario. Las opciones son: <br />


&nbsp; &nbsp;• **Actividad del tópico** - Permite ver las actividades de los topicos seleccionados desde su creación hasta su modificación.<br />

&nbsp; &nbsp;• **Open topics** - Muestra los topicos abiertos desde su creación hasta sus estados finales<br />

&nbsp; &nbsp;• **Planificador** *(eg: Hitos or Planificador de pases)
* - Visualiza las planificaciones realizadas para las ventanas de pases o de hitos especificos.<br />

&nbsp; &nbsp;• **Campos propios** - Personaliza los campos que se van a mostrar, por ejemplo si se quieren de determinados rangos de fecha. Para ello hay que configurar los dos campos que aparecen: <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *Fecha inicial* <br />

&nbsp; &nbsp;&nbsp; &nbsp;• *Fecha final*

<br />
### Vista por defecto
* Permite establecer la vista del calendario.<br />


&nbsp; &nbsp;• **Mes** - Se muestra una visión del mes actual.<br />

&nbsp; &nbsp;• **Semana** - Muestra todos los dias de la semana  (de lunes a domingo) <br />

&nbsp; &nbsp;• **Semana por horas** - Muestra la semana actual completa dividida por horas. <br />

&nbsp; &nbsp;• **Día** - Muestra solo el día actual.<br />

&nbsp; &nbsp;• **Día por horas**  - Se muestra el día actual dividido por horas.

<br />
### Primer día de la semana
* Configura el primer día de la semana.

<br />
### Seleccionar tópicos en categorías
* Selecciona las categorias para la vista del calendario.

<br />
### Excluir categorías seleccionadas?
* Permite hacer excluyente la opción superior mostrando solo las categorias **no** seleccionadas.

<br />
### Mostrar jobs?
* Permite, en caso de que el usuario tenga permisos mostrar los jobs programados en el calendario.

<br />
### Condición avanzada JSON/MongoDB
* Permite añadir un filtro para las filtrar los topicos y/o categorias a mostrar
            
        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


&nbsp;&nbsp;• Donde *id* es la clave una de la categoria. Dicho id se puede consultar a través del REPL.


<br />
### Máscara de etiqueta de tópicos
* Permite personalizar la etiqueta de los tópicos.
* *Ejemplo*: ${category.acronym}#${topic.mid} ${topic.title}