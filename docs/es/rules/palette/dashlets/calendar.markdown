---
title: Calendario
index: 5000
icon: dashlet-topic-calendar
---

Muestra un calendario en el dashboard.

En la configuración del dashlet existen varias opciones para personalizarlo:

### Altura en canvas

Define la altura en número de filas que se le da al dashlet.

El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el dashboard.

El valor máximo permitido es de 12 (100% de anchura).

### Frecuencia de autorefresco

Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

### Consulta de calendario

El usuario decidirá qué tipo de consulta desea ver en el calendario. Las opciones son:

- **Actividad del tópico** - Permite ver las actividades de los tópicos seleccionados desde su creación hasta su modificación.
- **Tópicos abiertos** - Muestra los tópicos abiertos desde su creación hasta sus estados finales.
- **Planificador** *(ej: Hitos o Planificador de pases)* - Visualiza las planificaciones realizadas para las ventanas de pases o de hitos específicos.
- **Campos propios** - Personaliza los campos que se van a mostrar, por ejemplo si se quieren de determinados rangos de fecha. Para ello hay que configurar los dos campos que aparecen:
    - *Fecha inicial*
    - *Fecha final*

### Vista por defecto
Permite establecer la vista del calendario

- **Mes** - Se muestra una visión del mes actual
- **Semana** - Muestra todos los días de la semana (de lunes a domingo).
- **Semana por horas** - Muestra la semana actual completa dividida por horas.
- **Día** - Muestra solo el día actual
- **Día por horas** - Se muestra el día actual dividido por horas.

### Primer día de la semana

Configura el primer día de la semana.

### Seleccionar tópicos en categorías

Selecciona las categorías para la vista del calendario.

### ¿Excluir categorías seleccionadas?

Permite hacer excluyente la opción superior mostrando solo las categorías **no** seleccionadas.

### ¿Mostrar jobs?

Permite, en caso de que el usuario tenga permisos mostrar los jobs programados en el calendario.

### Condición avanzada JSON/MongoDB

Permite añadir un filtro para las filtrar los topicos y/o categorías a mostrar.

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.

### Máscara de etiqueta de tópicos

Permite personalizar la etiqueta de los tópicos.

*Ejemplo*: *${category.acronym}#${topic.mid} ${topic.title}*