---
title: Roadmap de tópicos
index: 5000
icon: roadmap
---

Muestra en una tabla los tópicos en función de la fecha de resolución.

La lista de elementos para personalizar el dashlet son:


### Altura en canvas

Define la altura en numero de filas que se le da al dashlet.

El valor de la altura oscilará entre 1 y 4. Donde con 4 ocupará el 100% de la página.

### Anchura en canvas

Establece el ancho que ocupará el elemento en el dashboard.

El valor máximo permitido es de 12 (100% de anchura).

### Frecuencia de autorefresco

Establece el intervalo de tiempo el cual el elemento se autorrefrescará.

### Primer día de la semana

Permite establecer el primer día de la semana laboral.

### Escala

Se puede definir la escala para mejor visualización de los tópicos. Dicha escala puede ser por día, semana o mes.

### Entornos

Añade un filtro para poder visualizar tópicos que se encuentren en uno o varios entornos determinados.

### Excluir entornos seleccionadas

Excluye los entornos seleccionadas en el punto anterior y muestra el resto que **no*
están seleccionados.

### Inicio / Fin (Desplazamiento hacia delante en días desde hoy)

Permite establece un margen en el que se visualizan días anteriores al día actual y días posteriores.

### Seleccionar tópicos en categorias

Selecciona las categorías que se quieren mostrar en la tabla.

### Excluir las clases seleccionadas

Excluye las clases seleccionadas en el punto anterior y muestra el resto que **no*
están seleccionadas.

### Condición avanzada JSON/MongoDB

Permite añadir un filtro para las filtrar los tópicos y/o categorías a mostrar.

        {"labels":[],"categories":["*id*"],"statuses":[],"priorities":[],"start":0,"limit":25}

Donde *id* es la clave una de la categoría. Dicho id se puede consultar a través del REPL.


### Máscara de etiqueta de tópicos

Permite personalizar la etiqueta de los tópicos.

Ejemplo: ${category.acronym}#${topic.mid} ${topic.title}