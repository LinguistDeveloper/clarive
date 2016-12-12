---
title: Timeline NG de tópicos
index: 5000
icon: dashlet-topic-ng
---

Muestra una línea de tendencia con los tópicos reales y las previsiones.

La lista de elementos configurables del dashlet son:

### Altura en canvas

Define la altura en numero de filas que se le da al dashlet.

El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el dashboard.

El valor máximo permitido es de 12 (100% de anchura).


### Frecuencia de autorefresco

Establece el intervalo de tiempo el cual el elemento se autorrefrescará.


### El gráfico se mostrará como

Muestra los diferentes tipos de gráficos que pueden ser utilizados:

- Área
- Area step
- Line
- Bar
- Scatter

### Campo de tópico de tipo fecha

Establece el campo del fieldlet de tipo fecha que por el que se filtrará el gráfico.

### Escala

Establece la escala del gráfico,  puede ser horas, días, meses o años


### Método para la selección de fechas

Selecciona el método para mostrar en el eje X. Puede ser:

- Por duración - Selecciona el rango y el *offset* para mostrar las fechas.
- Por periodo - Selecciona la fecha de inicio y la fecha final del gráfico.
- Filtrar por campos del tópico - Selecciona dos id fieldlets de tipo fecha para estable


### Seleccionar tópicos en categorías

Selecciona las categorías que se quieren mostrar en el gráfico

### Estados cerrados

Indica los estados que no se tendrán en cuenta en el gráfico.

### Consulta JSON

Permite añadir un filtro avanzado JSON

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}


Donde *id* es el [MID](concepts/mid) de la categoría.


## Opciones como fieldlet

Clarive permite añadir este dashlet dentro de un formulario de un tópico.

Su comportamiento es el mismo que como dashlet.

Dispone de dos opciones diferentes al dashlet para configurarlo:

- Ancho - Establece en % el ancho que ocupará el elemento en el tópico.
- Altura - Indica en píxeles el alto del elemento.
