---
title: Topics burndown NG
index: 400
icon: chart_line
---
* Muestra una línea de tendencia con los tópicos reales y las previsiones.
* La lista de elementos configurables del dashlet son:

### Altura en canvas
* Define la altura en numero de filas que se le da al dashlet.
* El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

### Anchura en canvas
* Establece el ancho que ocupará el elemento en el dashboard.
* El valor máximo permitido es de 12 (100% de anchura).

<br/>
### Frecuencia de autorefresco
* Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

### Agrupar por campo
* Agrupa los tópicos por un campo existente en los tópicos hijos.

### Agrupar por fecha
* Permite agrupar los datos por:
    Hora - En el eje X se muestran las 24 horas del día actual.
    Día de la semana - Los tópicos se agrupan en los 7 días de la semana (de lunes a domingo).
    Mes - Los tópicos se agrupan por los 12 meses del año
    Fecha - Se agrupa el número de tópicos en función del smétodo de selección de fecha.

### Método de selección de fecha

Duración - Selecciona un rango de fechas:
    Día - Muestra en el eje X el día actual (una única vertical).
    Semana - Muestra los días de la semana actual en el eje X (con fechas absolutas)
    Mes - Muestra en el eje X la semana actual (con fechas absolutas).
    Año - Muestra en el eje X el número de tópicos desde el 1 de enero del año actual hasta la fecha.
    Periodo - Establece el intervalo de fechas en el eje X para agrupar los tópicos.
    Filtro por tópico - Permite establece el intervalo de fechas en base a campos del tópico padre.

### El gráfico se mostrará como
Muestra los diferentes tipos de gráficos que pueden ser utilizados:
    **Area**
    **Area step**
    **Lineal**
    **Bar**
    **Scatter**

### Seleccionar tópicos en categorías
* Selecciona las categorías que se quieren mostrar en el gráfico

### Estados cerrados
* Indica los estados que no se tendrán en cuenta en el gráfico.

### Consulta JSON
* Permite añadir un filtro avanzado JSON

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25} 


    Donde id es el [MID](concepts/mid) de la categoría.


## Opciones como fieldlet
* Clarive permite añadir este dashlet dentro de un formulario de un tópico.
* Su comportamiento es el mismo que como dashlet.
* Dispone de dos opciones diferentes al dashlet para configurarlo:
    Ancho - Establece en % el ancho que ocupará el elemento en el tópico.
    Altura - Indica en píxeles el alto del elemento.
