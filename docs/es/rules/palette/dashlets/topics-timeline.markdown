---
title: Timeline de tópicos
index: 5000
icon: dashlet-topic-dateline
---


Muestra el número de tópicos creados de una o varias categorías a lo largo de un determinado espacio de tiempo.

El dashlet es configurable a través de las siguientes opciones:

### Altura en canvas

Define la altura en número de filas que se le da al dashlet.

El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el dashboard.

El valor máximo permitido es de 12 (100% de anchura).

### Frecuencia de autorefresco

Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

### Seleccionar tópicos en categorias

Selecciona las categorías que se quieren mostrar en la tabla.

### Seleccionar tópicos en estados

Selecciona los estados que se quieren mostrar en el gráfico.

### Excluir estados seleccionados

Excluye los estados seleccionados en el punto anterior y muestra el resto que **no*
están seleccionados.

### Desplazamiento en días desde hoy para inicio del periodo

Permite establecer un margen de manera que el día actual no sea el primero que se visualizará.

### Desplazamiento en días desde hoy para fin del periodo

Permite establecer un margen de manera que el día actual no es el último que se visualizará.

### Condición avanzada JSON/MongoDB

Permite añadir un filtro para las filtrar los topicos y/o categorías a mostrar.

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.


### Campo de fecha en tópicos para el eje X

Establece la fecha inicial de manera que solo se mostrarán los tópicos creadas posterior a la fecha indicada.

### El gráfico se mostrará como
Muestra los diferentes tipos de gráficos que pueden ser utilizados:

- Área
- Area step
- Lineal
- Bar
- Scatter

### Los datos se agruparan por

Se pueden mostrar el número de tópicos agrupados por día, semana, mes, cuatrimestre o año.